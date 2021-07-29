--with BBS.embed.due.serial.int;
with strings;
with BBS.embed.GPIO.Due;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed;
--use type BBS.embed.addr7;
use type BBS.embed.uint8;
with BBS.embed.i2c.L3GD20H;
with BBS.embed.i2c.MCP23017;
with BBS.embed.i2c.PCA9685;
with BBS.embed.due.serial.int;
with BBS.lisp.embed;
use type BBS.lisp.embed.i2c_device_location;
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
   procedure show_status(s : BBS.embed.due.serial.int.serial_port);
   --
   procedure probe_bme280_bmp180(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7);
   procedure probe_l3gd20(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.L3GD20H.L3GD20H_record;
                            f : in out BBS.lisp.embed.i2c_device_location);
   procedure probe_mcp23017(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.MCP23017.MCP23017_record;
                            f : in out BBS.lisp.embed.i2c_device_location);
   procedure probe_pca9685(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.PCA9685.PS9685_record;
                            f : in out BBS.lisp.embed.i2c_device_location);
   --
end cli;
