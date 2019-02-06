with utils;
with i2c;
with i2c.BME280;
with analogs;

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
         exit when s(1..6) = "LOGOUT";
         exit when s(1..6) = "LOGOFF";
         exit when s(1..3) = "BYE";
         if s(1..5) = "FLASH" then
            utils.flash_count := integer'Value(s(6..l));
         elsif s(1..4) = "EXIT" then
            stdout.put_line("There is nowhere to exit to.  This is it.");
         elsif s(1..4) = "QUIT" then
            stdout.put_line("I can't quit.");
         elsif s(1..4) = "INFO" then
            utils.cpu_info;
         elsif s(1..4) = "HELP" then
            stdout.put_line("I'm sorry, I can't help you.");
         elsif i2c_good and (s(1..6) = "BME280") then
            i2c.BME280.start_conversion(err);
            loop
               flag := i2c.BME280.data_ready(err);
               exit when flag;
            end loop;
            i2c.BME280.read_data(err);
            stdout.put_line("Temperature is " & Integer'Image(i2c.BME280.get_temp/100));
            stdout.put_line("Pressure is " & Integer'Image(i2c.BME280.get_press/256));
            stdout.put_line("Humidity is " & Integer'Image(i2c.BME280.get_hum/1024));
         elsif s(1..5) = "OTHER" then
            serial1.put_line("Hello 1 from Ada.");
            serial2.put_line("Hello 2 from Ada.");
            serial2.put_line("Hello 3 from Ada.");
         elsif analog_enable and (s(1..6) = "ANALOG") then
            stdout.put_line("Analog input values:");
            for i in analogs.AIN_type'Range loop
               stdout.put_line("Channel " & Integer'Image(i) & " has value " &
                                 Integer'Image(Integer(analogs.get(i))));
            end loop;
         else
            stdout.put_line("Unrecognized command.");
         end if;
      end loop;
      stdout.put_line("User " & user(1..l_user) & " logged off.");
   end;

end cli;
