--with BBS.embed.due.serial.int;
with utils;
with analogs;
with SAM3x8e;
use type SAM3x8e.UInt12;
with BBS.embed.AIN.due;
with BBS.embed.i2c.BME280;
with BBS.embed.i2c.BMP180;
with BBS.lisp;
with BBS.lisp.info;
with lisp;
package body cli is

   --
   --  Logon procedure
   --
   procedure logon is
      stdout : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      stdin  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      user   : String(1 .. 20);
      l_user : Integer := 0;
   begin
      loop
         stdout.put_line("MovieOS V27.5.3 Central Control Computer");
         stdout.put_line("Now with lisp");
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
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      stdin   : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      serial1 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(1);
      serial2 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(2);
      serial3 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(3);
      ain  : BBS.embed.AIN.due.Due_AIN_record;
      ain_val : BBS.embed.uint12;
      line : aliased strings.bounded(80);
      cmd  : aliased strings.bounded(80);
      rest : aliased strings.bounded(80);
      s    : String(1 .. 80);
      l    : Integer := 0;
      val  : Integer;
   begin
      stdout.put_line("Welcome to the Central Control Computer.");
      BBS.lisp.init(BBS.embed.due.serial.int.Put_Line'Access,
                    BBS.embed.due.serial.int.Put'Access,
                    BBS.embed.due.serial.int.New_Line'Access,
                    BBS.embed.due.serial.int.Get_Line'Access);
      BBS.lisp.embed.init;
      lisp.init;
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
            serial3.put_line("Hello 3 from Ada.");
         elsif analog_enable and cmd.starts_with("ANALOG") then
            val := Integer'Value(rest.to_string);
            stdout.put_line("Analog input values:");
            for i in BBS.embed.AIN.due.AIN_Num'Range loop
               ain.channel := i;
               ain_val := ain.get;
               stdout.put_line("Channel " & Integer'Image(i) & " has value " &
                                 Integer'Image(Integer(ain_val)));
            end loop;
            stdout.put_line("Testing analog outputs.");
            analog_outs(val);
         elsif cmd.starts_with("I2C") then
            process_i2c(stdout, rest);
         elsif cmd.starts_with("STOP") then
            stop_task(rest);
         elsif cmd.starts_with("START") then
            start_task(rest);
         elsif cmd.starts_with("STATUS") then
            show_status(stdout);
         elsif cmd.starts_with("LISP") then
            stdout.Put_Line("Tiny lisp interpreter written in Ada.");
            stdout.Put_Line(BBS.lisp.info.name & " " & BBS.lisp.info.version_string &
                       " " & BBS.lisp.info.build_date);
            bbs.lisp.repl;
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
   --    PROBE
   --    BME280
   --    BMP180
   --
   procedure process_i2c(s : BBS.embed.due.serial.int.serial_port; r : strings.bounded) is
      i2c0   : aliased constant BBS.embed.i2c.due.due_i2c_interface := BBS.embed.i2c.due.get_interface(0);
      i2c1   : aliased constant BBS.embed.i2c.due.due_i2c_interface := BBS.embed.i2c.due.get_interface(1);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
      err    : BBS.embed.i2c.err_code;
      flag   : Boolean;
      temp   : BBS.embed.uint8;
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("SCAN") then
         s.put_line("Scanning I2C bus 0");
         flag := False;
         for i in BBS.embed.addr7 range 16#0E# .. 16#77# loop
            temp := i2c0.read(i, 0, err);
            if err = BBS.embed.i2c.none then
               s.put_line(" I2C device found at " & utils.byte_to_str(SAM3x8e.Byte(i)));
               flag := True;
            end if;
         end loop;
         if not flag then
            s.put_line("No devices found on bus 0");
         end if;
         s.put_line("Scanning I2C bus 1");
         flag := False;
         for i in BBS.embed.addr7 range 16#0E# .. 16#77# loop
            temp := i2c1.read(i, 0, err);
            if err = BBS.embed.i2c.none then
               s.put_line(" I2C device found at " & utils.byte_to_str(SAM3x8e.Byte(i)));
               flag := True;
            end if;
         end loop;
         if not flag then
            s.put_line("No devices found on bus 1");
         end if;
      elsif cmd.starts_with("PROBE") then
         BBS.lisp.embed.bme280_found     := BBS.lisp.embed.absent;
         BBS.lisp.embed.bmp180_found     := BBS.lisp.embed.absent;
         BBS.lisp.embed.l3gd20_found     := BBS.lisp.embed.absent;
         BBS.lisp.embed.pca9685_found    := BBS.lisp.embed.absent;
         BBS.lisp.embed.lsm303dlhc_found := BBS.lisp.embed.absent;
         BBS.lisp.embed.mcp23017_0_found := BBS.lisp.embed.absent;
         BBS.lisp.embed.mcp23017_2_found := BBS.lisp.embed.absent;
         BBS.lisp.embed.mcp23017_6_found := BBS.lisp.embed.absent;
         i2c_probe(0);
         i2c_probe(1);
      elsif cmd.starts_with("READ") then
         null;
      elsif (BBS.lisp.embed.bme280_found /= BBS.lisp.embed.absent) and cmd.starts_with("BME280") then
         BBS.lisp.embed.BME280_info.start_conversion(err);
         loop
            flag := BBS.lisp.embed.BME280_info.data_ready(err);
            exit when flag;
            exit when err /= BBS.embed.i2c.none;
         end loop;
         if err /= BBS.embed.i2c.none then
            s.put_line("BME280 Error: " & BBS.embed.i2c.err_code'Image(err));
         else
            BBS.lisp.embed.BME280_info.read_data(err);
            s.put_line("BME280 Data:");
            s.put_line("  Temperature is " & Integer'Image(BBS.lisp.embed.BME280_info.get_temp/100));
            s.put_line("  Pressure is " & Integer'Image(BBS.lisp.embed.BME280_info.get_press/256));
            s.put_line("  Humidity is " & Integer'Image(BBS.lisp.embed.BME280_info.get_hum/1024));
         end if;
      elsif (BBS.lisp.embed.bmp180_found /= BBS.lisp.embed.absent) and cmd.starts_with("BMP180") then
         BBS.lisp.embed.BMP180_info.start_conversion(BBS.embed.i2c.BMP180.cvt_temp, err);
         loop
            flag := BBS.lisp.embed.BMP180_info.data_ready(err);
            exit when flag;
            exit when err /= BBS.embed.i2c.none;
         end loop;
         if err /= BBS.embed.i2c.none then
            s.put_line("BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
         else
            s.put_line("BMP180 Data:");
            s.put_line("  Temperature is " & Integer'Image(BBS.lisp.embed.BMP180_info.get_temp(err)/10) &
                         "C");
            BBS.lisp.embed.BMP180_info.start_conversion(BBS.embed.i2c.BMP180.cvt_press0, err);
            loop
               flag := BBS.lisp.embed.BMP180_info.data_ready(err);
               exit when flag;
               exit when err /= BBS.embed.i2c.none;
            end loop;
            if err /= BBS.embed.i2c.none then
               s.put_line("BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
            else
               s.put_line("  Pressure is " & Integer'Image(BBS.lisp.embed.BMP180_info.get_press(err)) &
                              "Pa");
            end if;
         end if;
      else
         s.put_line("Unrecognized option <" & cmd.to_string & ">");
      end if;
   end;
   --
   --  Stops/pauses a currently running task.  Currently defined tasks are:
   --    FLASHER
   --
   procedure stop_task(r : strings.bounded) is
      stdout : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("FLASHER") then
         utils.ctrl_flasher(False);
      else
         stdout.put_line("Unknown task <" & cmd.to_string & ">");
      end if;
   end;
   --
   --  Starts/continues a paused task.  Currently defined tasks are:
   --    FLASHER
   --
   procedure start_task(r : strings.bounded) is
      stdout : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      line   : aliased strings.bounded := r;
      cmd    : aliased strings.bounded(80);
      rest   : aliased strings.bounded(80);
   begin
      line.token(' ', cmd, rest);
      cmd.uppercase;
      if cmd.starts_with("FLASHER") then
         utils.ctrl_flasher(True);
      else
         stdout.put_line("Unknown task <" & cmd.to_string & ">");
      end if;
   end;
   --
   procedure i2c_probe(c : BBS.embed.i2c.due.port_id) is
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
   begin
      stdout.put_line("I2C: Probing bus " & BBS.embed.i2c.due.port_id'Image(c));
      --
      --  Look for the LSM303DLHC.  This device exist at two I2C addresses.  If
      --  something is present at both addresses, assume that the device is
      --  present.  Currently commented out because the LSM303DLHC package uses
      --  a square root function that is not avaialable on the Ravenscar SFP.
      --
--        stdout.put_line("I2C: Probing address 16#19#");
--        temp := i2c_bus.read(BBS.embed.i2c.LSM303DLHC.addr_accel,
--                             BBS.embed.i2c.LSM303DLHC.accel_status, err);
--        if err = BBS.embed.i2c.none then
--           stdout.put_line("I2C: Probing address 16#1e#");
--           temp := i2c_bus.read(BBS.embed.i2c.LSM303DLHC.addr_mag,
--                                BBS.embed.i2c.LSM303DLHC.mag_sr, err);
--           if err = BBS.embed.i2c.none then
--              if c = 0 then
--                 lsm303dlhc_found := bus0;
--              else
--                 lsm303dlhc_found := bus1;
--              end if;
--           else
--              stdout.put_line("I2C: No device found.");
--           end if;
--        else
--           stdout.put_line("I2C: No device found.");
--        end if;
      --
      --  Probe various I2C devices
      --
      probe_l3gd20(c, BBS.embed.i2c.L3GD20H.addr, BBS.lisp.embed.L3GD20_info, BBS.lisp.embed.l3gd20_found);
      probe_bme280_bmp180(c, BBS.embed.i2c.BME280.addr);
      probe_pca9685(c, BBS.embed.i2c.PCA9685.addr_0, BBS.lisp.embed.PCA9685_info, BBS.lisp.embed.pca9685_found);
      probe_mcp23017(c, BBS.embed.i2c.MCP23017.addr_6, BBS.lisp.embed.MCP23017_6_info, BBS.lisp.embed.mcp23017_6_found);
      probe_mcp23017(c, BBS.embed.i2c.MCP23017.addr_2, BBS.lisp.embed.MCP23017_2_info, BBS.lisp.embed.mcp23017_2_found);
      probe_mcp23017(c, BBS.embed.i2c.MCP23017.addr_0, BBS.lisp.embed.MCP23017_0_info, BBS.lisp.embed.mcp23017_0_found);
   end;
   --
   procedure probe_bme280_bmp180(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7) is
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      i2c_bus : constant BBS.embed.i2c.i2c_interface := BBS.embed.i2c.i2c_interface(BBS.embed.i2c.due.get_interface(c));
      err     : BBS.embed.i2c.err_code;
      temp    : BBS.embed.uint8;
   begin
      stdout.put_line("I2C: --------");
      stdout.put_line("I2C: Getting device ID at 16#" &
                        utils.byte_to_str(BBS.embed.uint8(a)) &
                        "# for BMP180 or BME280.");
      temp := i2c_bus.read(a, BBS.embed.i2c.BME280.id, err);
      stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
      if err = BBS.embed.i2c.none then
         if temp = 16#60# then
            stdout.put_line("I2C: BME280 Found, configuring");
            BBS.lisp.embed.BME280_info.configure(i2c_bus, a, err);
            stdout.put_line("I2C: BME280 Configuration error code is " & BBS.embed.i2c.err_code'Image(err));
            if err = BBS.embed.i2c.none then
               if c = 0 then
                  BBS.lisp.embed.bme280_found := BBS.lisp.embed.bus0;
               else
                  BBS.lisp.embed.bme280_found := BBS.lisp.embed.bus1;
               end if;
            else
               stdout.put_line("I2C: BME280 initialization failed - disabling.");
            end if;
         elsif temp = 16#55# then
            stdout.put_line("I2C: BMP180 Found, configuring.");
            BBS.lisp.embed.BMP180_info.configure(i2c_bus, a, err);
            stdout.put_line("I2C: BMP180 Configuration error code is " & BBS.embed.i2c.err_code'Image(err));
            if err = BBS.embed.i2c.none then
               if c = 0 then
                  BBS.lisp.embed.bmp180_found := BBS.lisp.embed.bus0;
               else
                  BBS.lisp.embed.bmp180_found := BBS.lisp.embed.bus1;
               end if;
            else
               stdout.put_line("I2C: BMP180 initialization failed - disabling.");
            end if;
         else
            stdout.put_line("I2C: Unrecognized device found at address 16#" &
                              utils.byte_to_str(BBS.embed.uint8(a)) & "#.");
         end if;
      else
         stdout.put_line("I2C: No device found at address 16#" &
                           utils.byte_to_str(BBS.embed.uint8(a)) & "#.");
         stdout.put_line("I2C: Error code returned: " & BBS.embed.i2c.err_code'Image(err));
      end if;
   end;
   --
   procedure probe_l3gd20(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                          d : in out BBS.embed.i2c.L3GD20H.L3GD20H_record;
                          f : in out BBS.lisp.embed.i2c_device_location) is
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      i2c_bus : constant BBS.embed.i2c.i2c_interface := BBS.embed.i2c.i2c_interface(BBS.embed.i2c.due.get_interface(c));
      err     : BBS.embed.i2c.err_code;
      temp    : BBS.embed.uint8;
   begin
      stdout.put_line("I2C: --------");
      stdout.put_line("I2C: Probing address 16#" &
                        utils.byte_to_str(BBS.embed.uint8(a)) &
                        "# for L3GD20.");
      temp := i2c_bus.read(BBS.embed.i2c.L3GD20H.addr,
                           BBS.embed.i2c.L3GD20H.who_am_i, err);
      if err = BBS.embed.i2c.none then
         stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
--         if temp = 2#1101_0100# then
            stdout.put_line("I2C: L3GD20H found, configuring.");
            d.configure(i2c_bus, a, err);
            if err = BBS.embed.i2c.none then
               if c = 0 then
                  f := BBS.lisp.embed.bus0;
               else
                  f := BBS.lisp.embed.bus1;
               end if;
            else
               stdout.put_line("I2C: L3GD20H initialization failed - disabling.");
            end if;
--         else
--            stdout.put_line("I2C: Unrecognized device found at address 16#" &
--                              utils.byte_to_str(BBS.embed.uint8(BBS.embed.i2c.L3GD20H.addr)) & "#.");
--         end if;
      else
         stdout.put_line("I2C: No device found at address 16#" &
                           utils.byte_to_str(BBS.embed.uint8(a)) & "#.");
         stdout.put_line("I2C: Error code returned: " & BBS.embed.i2c.err_code'Image(err));
      end if;

   end;
   --
   procedure probe_mcp23017(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                            d : in out BBS.embed.i2c.MCP23017.MCP23017_record;
                            f : in out BBS.lisp.embed.i2c_device_location) is
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      i2c_bus : constant BBS.embed.i2c.i2c_interface := BBS.embed.i2c.i2c_interface(BBS.embed.i2c.due.get_interface(c));
      err     : BBS.embed.i2c.err_code;
      temp    : BBS.embed.uint8;
   begin
      stdout.put_line("I2C: --------");
      stdout.put_line("I2C: Probing address 16#" &
                        utils.byte_to_str(BBS.embed.uint8(a)) &
                        "# for MCP23017.");
      temp := i2c_bus.read(a, BBS.embed.i2c.MCP23017.IOCON, err);
      if err = BBS.embed.i2c.none then
         stdout.put_line("I2C: MCP23017 Found, configuring");
         d.configure(i2c_bus, a, err);
         if c = 0 then
            f := BBS.lisp.embed.bus0;
         else
            f := BBS.lisp.embed.bus1;
         end if;
      else
         stdout.put_line("I2C: No device found at address 16#" &
                           utils.byte_to_str(BBS.embed.uint8(a)) & "#.");
         stdout.put_line("I2C: Error code returned: " & BBS.embed.i2c.err_code'Image(err));
      end if;
   end;
   --
   procedure probe_pca9685(c : bbs.embed.i2c.due.port_id; a : BBS.embed.addr7;
                           d : in out BBS.embed.i2c.PCA9685.PS9685_record;
                           f : in out BBS.lisp.embed.i2c_device_location) is
      stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      i2c_bus : constant BBS.embed.i2c.i2c_interface := BBS.embed.i2c.i2c_interface(BBS.embed.i2c.due.get_interface(c));
      err     : BBS.embed.i2c.err_code;
   begin
      stdout.put_line("I2C: --------");
      stdout.put_line("I2C: probing address 16#" &
                        utils.byte_to_str(BBS.embed.uint8(a)) &
                        "# for PCA9685.");
      i2c_bus.read(BBS.embed.i2c.PCA9685.addr_0, BBS.embed.i2c.PCA9685.MODE1, 1, err);
      if err = BBS.embed.i2c.none then
         stdout.put_line("I2C: PCA9685 Found, configuring");
         d.configure(i2c_bus, BBS.embed.i2c.PCA9685.addr_0, err);
         stdout.put_line("I2C: PCA9685 Configuration error code is " & BBS.embed.i2c.err_code'Image(err));
         if err = BBS.embed.i2c.none then
            if c = 0 then
               f := BBS.lisp.embed.bus0;
            else
               f := BBS.lisp.embed.bus1;
            end if;
         else
            stdout.put_line("I2C: PCA9685 initialization failed - disabling.");
         end if;
      else
         stdout.put_line("I2C: No device found at address 16#" &
                           utils.byte_to_str(BBS.embed.uint8(a)) & "#.");
         stdout.put_line("I2C: Error code returned: " & BBS.embed.i2c.err_code'Image(err));
      end if;
   end;
   --
   procedure show_status(s : BBS.embed.due.serial.int.serial_port) is
   begin
      s.put_line("System Status Report");
      s.put_line("Task List");
      s.put("FLASHER  ");
      if utils.state_flasher then
         s.put_line("running");
      else
         s.put_line("paused");
      end if;
      s.new_line;
      s.put_line("Device list");
      s.put_line("BMP180     " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.bmp180_found));
      s.put_line("BME280     " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.bme280_found));
      s.put_line("L3GD20     " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.l3gd20_found));
      s.put_line("LSM303DLHC " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.lsm303dlhc_found));
      s.put_line("PCA9685    " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.pca9685_found));
      s.put_line("MCP23017-0 " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.mcp23017_0_found));
      s.put_line("MCP23017-2 " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.mcp23017_2_found));
      s.put_line("MCP23017-6 " & BBS.lisp.embed.i2c_device_location'Image(BBS.lisp.embed.mcp23017_6_found));
   end;
   --

end cli;
