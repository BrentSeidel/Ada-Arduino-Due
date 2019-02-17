with serial.int;
with strings;
--
--  This package implementes a simple command line interpreter.
package cli is
   --
   --  Feature selection
   --
   i2c_enable    : constant Boolean := True;
   analog_enable : constant Boolean := True;
   --
--   i2c_good    : Boolean := False;
   bme280_good : Boolean := False;
   bmp180_good : Boolean := False;
   --
   --  Procedure for the command line interpreter
   --
   procedure command_loop;
   --
   --  Logon procedure
   --
   procedure logon;
   --
private
   user   : String(1 .. 20);
   l_user : Integer := 0;
   pass   : String(1 .. 20);
   l_pass : Integer := 0;

   --
   --  Procedure to break up some of the functionality
   --
   procedure analog_outs(v : Integer);
   --
   procedure process_i2c(r : strings.bounded);
end cli;
