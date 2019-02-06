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

procedure Main is
   err  : i2c.err_code;
   stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
   stdin   : constant serial.int.serial_port := serial.int.get_port(0);
   serial1 : constant serial.int.serial_port := serial.int.init(1, 115_200);
   serial2 : constant serial.int.serial_port := serial.int.init(2, 115_200);
   serial3 : constant serial.int.serial_port := serial.int.init(3, 115_200);

begin
   stdout.put_line("Central Control Computer starting up:");
   if cli.analog_enable then
      stdout.put_line("Analogs: Setting up");
      analogs.setup;
      stdout.put_line("Analogs: Enabling inputs");
      for i in 0 .. 7 loop
         analogs.enable(i, True);
      end loop;
      analogs.enable(10, True);
      analogs.enable(11, True);
      analogs.enable(12, True);
      analogs.enable(13, True);
--      analogs.enable(15, True);
      stdout.put_line("Analogs: Free run");
      analogs.free_run(True);
   else
      stdout.put_line("Analogs: Disabled");
   end if;
   if cli.i2c_enable then
      stdout.put_line("I2C: Initialization");
      i2c.init(0, i2c.low100);
      stdout.put_line("I2C: Configuring BME280");
      i2c.BME280.configure(0, i2c.BME280.addr, err);
      stdout.put_line("I2C: BME280 Configuration error code is " & i2c.err_code'Image(err));
      if err = i2c.none then
         cli.i2c_good := True;
      else
         stdout.put_line("I2C: Initialization failed - disabling.");
         cli.i2c_good := False;
      end if;
   else
      stdout.put_line("I2C: Disabled.");
      cli.i2c_good := False;
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
