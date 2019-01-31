with serial.int;
with SAM3x8e.CHIPID;
package body utils is
   --
   --  Task to flash the LED.
   --
   task body flasher is
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(enable_flasher);
      pio.config(pio.LED_PIN, pio.output);
      loop
         for i in Integer range 1 .. flash_count loop
            pio.set(pio.LED_PIN, 1);
            delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
            pio.set(pio.LED_PIN, 0);
            delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
         end loop;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.5);
      end loop;
   end flasher;
   --
   procedure start_flasher is
   begin
      Ada.Synchronous_Task_Control.Set_True(enable_flasher);
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
