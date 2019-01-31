with Ada.Text_IO;
with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with serial.polled;
with serial.int;
with pio;
with utils;
with i2c;
with i2c.BME280;
with SAM3x8e;

procedure Main is
--   c : Character;
   s : String(1 .. 40);
   l : Integer := 0;
   --   data : SAM3x8e.Byte;
   flag : Boolean;
   err  : i2c.err_code;

begin
   pio.config(pio.rs485_pin, pio.output);
   serial.init(0, 115_200);
   serial.init(1, 115_200);
   serial.init(2, 115_200);
   serial.init(3, 115_200);
   serial.int.enable_rs485(1, pio.rs485_pin);
   utils.start_flasher;
   ada.Text_IO.Put_Line("Hello from Ada.Text_IO!");
   serial.int.put_line(0, "Hello world from Ada!");
   utils.cpu_info;
   serial.int.rx_enable(0, True);
   i2c.init(0, i2c.low100);
   i2c.BME280.configure(0, i2c.BME280.addr, err);
      serial.int.put_line(0, "BME280 Configuration error code is " & i2c.err_code'Image(err));
   loop
      Serial.int.put("Enter command: ");
      serial.int.get_line(0, s, l);
      i2c.BME280.start_conversion(err);
--      c := serial.int.get(0);
--      serial.int.rx_enable(0, False);
--      serial.int.put_line(0, "Got character <" & c & ">, value " &
--                            Integer'Image(Character'Pos(c)));
      serial.int.put_line("Got " & Integer'Image(l) & " characters in string.");
      serial.int.put_line("String is <" & s(1..l) & ">");
      if (s(1) = 'f') or (s(1) = 'F') then
         --
         --  Integer'Value() does not seem to be available on this runtime.
         --
         utils.flash_count := integer'Value(s(2..l));
      end if;
      if s(1..4) = "exit" then
         serial.int.put_line("There is nowhere to exit to.  This is it.");
      end if;
      loop
         flag := i2c.BME280.data_ready(err);
         exit when flag;
      end loop;
      i2c.BME280.read_data(err);
      serial.int.put_line("Temperature is " & Integer'Image(i2c.BME280.get_temp/100));
      serial.int.put_line("Pressure is " & Integer'Image(i2c.BME280.get_press/256));
      serial.int.put_line("Humidity is " & Integer'Image(i2c.BME280.get_hum/1024));
--      serial.int.put_line(0, "Flashing LED " & Integer'Image(count) & " times.");
--      serial.int.put_line(1, "Hello 1 from Ada.");
--      serial.int.put_line(2, "Hello 2 from Ada.");
--      serial.int.put_line(3, "Hello 3 from Ada.");
   end loop;
end Main;
