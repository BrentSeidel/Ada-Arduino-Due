with serial.int;
--
--  This package implementes a simple command line interpreter.
package cli is
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

end cli;
