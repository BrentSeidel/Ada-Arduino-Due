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
   stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
   stdin   : constant serial.int.serial_port := serial.int.get_port(0);
   serial1 : constant serial.int.serial_port := serial.int.init(1, 115_200);
   serial2 : constant serial.int.serial_port := serial.int.init(2, 115_200);
   serial3 : constant serial.int.serial_port := serial.int.init(3, 115_200);
   i2c_0   : aliased i2c.i2c_interface_record := (hw => i2c.get_device(0));
   i2c_1   : aliased i2c.i2c_interface_record := (hw => i2c.get_device(1));

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
   --
   --  I2C device initialization
   --
   if cli.i2c_enable then
      stdout.put_line("I2C: Initialization");
      i2c.init(0, i2c.low100);
      i2c.init(1, i2c.low100);
      cli.i2c_probe(0);
      cli.i2c_probe(1);
   else
      stdout.put_line("I2C: Disabled.");
   end if;
   --
   --  Other initializations
   --
   stdout.put_line("GPIO: Configuing RS485 control pin");
   pio.RS485_PIN.config(pio.gpio_output);
   pio.RS485_PIN.set(0);
   stdout.put_line("Serial: Enabling RS485 control on serial 1");
   serial1.enable_rs485(pio.rs485_pin);
   stdout.put_line("LED: Starting LED flashing task");
   utils.ctrl_flasher(True);
--   ada.Text_IO.Put_Line("Hello from Ada.Text_IO!");
   stdout.put_line("Serial: Enable receive on stdin");
   stdin.rx_enable(True);
   stdout.put_line("BOOT: Setup complete.");
   --
   --  Initializations complete, start the CLI loop.
   --
   loop
      cli.logon;
      cli.command_loop;
   end loop;
end Main;
