with Ada.Text_IO;
with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with serial.polled;
with serial.int;
with pio;
with utils;
with analogs;
with cli;
with i2c;
use type i2c.err_code;
with i2c.BME280;
with SAM3x8e;
use type SAM3x8e.Byte;

procedure Main is
   i2c_num : constant i2c.port_id := 0;
   err  : i2c.err_code;
   stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
   stdin   : constant serial.int.serial_port := serial.int.get_port(0);
   serial1 : constant serial.int.serial_port := serial.int.init(1, 115_200);
   serial2 : constant serial.int.serial_port := serial.int.init(2, 115_200);
   serial3 : constant serial.int.serial_port := serial.int.init(3, 115_200);
   BME280  : constant i2c.BME280.BME280_ptr := i2c.BME280.get_BME280;
   temp    : SAM3x8e.Byte;
   i2c_chan : aliased i2c.i2c_interface_record := (hw => i2c.get_device(i2c_num));

begin
   stdout.put_line("Central Control Computer starting up:");
   if cli.analog_enable then
      stdout.put_line("Analogs: Setting up inputs");
      analogs.setup_ain;
      stdout.put_line("Analogs: Enabling inputs");
      for i in analogs.AIN_Num'Range loop
         analogs.enable_ain(i, True);
      end loop;
      stdout.put_line("Analogs: Free run");
      analogs.free_run(True);
      stdout.put_line("Analogs: Setting up outputs");
      analogs.setup_aout;
      stdout.put_line("Analogs: Enabling outputs");
      analogs.enable_aout(0, True);
      analogs.enable_aout(1, True);
   else
      stdout.put_line("Analogs: Disabled");
   end if;
   stdout.flush;
   if cli.i2c_enable then
      stdout.put_line("I2C: Initialization");
      i2c.init(i2c_num, i2c.low100);
      stdout.put_line("I2C: Getting device ID at 16#6B#.");
      stdout.flush;
      temp := i2c_chan.read(16#6b#, 16#0f#, err);
--      stdout.put_line("I2C: Device ID error code is " & i2c.err_code'Image(err));
      stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
      if temp = 16#b4# then
         stdout.put_line("I2C: L3GD20 found.");
      else
         stdout.put_line("I2C: Unrecognized device found at address 16#6B#.");
      end if;
      stdout.put_line("I2C: Getting device ID at 16#77#.");
      stdout.flush;
      temp := i2c_chan.read(i2c.BME280.addr, i2c.BME280.id, err);
--      stdout.put_line("I2C: Device ID error code is " & i2c.err_code'Image(err));
      stdout.put_line("I2C: Device ID is " & utils.byte_to_str(temp));
      if temp = 16#60# then
         stdout.put_line("I2C: BME280 Found, configuring");
         BME280.configure(i2c.get_device(0), i2c.BME280.addr, err);
         stdout.put_line("I2C: BME280 Configuration error code is " & i2c.err_code'Image(err));
         if err = i2c.none then
            cli.bme280_good := True;
         else
            stdout.put_line("I2C: Initialization failed - disabling.");
            cli.bme280_good := False;
         end if;
      elsif temp = 16#55# then
         stdout.put_line("I2C: BMP180 Found.");
      else
         stdout.put_line("I2C: Unrecognized device found at address 16#77#.");
      end if;
   else
      stdout.put_line("I2C: Disabled.");
   end if;
   stdout.put_line("GPIO: Configuing RS485 control pin");
   pio.RS485_PIN.config(pio.gpio_output);
   pio.RS485_PIN.set(0);
   stdout.put_line("Serial: Enabling RS485 control on serial 1");
   serial1.enable_rs485(pio.rs485_pin);
   stdout.put_line("LED: Starting LED flashing task");
   utils.start_flasher;
   ada.Text_IO.Put_Line("Hello from Ada.Text_IO!");
   stdout.put_line("Serial: Enable receive on stdin");
   stdin.rx_enable(True);
   stdout.put_line("BOOT: Setup complete.");
   loop
      cli.logon;
      cli.command_loop;
   end loop;
end Main;
