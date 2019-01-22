with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with serial.polled;
with serial.int;
with pio;
with pins;
with SAM3x8e.CHIPID;
--
--  This is a simple Ada program to flash the LED on an Arduino Due.  Its
--  primary purpose is to test the tool chain to ensure that a binary can
--  be built and loaded.
--

--
--  From the Arduino Due schematic, it appears that the LED is a yellow LED
--  attached to microcontroller pin PB27.  This is parallel I/O controller B,
--  bit 27.
--
procedure Main is
   count : Integer;
   --
   --  Turn the LED on briefly and then turn it off a given number of times.
   --
   Procedure flash_led(times : Integer) is
   begin
      for i in Integer range 1 .. times loop
         pio.set(pins.LED_PIN);
         delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
         pio.clear(pins.LED_PIN);
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
   pio.config_out(pins.LED_PIN);
   serial.init(0, 115_200);
   serial.init(3, 115_200);
   count := 1;
   serial.int.put_line(0, "Hello world from Ada!");
   cpu_info;
   loop
      serial.int.put_line(0, "Flashing LED " & Integer'Image(count) & " times.");
      serial.int.put_line(3, "Hello from Ada.");
      flash_led(count);
      count := count + 1;
      if count > 4 then
         count := 1;
      end if;
      delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(1.0);
   end loop;
end Main;
