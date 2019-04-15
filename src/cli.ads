with BBS.embed.due.serial.int;
with strings;
with BBS.embed.GPIO.Due;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed;
use type BBS.embed.uint8;
with BBS.embed.i2c.BME280;
with BBS.embed.i2c.BMP180;
with BBS.embed.i2c.L3GD20H;
--
--  This package implementes a simple command line interpreter.
--
package cli is
   --
   --  Feature selection
   --
   i2c_enable    : constant Boolean := True;
   analog_enable : constant Boolean := True;
   --
   type i2c_device_location is (absent, bus0, bus1);
   bme280_found     : i2c_device_location := absent;
   bmp180_found     : i2c_device_location := absent;
   l3gd20_found     : i2c_device_location := absent;
   lsm303dlhc_found : i2c_device_location := absent;
   --
   --  GPIO Pin to operate on
   --
   gpio   : aliased BBS.embed.GPIO.Due.Due_GPIO_record;
   --
   --  Procedure for the command line interpreter
   --
   procedure command_loop;
   --
   --  Logon procedure
   --
   procedure logon;
   --
   procedure i2c_probe(c : bbs.embed.i2c.due.port_id);
   --
private
   username : aliased strings.bounded(20);
   pass   : String(1 .. 20);
   l_pass : Integer := 0;

   --
   --  Device records
   --
   BMP180 : aliased BBS.embed.i2c.BMP180.BMP180_record;
   BME280 : aliased BBS.embed.i2c.BME280.BME280_record;
   L3GD20 : aliased BBS.embed.i2c.L3GD20H.L3GD20H_record;
   --
   --  Procedure to break up some of the functionality
   --
   procedure analog_outs(v : Integer);
   --
   procedure process_i2c(r : strings.bounded);
   --
   procedure stop_task(r : strings.bounded);
   --
   procedure start_task(r : strings.bounded);
   --
   procedure handle_gpio(r : strings.bounded);
   --
   procedure parse_pin(r : strings.bounded; err : out Boolean);
   --
   procedure show_status;
   --
end cli;