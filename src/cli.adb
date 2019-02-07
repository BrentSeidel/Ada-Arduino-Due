with utils;
with i2c;
with i2c.BME280;
with analogs;
with SAM3x8e;
use type SAM3x8e.UInt12;

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
         utils.uppercase(user);
         stdout.put("Password: ");
         stdin.get_line(pass, l_pass);
         utils.uppercase(pass);
         exit when (l_pass = 8) and (pass(1..l_pass) = "OVERRIDE");
         stdout.put_line("Invalid credentials.  Security has been notified.");
      end loop;
   end;

   --
   --  Procedure for the command line interpreter
   --
   procedure command_loop is
      s : String(1 .. 80);
      l : Integer := 0;
      flag : Boolean;
      err  : i2c.err_code;
      stdout  : constant serial.int.serial_port := serial.int.get_port(0);
      stdin   : constant serial.int.serial_port := serial.int.get_port(0);
      serial1 : constant serial.int.serial_port := serial.int.get_port(1);
      serial2 : constant serial.int.serial_port := serial.int.get_port(2);
      serial3 : constant serial.int.serial_port := serial.int.get_port(3);
   begin
      stdout.put_line("Welcome to the Central Control Computer.");
      loop
         stdout.put(user(1..l_user) & "> ");
         stdin.get_line(s, l);
         stdout.put_line("Got " & Integer'Image(l) & " characters in string.");
         stdout.put_line("String is <" & s(1..l) & ">");
         utils.uppercase(s);
         stdout.put_line("Uppercase string is <" & s(1..l) & ">");
         --
         -- Check for some commands.
         --
         exit when utils.starts_with(s, l, "LOGOUT");
         exit when utils.starts_with(s, l, "LOGOFF");
         exit when utils.starts_with(s, l, "BYE");
         if utils.starts_with(s, l, "FLASH") then
            utils.flash_count := integer'Value(s(6..l));
         elsif utils.starts_with(s, l, "EXIT") then
            stdout.put_line("There is nowhere to exit to.  This is it.");
         elsif utils.starts_with(s, l, "QUIT") then
            stdout.put_line("I can't quit.");
         elsif utils.starts_with(s, l, "INFO") then
            utils.cpu_info;
         elsif utils.starts_with(s, l, "HELP") then
            stdout.put_line("I'm sorry, I can't help you.");
         elsif i2c_good and utils.starts_with(s, l, "BME280") then
            i2c.BME280.start_conversion(err);
            loop
               flag := i2c.BME280.data_ready(err);
               exit when flag;
            end loop;
            i2c.BME280.read_data(err);
            stdout.put_line("Temperature is " & Integer'Image(i2c.BME280.get_temp/100));
            stdout.put_line("Pressure is " & Integer'Image(i2c.BME280.get_press/256));
            stdout.put_line("Humidity is " & Integer'Image(i2c.BME280.get_hum/1024));
         elsif utils.starts_with(s, l, "SERIAL") then
            serial1.put_line("Hello 1 from Ada.");
            serial2.put_line("Hello 2 from Ada.");
            serial2.put_line("Hello 3 from Ada.");
         elsif analog_enable and utils.starts_with(s, l, "ANALOG") then
            stdout.put_line("Analog input values:");
            for i in analogs.AIN_Num'Range loop
               stdout.put_line("Channel " & Integer'Image(i) & " has value " &
                                 Integer'Image(Integer(analogs.get(i))));
            end loop;
            stdout.put_line("Testing analog outputs.");
            analog_outs;
         else
            stdout.put_line("Unrecognized command.");
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
   procedure analog_outs is
      val : SAM3x8e.UInt12 := 0;
   begin
      for i in 1 .. 10000 loop
         analogs.put(0, val);
         val := val + 32;
      end loop;
      for i in 1 .. 10000 loop
         analogs.put(1, val);
         val := val + 32;
      end loop;
   end;

end cli;
