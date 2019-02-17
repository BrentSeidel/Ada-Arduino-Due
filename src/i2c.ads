with Ada.Interrupts;
with Ada.Interrupts.Names;
with Ada.Synchronous_Task_Control;
with System;
with SAM3x8e;
use type SAM3x8e.Bit;
use type SAM3x8e.Byte;
use type SAM3x8e.UInt16;
use type SAM3x8e.UInt32;
with SAM3x8e.TWI;
with pio;
with dev;
--
--  Package for the I2C interface
--
--  The Arduino Due has two I2C interfaces.
--  Interface  SCL  SDA   TWI
--  I2C-0      PB13 PB12  TWI0
--  I2C-1      PA18 PA17  TWI1
--
package i2c is
   --
   --  Possible error codes
   --
   type err_code is (none, nack, ovre);
   --
   --  Interface speed, 100kHz and 400kHz are supported.
   --
   type speed_type is (low100, high400);
   --
   --  Port ID is 0 or 1
   --
   type port_id is  new Integer range 0 .. 1;
   --
   -- buffer to use for reading and writing from i2c bus.  In most cases, only
   -- a few bytes are needed.  This should be quite adequate.
   --
   type buff_index is new Integer range 0 .. 127;
   type buffer is array(buff_index'Range) of SAM3x8e.Byte;
   type buff_ptr is access all buffer;
   --
   --  The I2C device object
   --
   type i2c_device_record is tagged limited private;
   type i2c_device is access all i2c_device_record;
   --
   --  The I2C interface object
   --
   type i2c_interface_record is tagged
      record
         hw       : i2c_device;
      end record;
   type i2c_interface is access i2c_interface_record;
   --
   --  Function to return access to a device record.
   --
   function get_device(d : port_id) return i2c_device;
   --
   --  Initialize interface I2C-0 on the Arduino (turns out to be TWI1
   --  internally)
   --
   procedure init(chan : port_id; speed : speed_type);
   --
   -- Routines to read and write data on the i2c bus
   --
   procedure write(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   data : SAM3x8e.Byte; error : out err_code);
   function read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte;
   --
   -- Reading a single byte is straightforward.  When reading two bytes, is the
   -- MSB first or second?  There is no standard even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16;
   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   error : out err_code) return SAM3x8e.UInt16;
   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(chan : port_id; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  size : buff_index; error : out err_code);
   --
   --  Object oriented interface
   --
   procedure write(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                   data : SAM3x8e.Byte; error : out err_code);
   --
   function read(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.Byte;
   --
   -- When reading two bytes, is the MSB first or second?  There is no standard
   -- even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.UInt16;
   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                 error : out err_code) return SAM3x8e.UInt16;
   --
   -- Write an arbitrary number of bytes to a device on the i2c bus.
   --
--   procedure write(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
--                   buff : buff_ptr; size : SAM3x8e.UInt16; error : out err_code);
   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(self : not null access i2c_interface_record'class; addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte;
                  size : buff_index; error : out err_code);
private
   --
   --  Addresses for TWI records
   --
   TWI0 : aliased SAM3x8e.TWI.TWI_Peripheral
     with Import, Address => SAM3x8e.TWI0_Base;
   --
   TWI1 : aliased SAM3x8e.TWI.TWI_Peripheral
     with Import, Address => SAM3x8e.TWI1_Base;
   --
   --
   --  Buffers for reading data
   --
   b0 : aliased buffer;
   b1 : aliased buffer;

   --
   --  A protected type defining the transmit and receive buffers as well as an
   --  interface to the buffers.  This is based on the serial port handler, but
   --  is a bit simpler since (a) tx and rx is not simultaneous, so only one
   --  buffer is needed, and (b) communications are more transaction/block
   --  oriented so the user only needs to be notified when the exchange is
   --  completed.
   --
   protected type handler(interrupt : Ada.Interrupts.Interrupt_ID) is
      --
      --  Set the address to the device record.  This only needs to be called
      --  once during initialization/configuration.
      --
      procedure set_device(d : i2c_device);
      --
      --  Functions to return statuses
      --
      function is_busy return Boolean;
      function get_status return SAM3x8e.TWI.TWI0_SR_Register;
      --
      --  Entry point to transmit a character.  Per Ravenscar, there can be
      --  only one entry.  This is not yet implemented.
      --
      entry send(reg : SAM3x8e.Byte; size : buff_index);
      --
      --  Procedure to read a specified number of characters into a buffer.
      --  Calls to this procedure need to be synchronized using
      --  susp_not_busy.
      --
      procedure rx_read(addr : SAM3x8e.UInt7; reg : SAM3x8e.Byte; size : buff_index);
      --
      -- Return the error code, if any.
      --
      function get_error return err_code;
   private
      procedure int_handler;
      pragma Attach_Handler (int_handler, interrupt);
      pragma Interrupt_Priority(System.Interrupt_Priority'First);

      device   : i2c_device;
      stat     : SAM3x8e.TWI.TWI0_SR_Register;

      busy     : Boolean := False;
      not_busy : Boolean := True;

      bytes  : buff_index;
      index  : buff_index;

      err : err_code;
   end handler;
   --
   --  Declare a handler for each i2c port
   --
   buff0 : aliased handler(Ada.Interrupts.Names.TWI1_Interrupt);
   buff1 : aliased handler(Ada.Interrupts.Names.TWI0_Interrupt);
   --
   --  An array of the interrupt handlers so that the I/O routines can access a
   --  handler by the port ID.
   --
   type buffer_access is access all handler;
   buff : array (port_id'Range) of buffer_access :=
     (buff0'access, buff1'access);
   --
   --  Create a serial channel information record.  This should contain all
   --  the information necessary to identify a serial port and the pins used
   --  by it.
   --
   type twi_access is access all SAM3x8e.TWI.TWI_Peripheral;
   type i2c_device_record is tagged limited
      record
         dev_id   : SAM3x8e.Byte;    --  TWI device ID
         port     : twi_access;      --  Access to I2C registers
         pioc     : pio.pio_access;  --  PIO controlling pins
         sda_pin  : SAM3x8e.Byte;    --  SDA pin on PIO
         scl_pin  : SAM3x8e.Byte;    --  SCL pin on PIO
         int_id   : Ada.Interrupts.Interrupt_ID; -- Interrupt for channel
         b        : buff_ptr;
         handle   : buffer_access;
         not_busy : Ada.Synchronous_Task_Control.Suspension_Object;
      end record;
   --
   --  The Arduino Due has two I2C busses available on the headers.  Note that
   --  the port numbers on the header are reversed from the internal hardware
   --  channel numbers.
   --
   i2c_0 : aliased i2c_device_record;
   i2c_1 : aliased i2c_device_record;
   i2c_port :  array (port_id'Range) of i2c_device := (i2c_0'Access, i2c_1'Access);

end i2c;
