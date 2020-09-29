--with BBS.embed.due.serial.int;
with strings;
with BBS.embed.GPIO.Due;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed;
--use type BBS.embed.addr7;
use type BBS.embed.uint8;
with BBS.embed.i2c.BME280;
with BBS.embed.i2c.BMP180;
with BBS.embed.i2c.L3GD20H;
with BBS.embed.i2c.MCP23017;
with BBS.embed.i2c.PCA9685;
with BBS.embed.due.serial.int;
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
   bme280_found      : i2c_device_location := absent;
   bmp180_found      : i2c_device_location := absent;
   l3gd20_found      : i2c_device_location := absent;
   pca9685_found     : i2c_device_location := absent;
   lsm303dlhc_found  : i2c_device_location := absent;
   mcp23017_0_found  : i2c_device_location := absent;
   mcp23017_2_found  : i2c_device_location := absent;
   mcp23017_6_found  : i2c_device_location := absent;
   --
   --  Device records
   --
   BMP180 : aliased BBS.embed.i2c.BMP180.BMP180_record;
   BME280 : aliased BBS.embed.i2c.BME280.BME280_record;
   L3GD20 : aliased BBS.embed.i2c.L3GD20H.L3GD20H_record;
   PCA9685 : aliased BBS.embed.i2c.PCA9685.PS9685_record;
   MCP23017_0 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
   MCP23017_2 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
   MCP23017_6 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
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
   --  Procedure to break up some of the functionality
   --
   procedure analog_outs(v : Integer);
   --
   procedure process_i2c(s : BBS.embed.due.serial.int.serial_port; r : strings.bounded);
   --
   procedure stop_task(r : strings.bounded);
   --
   procedure start_task(r : strings.bounded);
   --
   procedure handle_gpio(r : strings.bounded);
   --
   procedure parse_pin(r : strings.bounded; err : out Boolean);
   --
   procedure show_status(s : BBS.embed.due.serial.int.serial_port);
   --
   procedure probe_bme280_bmp180(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7);
   procedure probe_l3gd20(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.L3GD20H.L3GD20H_record;
                            f : out i2c_device_location);
   procedure probe_mcp23017(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.MCP23017.MCP23017_record;
                            f : out i2c_device_location);
   procedure probe_pca9685(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.PCA9685.PS9685_record;
                            f : out i2c_device_location);
   --
end cli;
