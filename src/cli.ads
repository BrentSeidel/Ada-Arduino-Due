with serial.int;
with strings;
with pio;
with i2c;
use type i2c.err_code;
use type i2c.port_id;
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
   --  Procedure for the command line interpreter
   --
   procedure command_loop;
   --
   --  Logon procedure
   --
   procedure logon;
   --
   procedure i2c_probe(c : i2c.port_id);
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
   procedure process_i2c(r : strings.bounded);
   --
   procedure stop_task(r : strings.bounded);
   --
   procedure start_task(r : strings.bounded);
   --
   procedure handle_gpio(r : strings.bounded);
   --
   function parse_pin(r : strings.bounded; err : out Boolean) return pio.gpio_record;
   --
   procedure show_status;
   --
end cli;
