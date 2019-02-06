with SAM3x8e.PMC;
with SAM3x8e.PIO;
with SAM3x8e.TWI;
with serial.int;
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
      if speed = high400 then
         i2c_port(chan).port.CWGR.CKDIV := 0;
      else
         i2c_port(chan).port.CWGR.CKDIV := 2;
      end if;
      i2c_port(chan).port.CWGR.CLDIV := 104;
      i2c_port(chan).port.CWGR.CHDIV := 104;
      --
      --  Enable master mode
      --
      i2c_port(chan).port.CR.MSEN  := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS := 1;  --  Disable slave mode
      --
      --  Set channel not busy
      --
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
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
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      i2c_port(chan).port.CR.MSEN    := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS   := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 0;  --  Master write
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR  := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.THR.TXDATA := data;
      i2c_port(chan).port.CR.STOP    := 1;
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
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
   end;
   --
   function read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte is
      status : SAM3x8e.TWI.TWI0_SR_Register;
      ctrl   : SAM3x8e.TWI.TWI0_CR_Register;
      data   : SAM3x8e.Byte;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      i2c_port(chan).port.CR.MSEN    := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS   := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR  := SAM3x8e.UInt24(reg);
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
      i2c_port(chan).port.IER.TXCOMP := 1;
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
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
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      i2c_port(chan).port.CR.MSEN    := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS   := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR  := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START   := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
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
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      else
         error := none;
      end if;
      d1 := i2c_port(chan).port.RHR.RXDATA;
      i2c_port(chan).port.IER.TXCOMP := 1;
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
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
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      i2c_port(chan).port.CR.MSEN    := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS   := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR  := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START   := 1;
      loop
         status := i2c_port(chan).port.SR;
         exit when status.RXRDY = 1;
         exit when status.NACK = 1;
         exit when status.OVRE = 1;
      end loop;
      if status.NACK = 1 then
         error := nack;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
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
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      elsif status.OVRE = 1 then
         error := ovre;
         Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         return 0;
      else
         error := none;
      end if;
      d1 := i2c_port(chan).port.RHR.RXDATA;
      i2c_port(chan).port.IER.TXCOMP := 1;
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
      return  SAM3x8e.UInt16(d1)*256 + SAM3x8e.UInt16(d0);
   end;

   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  buffer : buff_ptr; size : buff_index; error : out err_code) is
      count  : buff_index := 0;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      i2c_port(chan).port.CR.MSEN    := 1;  --  Enable master mode
      i2c_port(chan).port.CR.SVDIS   := 1;  --  Disable slave mode
      i2c_port(chan).port.MMR.MREAD  := 1;  --  Master read
      i2c_port(chan).port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      i2c_port(chan).port.MMR.DADR   := addr;
      i2c_port(chan).port.IADR.IADR  := SAM3x8e.UInt24(reg);
      i2c_port(chan).port.CR.START   := 1;
      --
      buff(chan).rx_read(buffer, reg, size);
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_not_busy(chan));
      error := buff(chan).get_error;
      Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
   end;
   --

   --
   --  A protected type defining the transmit and receive buffers as well as an
   --  interface to the buffers.  This is based on the serial port handler, but
   --  is a bit simpler since (a) tx and rx is not simultaneous, so only one
   --  buffer is needed, and (b) communications are nore transaction/block
   --  oriented so the user only needs to be notified when the exchange is
   --  completed.
   --
   protected body handler is
      --
      --  Functions to return statuses
      --
      function is_busy return Boolean is
      begin
         return busy;
      end;
      --
      --  Entry point to transmit a character.  Per Ravenscar, there can be
      --  only one entry.
      --
      entry send(b : buff_ptr; reg : SAM3x8e.Byte; size : buff_index) when not_busy is
      begin
         busy := True;
         not_busy := False;
         bytes := size;
         index := 0;
         buffer := b;
      end;
      --
      --  Procedure to read a specified number of characters into a buffer.
      --  Calls to this procedure need to be synchronized using
      --  susp_not_busy.
      --
      procedure rx_read(b : buff_ptr; reg : SAM3x8e.Byte; size : buff_index) is
      begin
         busy := True;
         not_busy := False;
         err := none;
         bytes := size;
         index := 0;
         buffer := b;
         i2c_port(chan).port.IER.RXRDY := 1;
      end;
      --
      -- Return the error code, if any.
      --
      function get_error return err_code is
      begin
         return err;
      end;
      --
      --  This is the interrupt handler.  There are three different things that
      --  may cause an interrupt:
      --  Transmitter ready:  If the buffer is not empty, then pull the next
      --    character out of the buffer and write it to the transmitter.  Update
      --    pointers and check if that was the last character.
      --
      --  Receiver ready:  Add characters to the receive buffer.  If buffer is
      --    full, the oldest character is discarded.
      --
      --  Transmitter empty: This is triggered when the UART is finished sending
      --    data and there is no more data ready.  This is used in RS-485 mode
      --    to clear the pin used to enable the drivers.
      --
      procedure int_handler is
         status : SAM3x8e.TWI.TWI0_SR_Register;
      begin
         status := i2c_port(channel_id).port.SR;
         if status.NACK = 1 then
            err := nack;
         elsif status.OVRE = 1 then
            err := ovre;
         end if;
         --
         --  Check for transmitter ready.  If so, send the next character(s).
         --
         if status.TXRDY = 1 then
            null;
         end if;
         --
         --  Check for receiver ready.  If the buffer is full, discard the oldest
         --  character in the buffer.
         --
         if status.RXRDY = 1 then
            buffer(index) := i2c_port(channel_id).port.RHR.RXDATA;
            if index = bytes then
               i2c_port(channel_id).port.IDR.RXRDY := 1;
               i2c_port(channel_id).port.IER.TXCOMP := 1;
            end if;
            index := index + 1;
            if index = bytes then
               i2c_port(channel_id).port.CR.STOP := 1;
            end if;
         end if;
         --
         --  Check for transmitter empty
         --
         if (status.TXCOMP = 1) then
            i2c_port(channel_id).port.IDR.TXCOMP := 1;
            Ada.Synchronous_Task_Control.Set_True(i2c_not_busy(chan));
         end if;
      end int_handler;
   end handler;
   --

end i2c;
