with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with serial.polled;
with serial.int;
with pio;
with SAM3x8e.CHIPID;

procedure Main is
   count : Integer;
--   c : Character;
   s : String(1 .. 40);
   l : Integer := 0;
   --
   --  Turn the LED on briefly and then turn it off a given number of times.
   --
   Procedure flash_led(times : Integer) is
   begin
      for i in Integer range 1 .. times loop
         pio.set(pio.LED_PIN, 1);
         delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
         pio.set(pio.LED_PIN, 0);
         delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
      end loop;
   end;
   --
   procedure cpu_info is
   begin
      serial.int.put_line(0, "Processor is " &
                               SAM3x8e.CHIPID.CIDR_EPROC_Field'image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.EPROC));
      serial.int.put_line(0, "Version is " &
                               SAM3x8e.CHIPID.CHIPID_CIDR_VERSION_Field'Image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.VERSION));
      serial.int.put_line(0, "NVRAM 1 size is " &
                               SAM3x8e.CHIPID.CIDR_NVPSIZ_Field'Image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.NVPSIZ.Arr(1)));
      serial.int.put_line(0, "NVRAM 2 size is " &
                               SAM3x8e.CHIPID.CIDR_NVPSIZ_Field'Image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.NVPSIZ.Arr(2)));
      serial.int.put_line(0, "RAM size is " &
                               SAM3x8e.CHIPID.CIDR_SRAMSIZ_Field'Image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.SRAMSIZ));
      serial.int.put_line(0, "Architecture is " &
                               SAM3x8e.CHIPID.CIDR_ARCH_Field'Image(SAM3x8e.CHIPID.CHIPID_Periph.CIDR.ARCH));
   end;

begin
   pio.config(pio.LED_PIN, pio.output);
   pio.config(pio.rs485_pin, pio.output);
   serial.init(0, 115_200);
   serial.init(1, 115_200);
   serial.init(2, 115_200);
   serial.init(3, 115_200);
   serial.int.enable_rs485(1, pio.rs485_pin);
   count := 1;
   serial.int.put_line(0, "Hello world from Ada!");
   cpu_info;
   loop
      Serial.int.put("Enter command: ");
      serial.int.rx_enable(0, True);
      serial.int.get_line(0, s, l);
--      c := serial.int.get(0);
      serial.int.rx_enable(0, False);
--      serial.int.put_line(0, "Got character <" & c & ">, value " &
--                            Integer'Image(Character'Pos(c)));
      serial.int.put_line("Got " & Integer'Image(l) & " characters in string.");
      serial.int.put_line("String is <" & s(1..l) & ">");
      if (s(1) = 'f') or (s(1) = 'F') then
         --
         --  Integer'Value() does not seem to be available on this runtime.
         --
         --         count := integer'Value(s(1..l));
         count := Character'Pos(s(2)) - Character'Pos('0');
      end if;
      serial.int.put_line(0, "Flashing LED " & Integer'Image(count) & " times.");
--      serial.int.put_line(1, "Hello 1 from Ada.");
--      serial.int.put_line(2, "Hello 2 from Ada.");
--      serial.int.put_line(3, "Hello 3 from Ada.");
      flash_led(count);
      count := count + 1;
      if count > 4 then
         count := 1;
      end if;
--      delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.5);
   end loop;
end Main;
