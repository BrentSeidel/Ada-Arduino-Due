with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with SAM3x8e.PMC;
with SAM3x8e.PIO;
with SAM3x8e.TWI;
with serial.int;
with utils;
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
   --  Function to return access to a device record.
   --
   function get_device(d : port_id) return i2c_device is
   begin
      return i2c_port(d);
   end;
   --
   --  Initialize an interface
   --
   --
   --  The I2C-0 port is connected to pins PB13 and PB12.  The UART
   --  initialization is used as a basis for this.
   --
   procedure init(chan : port_id; speed : speed_type) is
      pins    : SAM3x8e.UInt32;
   begin
      --
      --  Initialize internal data structures for both devices.
      --
      i2c_port(0).dev_id  := dev.TWI1_ID;
      i2c_port(0).port    := TWI1'Access;
      i2c_port(0).pioc    := pio.PIOB'Access;
      i2c_port(0).sda_pin := 12;
      i2c_port(0).scl_pin := 13;
      i2c_port(0).int_id  := Ada.Interrupts.Names.TWI1_Interrupt;
      i2c_port(0).b       := b0'Access;
      i2c_port(0).handle  := buff(0);
      buff0.set_device(i2c_0'Access);
      --
      i2c_port(1).dev_id := dev.TWI0_ID;
      i2c_port(1).port   := TWI0'Access;
      i2c_port(1).pioc   := pio.PIOA'Access;
      i2c_port(1).sda_pin := 17;
      i2c_port(1).scl_pin := 18;
      i2c_port(1).int_id  := Ada.Interrupts.Names.TWI0_Interrupt;
      i2c_port(1).b       := b1'Access;
      i2c_port(1).handle  := buff(1);
      buff1.set_device(i2c_1'Access);
      --
      pins    := 2**Natural(i2c_port(chan).sda_pin) or 2**Natural(i2c_port(chan).scl_pin);
      --
      --  Initialize hardware for selected device.
      --
      --  Enable clock for I2C-0
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
      Ada.Synchronous_Task_Control.Set_True(i2c_port(chan).not_busy);
   end init;
   --
   --  Non-object oriented interface.
   --
   --  Routines to read and write data on the i2c bus.  These are based on the
   --  flowcharts in the datasheet.  The read routines are interrupt driven.
   --  The write routine is still partially polled.  It will eventually be
   --  converted to interrupt driven and a block write added.
   --
   procedure write(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   data : SAM3x8e.Byte; error : out err_code) is
      status : SAM3x8e.TWI.TWI0_SR_Register;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_port(chan).not_busy);
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
      Ada.Synchronous_Task_Control.Set_True(i2c_port(chan).not_busy);
   end;
   --
   function read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte is
   begin
      read(chan, addr, reg, 1, error);
      return  SAM3x8e.Byte(i2c_port(chan).b(0));
   end;
   --
   -- Reading a single byte is straightforward.  When reading two bytes, is the
   -- MSB first or second?  There is no standard even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
   begin
      read(chan, addr, reg, 2, error);
      return  SAM3x8e.UInt16(i2c_port(chan).b(0))*256 +
        SAM3x8e.UInt16(i2c_port(chan).b(1));
   end;

   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
   begin
      read(chan, addr, reg, 2, error);
      return  SAM3x8e.UInt16(i2c_port(chan).b(1))*256 +
        SAM3x8e.UInt16(i2c_port(chan).b(0));
   end;

   --
   -- Read the specified number of bytes into the device buffer
   --
   procedure read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  size : buff_index; error : out err_code) is
      count  : buff_index := 0;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_port(chan).not_busy);
      buff(chan).rx_read(addr, reg, size);
      Ada.Synchronous_Task_Control.Suspend_Until_True(i2c_port(chan).not_busy);
      error := buff(chan).get_error;
      Ada.Synchronous_Task_Control.Set_True(i2c_port(chan).not_busy);
   end;
   --
   --
   --  Object oriented interface
   --
   --
   --  Write a byte to a specified register on an I2C device.
   --
   procedure write(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   data : SAM3x8e.Byte; error : out err_code) is
      status : SAM3x8e.TWI.TWI0_SR_Register;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(self.hw.not_busy);
      self.hw.port.CR.MSEN    := 1;  --  Enable master mode
      self.hw.port.CR.SVDIS   := 1;  --  Disable slave mode
      self.hw.port.MMR.MREAD  := 0;  --  Master write
      self.hw.port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
      self.hw.port.MMR.DADR   := addr;
      self.hw.port.IADR.IADR  := SAM3x8e.UInt24(reg);
      self.hw.port.THR.TXDATA := data;
      self.hw.port.CR.STOP    := 1;
      loop
         status := self.hw.port.SR;
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
      Ada.Synchronous_Task_Control.Set_True(self.hw.not_busy);
   end write;
   --
   --  All the read functions use the block read procedure and return the
   --  specified data.
   --
   function read(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte is
   begin
      read(self, addr, reg, 1, error);
      return  SAM3x8e.Byte(self.hw.b(0));
   end read;
   --
   -- When reading two bytes, is the MSB first or second?  There is no standard
   -- even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
   begin
      read(self, addr, reg, 2, error);
      return  SAM3x8e.UInt16(self.hw.b(0))*256 + SAM3x8e.UInt16(self.hw.b(1));
   end;
   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16 is
   begin
      read(self, addr, reg, 2, error);
      return  SAM3x8e.UInt16(self.hw.b(1))*256 + SAM3x8e.UInt16(self.hw.b(0));
   end;
   --
   --  Write an arbitrary number of bytes to a device on the i2c bus.  Not yet
   --  implemented.
   --
--   procedure write(self : not null access i2c_interface_record'class; addr : addr7; reg : uint8;
--                   buff : buff_ptr; size : uint16; error : out err_code) is null;
   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  size : buff_index; error : out err_code) is
      stdout : serial.int.serial_port := serial.int.get_port(0);
      count  : Integer := 0;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(self.hw.not_busy);
      self.hw.handle.rx_read(addr, reg, size);
      Ada.Synchronous_Task_Control.Suspend_Until_True(self.hw.not_busy);
      error := self.hw.handle.get_error;
      Ada.Synchronous_Task_Control.Set_True(self.hw.not_busy);
   end read;
   --
   --  -------------------------------------------------------------------------
   --  A protected type defining the transmit and receive buffers as well as an
   --  interface to the buffers.  This is based on the serial port handler, but
   --  is a bit simpler since (a) tx and rx is not simultaneous, so only one
   --  buffer is needed, and (b) communications are nore transaction/block
   --  oriented so the user only needs to be notified when the exchange is
   --  completed.
   --
   protected body handler is
      --
      --  Set the address to the device record.  This only needs to be called
      --  once during initialization/configuration.
      --
      procedure set_device(d : i2c_device) is
      begin
         device := d;
      end;
      --
      --  Functions to return statuses
      --
      function is_busy return Boolean is
      begin
         return busy;
      end;
      --
      function get_status return SAM3x8e.TWI.TWI0_SR_Register is
      begin
         return device.port.SR;
      end;
      --
      --  Entry point to transmit a character.  Per Ravenscar, there can be
      --  only one entry.  Note that this is not yet implemented.
      --
      entry send(reg : SAM3x8e.Byte; size : buff_index) when not_busy is
      begin
         busy := True;
         not_busy := False;
         bytes := size;
         index := 0;
      end;
      --
      --  Procedure to read a specified number of characters into a buffer.
      --  Calls to this procedure need to be synchronized using
      --  susp_not_busy.
      --
      procedure rx_read(addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte; size : buff_index) is
      begin
         busy := True;
         not_busy := False;
         err := none;
         bytes := size;
         index := 0;
         device.port.IER.RXRDY  := 1;
         device.port.IER.OVRE   := 1;
         device.port.IER.NACK   := 1;
         device.port.IER.TXCOMP := 1;
         device.port.CR.MSEN    := 1;  --  Enable master mode
         device.port.CR.SVDIS   := 1;  --  Disable slave mode
         device.port.MMR.MREAD  := 1;  --  Master read
         device.port.MMR.IADRSZ := SAM3x8e.TWI.Val_1_Byte;  --  Register addresses are 1 byte;
         device.port.MMR.DADR   := addr;
         device.port.IADR.IADR  := SAM3x8e.UInt24(reg);
         device.port.CR.START   := 1;
         if size = 1 then
            device.port.CR.STOP := 1;
         end if;
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
      --  Transmitter ready:  Currently does nothing.
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
         status := device.port.SR;
         stat := status;
         if status.NACK = 1 then
            err := nack;
         elsif status.OVRE = 1 then
            err := ovre;
         end if;
         --
         --  Currently transmit ready does nothing.
         --
         if status.TXRDY = 1 then
            null;
         end if;
         --
         --  Check for receiver ready and add new data to the buffer.
         --
         if status.RXRDY = 1 then
            device.b(index) := device.port.RHR.RXDATA;
            index := index + 1;
            if index = bytes then
               device.port.CR.STOP := 1;
            end if;
         end if;
         --
         --  Check for transmitter empty
         --
         if (status.TXCOMP = 1) then
            device.port.IDR.TXCOMP := 1;
            device.port.IDR.RXRDY := 1;
            device.port.IDR.OVRE := 1;
            device.port.IDR.NACK := 1;
            Ada.Synchronous_Task_Control.Set_True(device.not_busy);
            busy := False;
            not_busy := True;
         end if;
         --
         --  Check if error detected.  If so, abandon whatever we're currently
         --  doing.
         --
         if err /= none then
            device.port.IDR.TXCOMP := 1;
            device.port.IDR.TXRDY := 1;
            device.port.IDR.RXRDY := 1;
            device.port.IDR.OVRE := 1;
            device.port.IDR.NACK := 1;
            Ada.Synchronous_Task_Control.Set_True(device.not_busy);
            busy := False;
            not_busy := True;
         end if;
      end int_handler;
   end handler;
   --

end i2c;
