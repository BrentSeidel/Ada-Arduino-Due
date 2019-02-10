with utils;
with i2c;
with i2c.BME280;
with analogs;
with SAM3x8e;
use type SAM3x8e.UInt12;
with BBS.units;
with strings;

package body cli is

   --
   --  Logon procedure
   --
   procedure logon is
      stdout  : constant serial.int.serial_port := serial.int.get_port(0);
      stdin   : constant serial.int.serial_port := serial.int.get_port(0);
   begin
      loop
         stdout.put_line("MovieOS V27.5.2 Central Control Computer");
         stdout.put("Username: ");
         stdin.get_line(user, l_user);
         strings.uppercase(user);
         stdout.put("Password: ");
         stdin.get_line(pass, l_pass);
         strings.uppercase(pass);
         exit when (l_pass = 8) and (pass(1..l_pass) = "OVERRIDE");
         stdout.put_line("Invalid credentials.  Security has been notified.");
      end loop;
   end;

   --
   --  Procedure for the command line interpreter
   --
   procedure command_loop is
      stdout  : constant serial.int.serial_port := serial.int.get_port(0);
      stdin   : constant serial.int.serial_port := serial.int.get_port(0);
      serial1 : constant serial.int.serial_port := serial.int.get_port(1);
      serial2 : constant serial.int.serial_port := serial.int.get_port(2);
      serial3 : constant serial.int.serial_port := serial.int.get_port(3);
      BME280  : constant i2c.BME280.BME280_ptr := i2c.BME280.get_BME280;
      line : aliased strings.bounded(80);
      cmd  : aliased strings.bounded(80);
      rest : aliased strings.bounded(80);
      s    : String(1 .. 80);
      l    : Integer := 0;
      flag : Boolean;
      err  : i2c.err_code;
      val  : Integer;
   begin
      stdout.put_line("Welcome to the Central Control Computer.");
      loop
         stdout.put(user(1..l_user) & "> ");
         stdin.get_line(s, l);
         strings.to_bounded(line, s, l);
         line.token(' ', cmd, rest);
         cmd.uppercase;
--         stdout.put_line("Token is <" & cmd.to_string & ">");
--         stdout.put_line("Rest is <" & rest.to_string & ">");
         --
         -- Check for some commands.
         --
         exit when cmd.starts_with("LOGOUT");
         exit when cmd.starts_with("LOGOFF");
         exit when cmd.starts_with("BYE");
         if cmd.starts_with("FLASH") then
            utils.flash_count := integer'Value(rest.to_string);
         elsif cmd.starts_with("EXIT") then
            stdout.put_line("There is nowhere to exit to.  This is it.");
         elsif cmd.starts_with("QUIT") then
            stdout.put_line("I can't quit.");
         elsif cmd.starts_with("INFO") then
            utils.cpu_info;
         elsif cmd.starts_with("HELP") then
            stdout.put_line("I'm sorry, I can't help you.");
         elsif i2c_good and cmd.starts_with("BME280") then
            BME280.start_conversion(err);
            loop
               flag := BME280.data_ready(err);
               exit when flag;
            end loop;
            BME280.read_data(err);
            stdout.put_line("Temperature is " & Integer'Image(BME280.get_temp/100));
            stdout.put_line("Pressure is " & Integer'Image(BME280.get_press/256));
            stdout.put_line("Humidity is " & Integer'Image(BME280.get_hum/1024));
         elsif cmd.starts_with("SERIAL") then
            serial1.put_line("Hello 1 from Ada.");
            serial2.put_line("Hello 2 from Ada.");
            serial2.put_line("Hello 3 from Ada.");
         elsif analog_enable and cmd.starts_with("ANALOG") then
            val := Integer'Value(rest.to_string);
            stdout.put_line("Analog input values:");
            for i in analogs.AIN_Num'Range loop
               stdout.put_line("Channel " & Integer'Image(i) & " has value " &
                                 Integer'Image(Integer(analogs.get(i))));
            end loop;
            stdout.put_line("Testing analog outputs.");
            analog_outs(val);
         else
            stdout.put_line("Unrecognized command <" & cmd.to_string & ">.");
         end if;
      end loop;
      stdout.put_line("User " & user(1..l_user) & " logged off.");
      for i in 1 .. 10 loop
         stdout.new_line;
      end loop;
   end;

   --
   --  Procedure to break up some of the functionality
   --
   procedure analog_outs(v : Integer) is
      val   : SAM3x8e.UInt12 := 0;
      incr  : constant SAM3x8e.UInt12 := SAM3x8e.UInt12(v);
      count : constant Integer := 1000;
   begin
      for i in 1 .. count loop
         analogs.put(0, val);
         val := val + incr;
      end loop;
      analogs.put(0, 0);
      val := 0;
      for i in 1 .. count loop
         analogs.put(1, val);
         val := val + incr;
      end loop;
      analogs.put(0, 1);
   end;

end cli;
