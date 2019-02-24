with utils;
with i2c.BME280;
with analogs;
with SAM3x8e;
use type SAM3x8e.Byte;
use type SAM3x8e.UInt12;
with BBS.units;
with Ada.Synchronous_Task_Control;

package body cli is

   --
   --  Logon procedure
   --
   procedure logon is
      stdout : constant serial.int.serial_port := serial.int.get_port(0);
      stdin  : constant serial.int.serial_port := serial.int.get_port(0);
      user   : String(1 .. 20);
      l_user : Integer := 0;
   begin
      loop
         stdout.put_line("MovieOS V27.5.2 Central Control Computer");
         stdout.put("Username: ");
         stdin.get_line(user, l_user);
         strings.uppercase(user);
         strings.to_bounded(username, user, l_user);
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
      line : aliased strings.bounded(80);
      cmd  : aliased strings.bounded(80);
      rest : aliased strings.bounded(80);
      s    : String(1 .. 80);
      l    : Integer := 0;
      val  : Integer;
   begin
      stdout.put_line("Welcome to the Central Control Computer.");
      loop
         stdout.put(username.to_string & "> ");
         stdin.get_line(s, l);
         strings.to_bounded(line, s, l);
         line.token(' ', cmd, rest);
         cmd.uppercase;
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
         elsif cmd.starts_with("I2C") then
            process_i2c(rest);
         elsif cmd.starts_with("STOP") then
            stop_task(rest);
         elsif cmd.starts_with("START") then
            start_task(rest);
         elsif cmd.starts_with("GPIO") then
            handle_gpio(rest);
         elsif cmd.starts_with("STATUS") then
            show_status;
         else
            stdout.put_line("Unrecognized command <" & cmd.to_string & ">.");
         end if;
      end loop;
      stdout.put_line("User " & username.to_string & " logged off.");
      for i in 1 .. 10 loop
         stdout.new_line;
      end loop;
   end;

   --
   --  Procedure to break up some of the functionality.
   --
   --  Put a sawtooth wave on both analog outputs - one after the other.
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
   --
   --  I2C related operations.  Currently supported commands are:
   --    SCAN
   --    BME280
   --
   procedure process_i2c(r : strings.bounded) is
      i2c0   : aliased i2c.i2c_interface_record := (hw => i2c.get_device(0));
      i2c1   : aliased i2c.i2c_interface_record := (hw => i2c.get_device(1));
      BME280 : constant i2c.BME280.BME280_ptr := i2c.BME280.get_BME280;
      stdout : constant serial.int.serial_port := serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
      err    : i2c.err_code;
      flag   : Boolean;
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("SCAN") then
         stdout.put_line("Scanning I2C bus 0");
         flag := False;
         for i in SAM3x8e.UInt7 range 16#0E# .. 16#77# loop
            i2c0.read(i, 0, 1, err);
            if err = i2c.none then
               stdout.put_line(" I2C device found at " & utils.byte_to_str(SAM3x8e.Byte(i)));
               flag := True;
            end if;
         end loop;
         if not flag then
            stdout.put_line("No devices found on bus 0");
         end if;
         stdout.put_line("Scanning I2C bus 1");
         flag := False;
         for i in SAM3x8e.UInt7 range 16#0E# .. 16#77# loop
            i2c1.read(i, 0, 1, err);
            if err = i2c.none then
               stdout.put_line(" I2C device found at " & utils.byte_to_str(SAM3x8e.Byte(i)));
               flag := True;
            end if;
         end loop;
         if not flag then
            stdout.put_line("No devices found on bus 1");
         end if;
      elsif cmd.starts_with("READ") then
         null;
      elsif (bme280_found /= absent) and cmd.starts_with("BME280") then
         stdout.put_line("BME280: Starting conversion.");
         BME280.start_conversion(err);
         stdout.put_line("BME280: Waiting for conversion.");
         loop
            flag := BME280.data_ready(err);
            exit when flag;
         end loop;
         stdout.put_line("BME280: Conversion complete.");
         BME280.read_data(err);
         stdout.put_line("BME280 Data:");
         stdout.put_line("  Temperature is " & Integer'Image(BME280.get_temp/100));
         stdout.put_line("  Pressure is " & Integer'Image(BME280.get_press/256));
         stdout.put_line("  Humidity is " & Integer'Image(BME280.get_hum/1024));
      else
         stdout.put_line("Unrecognized option <" & cmd.to_string & ">");
      end if;
   end;
   --
   --  Stops/pauses a currently running task.  Currently defined tasks are:
   --    FLASHER
   --    TOGGLE
   --
   procedure stop_task(r : strings.bounded) is
      stdout : constant serial.int.serial_port := serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("FLASHER") then
         utils.ctrl_flasher(False);
      elsif cmd.starts_with("TOGGLE") then
         utils.ctrl_toggle(False);
      else
         stdout.put_line("Unknown task <" & cmd.to_string & ">");
      end if;
   end;
   --
   --  Starts/continues a paused task.  Currently defined tasks are:
   --    FLASHER
   --    TOGGLE
   --
   procedure start_task(r : strings.bounded) is
      stdout : constant serial.int.serial_port := serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("FLASHER") then
         utils.ctrl_flasher(True);
      elsif cmd.starts_with("TOGGLE") then
         utils.ctrl_toggle(True);
      else
         stdout.put_line("Unknown task <" & cmd.to_string & ">");
      end if;
   end;
   --
   --  Handle GPIO related commands.  Currently defined commands are:
   --    SET
   --    GET
   --
   procedure handle_gpio(r : strings.bounded) is
      stdout : constant serial.int.serial_port := serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
      pin    : aliased strings.bounded(80);
      state  : aliased strings.bounded(80);
      gpio   : aliased pio.gpio_record;
      err    : Boolean := False;
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      rest.token(' ', pin, state);
      gpio := parse_pin(pin, err);
      if err then
         stdout.put_line("<" & pin.to_string & "> is not a recognized pin");
         return;
      end if;
      if cmd.starts_with("SET") then
         gpio.config(pio.gpio_output);
         if state.str(1) = '0' then
            gpio.set(0);
         elsif state.str(1) = '1' then
            gpio.set(1);
         else
            stdout.put_line("Unknown state <" & state.to_string & ">");
         end if;
      elsif cmd.starts_with("GET") then
         stdout.put_line("Pin value is " & SAM3x8e.Bit'Image(gpio.get));
      else
         stdout.put_line("Unknown option <" & cmd.to_string & ">");
      end if;
   end;
   --
   function parse_pin(r : strings.bounded; err : out Boolean) return pio.gpio_record is
      gpio : pio.gpio_record := (ctrl => pio.PIOA'Access, bit => 0);
      temp : Character := r.str(1);
   begin
      err := False;
      if (r.len < 2) or (r.len > 3) then
         err := True;
      end if;
      case temp is
         when 'A' | 'a' =>
            gpio.ctrl := pio.PIOA'Access;
         when 'B' | 'b' =>
            gpio.ctrl := pio.PIOB'Access;
         when 'C' | 'c' =>
            gpio.ctrl := pio.PIOC'Access;
         when 'D' | 'd' =>
            gpio.ctrl := pio.PIOD'Access;
         when others =>
            err := True;
      end case;
      gpio.bit := integer'Value(r.str(2 .. r.len));
      if (gpio.bit < 0) or (gpio.bit > 31) then
         err := True;
      end if;
      return gpio;
   end;
   --
   procedure i2c_probe(c : i2c.port_id) is
      stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
      i2c_bus : aliased i2c.i2c_interface_record := (hw => i2c.get_device(c));
      BME280  : constant i2c.BME280.BME280_ptr := i2c.BME280.get_BME280;
      err     : i2c.err_code;
      temp    : SAM3x8e.Byte;
   begin
      stdout.put_line("I2C: Probing bus " & i2c.port_id'Image(c));
      --
      --  Looking for L3GD20
      --
      stdout.put_line("I2C: Getting device ID at 16#6B#.");
      temp := i2c_bus.read(16#6b#, 16#0f#, err);
      if err = i2c.none then
         stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
         if temp = 16#c4# then
            stdout.put_line("I2C: L3GD20 found.");
         else
            stdout.put_line("I2C: Unrecognized device found at address 16#6B#.");
         end if;
      else
         stdout.put_line("I2C: No device found at address 16#6B#.");
      end if;
      --
      --  Looking for BMP180 or BME280
      --
      stdout.put_line("I2C: Getting device ID at 16#77#.");
      temp := i2c_bus.read(i2c.BME280.addr, i2c.BME280.id, err);
      stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
      if err = i2c.none then
      if temp = 16#60# then
            stdout.put_line("I2C: BME280 Found, configuring");
            BME280.configure(i2c.get_device(c), i2c.BME280.addr, err);
            stdout.put_line("I2C: BME280 Configuration error code is " & i2c.err_code'Image(err));
            if err = i2c.none then
               if c = 0 then
                  bme280_found := bus0;
               else
                  bme280_found := bus1;
               end if;
            else
               stdout.put_line("I2C: BME280 initialization failed - disabling.");
               cli.bme280_found := cli.absent;
            end if;
         elsif temp = 16#55# then
            stdout.put_line("I2C: BMP180 Found.");
            if c = 0 then
               bmp180_found := bus0;
            else
               bmp180_found := bus1;
            end if;
         else
            stdout.put_line("I2C: Unrecognized device found at address 16#77#.");
         end if;
      else
         stdout.put_line("I2C: No device found at address 16#77#.");
      end if;
   end;
   --
   procedure show_status is
      stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
   begin
      stdout.put_line("System Status Report");
      stdout.put_line("Task List");
      stdout.put("FLASHER  ");
      if utils.state_flasher then
         stdout.put_line("running");
      else
         stdout.put_line("paused");
      end if;
      stdout.put("TOGGLE   ");
      if utils.state_toggle then
         stdout.put_line("running");
      else
         stdout.put_line("paused");
      end if;
      stdout.new_line;
      stdout.put_line("Device list");
      stdout.put_line("BMP180     " & i2c_device_location'Image(bmp180_found));
      stdout.put_line("BME280     " & i2c_device_location'Image(bme280_found));
      stdout.put_line("L3GD20     " & i2c_device_location'Image(l3gd20_found));
      stdout.put_line("LSM303DLHC " & i2c_device_location'Image(lsm303dlhc_found));
   end;
   --

end cli;
