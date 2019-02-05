with Ada.Text_IO;
with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with serial.polled;
with serial.int;
with pio;
with utils;
with cli;
with i2c;
with i2c.BME280;
with SAM3x8e;

procedure Main is
   l : Integer := 0;
   err  : i2c.err_code;
   stdout  : constant serial.int.serial_port := serial.int.init(0, 115_200);
   stdin   : constant serial.int.serial_port := serial.int.get_port(0);
   serial1 : constant serial.int.serial_port := serial.int.init(1, 115_200);
   serial2 : constant serial.int.serial_port := serial.int.init(2, 115_200);
   serial3 : constant serial.int.serial_port := serial.int.init(3, 115_200);

begin
   pio.RS485_PIN.config(pio.gpio_output);
   pio.RS485_PIN.set(0);
   serial1.enable_rs485(pio.rs485_pin);
   utils.start_flasher;
   ada.Text_IO.Put_Line("Hello from Ada.Text_IO!");
   stdout.put_line("Hello world from Ada!");
   stdin.rx_enable(True);
   i2c.init(0, i2c.low100);
   i2c.BME280.configure(0, i2c.BME280.addr, err);
   stdout.put_line("BME280 Configuration error code is " & i2c.err_code'Image(err));
   loop
      cli.logon;
      cli.command_loop;
   end loop;
end Main;
