with serial.int;
with SAM3x8e.CHIPID;
package body utils is
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
   --  Print some information about the CPU
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
end utils;
