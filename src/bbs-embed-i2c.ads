with BBS.embed;
package BBS.embed.i2c is

   --
   --  Possible error codes
   --
   type err_code is (none, nack, ovre, invalid_addr);
   --
   -- buffer to use for reading and writing from i2c bus.  In most cases, only
   -- a few bytes are needed.  This should be quite adequate.
   --
   type buff_index is new Integer range 0 .. 127;
   type buffer is array(buff_index'Range) of BBS.embed.uint8;
   type buff_ptr is access all buffer;
   --
   -- The I2C  object
   --
   --
   -- The root class for I2C device objects
   --
   type i2c_interface_record is tagged limited
      record
         b        : buff_ptr;
      end record;
   type i2c_interface is access all i2c_interface_record'Class;
   --
   --  The I2C interface object
   --
   type i2c_device_record is tagged
      record
         hw       : i2c_interface;
      end record;
   type i2c_device is access i2c_device_record;
   --
   -- Reading or writing a single byte is straigtforward.
   --
   procedure write(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                   data : uint8; error : out err_code) is null;
   --
   function read(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                 error : out err_code) return uint8 is (0);
   --
   -- When reading two bytes, is the MSB first or second?  There is no standard
   -- even within a single device.
   --
   -- Read a word with MSB first
   --
   function readm1(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                 error : out err_code) return uint16 is (0);
   --
   -- Read a word with MSB second (LSB first)
   --
   function readm2(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                 error : out err_code) return uint16 is (0);
   --
   -- Write an arbitrary number of bytes to a device on the i2c bus.
   --
   procedure write(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                   size : buff_index; error : out err_code) is null;
   --
   -- Read the specified number of bytes into a buffer
   --
   procedure read(self : in out i2c_interface_record; addr : addr7; reg : uint8;
                  size : buff_index; error : out err_code) is null;

end;
