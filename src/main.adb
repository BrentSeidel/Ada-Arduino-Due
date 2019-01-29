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
   count : Integer := 1;
--   c : Character;
   s : String(1 .. 40);
   l : Integer := 0;
   data : SAM3x8e.Byte;
   err  : i2c.err_code;

begin
   pio.config(pio.LED_PIN, pio.output);
   pio.config(pio.rs485_pin, pio.output);
   serial.init(0, 115_200);
   serial.init(1, 115_200);
   serial.init(2, 115_200);
   serial.init(3, 115_200);
   serial.int.enable_rs485(1, pio.rs485_pin);
   ada.Text_IO.Put_Line("Hello from Ada.Text_IO!");
   serial.int.put_line(0, "Hello world from Ada!");
   utils.cpu_info;
   serial.int.rx_enable(0, True);
   i2c.init(0, i2c.low100);
   loop
      Serial.int.put("Enter command: ");
      serial.int.get_line(0, s, l);
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
         count := integer'Value(s(2..l));
--         count := Character'Pos(s(2)) - Character'Pos('0');
      end if;
      if s(1..4) = "exit" then
         serial.int.put_line("There is nowhere to exit to.  This is it.");
         count := 1;
      end if;
      data := i2c.read(i2c.BME280.addr, i2c.BME280.id, err);
      --
      --  ID should be 16#60#.  Use to see if things are working.
      --
      serial.int.put_line(0, "Got BME280 ID of " & Integer'Image(Integer(data)));
      serial.int.put_line(0, "  Error code is " & i2c.err_code'Image(err));
      serial.int.put_line(0, "Flashing LED " & Integer'Image(count) & " times.");
--      serial.int.put_line(1, "Hello 1 from Ada.");
--      serial.int.put_line(2, "Hello 2 from Ada.");
--      serial.int.put_line(3, "Hello 3 from Ada.");
      utils.flash_led(count);
      count := count + 1;
      if count > 4 then
         count := 1;
      end if;
--      delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.5);
   end loop;
end Main;
