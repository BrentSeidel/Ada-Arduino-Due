with SAM3x8e.PMC;
with SAM3x8e.PIO;
with SAM3x8e.TWI;
--
--  Package for the I2C interface
--
--  The Arduino Due has two I2C interfaces.
--  Interface  SCL  SDA   TWI
--  I2C-0      PB13 PB12  TWI0
--  I2C-1      PA18 PA17  TWI1
--
package body i2c is
   --
   --  Initialize an interface
   --
   --
   --  The I2C-0 port is connected to pins PB13 and PB12.  The UART
   --  initialization is used as a basis for this.
   --
   procedure init(chan : port_id; speed : speed_type) is
      sda_pin : constant SAM3x8e.UInt32  := 2**Natural(i2c_port(chan).sda_pin);
      scl_pin : constant SAM3x8e.UInt32  := 2**Natural(i2c_port(chan).scl_pin);
      pins   : constant SAM3x8e.UInt32  := sda_pin or scl_pin;
   begin
      --
      --  Enable clock for I2C-0
      --
      --
      SAM3x8e.PMC.PMC_Periph.PMC_PCER0.PID.Arr(Integer(i2c_port(chan).dev_id)) := 1;
      --
      --  Configure pins PB12 and PB13 to be I2C pins.
      --
      --  PER
      --  PDR
      i2c_port(chan).pioc.PDR.Val := pins;
      --  OER
      --  ODR
      i2c_port(chan).pioc.OER.Val := pins;
      --  IFER
      --  IFDR
      i2c_port(chan).pioc.IFDR.Val := pins;
      --  SODR
      --  CODR
      --  IER
      --  IDR
      i2c_port(chan).pioc.IDR.Val := pins;
      --  MDER
      --  MDDR
      i2c_port(chan).pioc.MDDR.Val := pins;
      --  PUDR
      --  PUER
      i2c_port(chan).pioc.PUER.Val := pins;
      --  ABSR -  really needed since both TWI are function A
      i2c_port(chan).pioc.ABSR.Arr(Integer(i2c_port(chan).sda_pin)) := 0;
      i2c_port(chan).pioc.ABSR.Arr(Integer(i2c_port(chan).scl_pin)) := 0;
      --  OWER
      --  OWDR
      i2c_port(chan).pioc.OWDR.Val := pins;
      --
      --  Do whatever configuration is needed to configure the I2C controller.
      --
      --
      --  Set TWI clock for 100kHz
      --  The system clock is 84_000_000Hz
      --  The I2C clock is       100_000Hz
      --  This gives 840 system clocks per I2C clock.
      --
      --  The clock rate is set by three parameters: CLDIV, CHDIV, and CKDIV.
      --  Instead of specifying a clock rate, these specify the high time and
      --  the low time for the I2C clock.  The times are given by (note that
      --  the wave is symmetrical so Tlow = Thigh, meaning that CLDIV = CHDIV):
      --    Tlow  = ((CLDIV * 2^CKDIV) + 4) * Tmck
      --  Where:
      --    Tmch is the master clock period
      --  This should reduce to:
      --    420 = (CLDIV * 2^CKDIV) + 4
      --  or
      --    416 = CLDIV * 2^CKDIV
      --  or
      --    CLDIV = 416/(2^CKDIV)
      --
      --    CLDIV and CHDIV occupy 8 bits and this are limited to 0 - 255
      --    CKDIV is 3 bits and is limited to 0 - 7.
      --  So, we can get:
      --    CLDIV = CHDIV = 104
      --    CKDIV = 2
      --
      i2c_port(chan).port.CWGR.CKDIV := 2;
      i2c_port(chan).port.CWGR.CLDIV := 104;
      i2c_port(chan).port.CWGR.CHDIV := 104;
      --
      --  Enable master mode
      --
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
   end init;
   --
   --  Routines to read and write data on the i2c bus.  These are based on the
   --  flowcharts in the datasheet.  Note that these are polled, not interrupt
   --  driven.  Those will be added later.
   --
   procedure write(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   data : SAM3x8e.Byte; error : out err_code) is
      status : SAM3x8e.TWI.TWI0_SR_Register;
   begin
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 0;  --  Master write
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.THR.TXDATA := data;
      i2c_port(chan).port.CR.STOP := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.TXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
      elsif status.OVRE = 1 then
         error := ovre;
      else
         error := none;
      end if;
   end;
   --
   function read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte is
      status : SAM3x8e.TWI.TWI0_SR_Register;
      ctrl   : SAM3x8e.TWI.TWI0_CR_Register;
      data   : SAM3x8e.Byte;
   begin
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR := SAM3x8e.UInt24(reg);
      ctrl.START := 1;
      ctrl.STOP  := 1;
      i2c_port(chan).port.CR := ctrl;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
      elsif status.OVRE = 1 then
         error := ovre;
      else
         error := none;
      end if;
      data := i2c_port(chan).port.RHR.RXDATA;
      while i2c_port(chan).port.SR.TXCOMP = 0 loop
         null;
      end loop;
      return data;
   end;
   --
   -- Reading a single byte is straightforward.  When reading two bytes, is the
   -- MSB first or second?  There is no standard even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
      status : SAM3x8e.TWI.TWI0_SR_Register;
      d0     : SAM3x8e.Byte;
      d1     : SAM3x8e.Byte;
   begin
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         return 0;
      else
         error := none;
      end if;
      d0 := i2c_port(chan).port.RHR.RXDATA;
      i2c_port(chan).port.CR.STOP := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         return 0;
      else
         error := none;
      end if;
      d1 := i2c_port(chan).port.RHR.RXDATA;
      while i2c_port(chan).port.SR.TXCOMP = 0 loop
         null;
      end loop;
      return  SAM3x8e.UInt16(d0)*256 + SAM3x8e.UInt16(d1);
   end;

   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
      status : SAM3x8e.TWI.TWI0_SR_Register;
      d0     : SAM3x8e.Byte;
      d1     : SAM3x8e.Byte;
   begin
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         return 0;
      else
         error := none;
      end if;
      d0 := i2c_port(chan).port.RHR.RXDATA;
      i2c_port(chan).port.CR.STOP := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         return 0;
      else
         error := none;
      end if;
      d1 := i2c_port(chan).port.RHR.RXDATA;
      while i2c_port(chan).port.SR.TXCOMP = 0 loop
         null;
      end loop;
      return  SAM3x8e.UInt16(d1)*256 + SAM3x8e.UInt16(d0);
   end;

   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  buff : buff_ptr; size : SAM3x8e.UInt16; error : out err_code) is
      status : SAM3x8e.TWI.TWI0_SR_Register;
--      data   : SAM3x8e.Byte;
      count  : SAM3x8e.UInt16 := 0;
   begin
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START := 1;
      loop
         loop
            status := i2c_port(chan).port.SR;
            exit when status.RXRDY = 1;
            exit when status.NACK = 1;
            exit when status.OVRE = 1;
         end loop;
         if status.NACK = 1 then
            error := nack;
         elsif status.OVRE = 1 then
            error := ovre;
         else
            error := none;
         end if;
         exit when error /= none;
         buff(Integer(count)) := i2c_port(chan).port.RHR.RXDATA;
         count := count + 1;
         if count = (size - 1) then
            i2c_port(chan).port.CR.STOP := 1;
         end if;
         exit when count = size;
      end loop;

      while i2c_port(chan).port.SR.TXCOMP = 0 loop
         null;
      end loop;
   end;
   --

end i2c;
