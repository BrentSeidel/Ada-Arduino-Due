with serial.int;
with SAM3x8e.CHIPID;
package body utils is
   --
   --  Task to flash the LED.
   --
   task body flasher is
      led : constant pio.gpio_ptr := pio.led_pin_obj'Access;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(enable_flasher);
      led.config(pio.gpio_output);
      loop
         for i in Integer range 1 .. flash_count loop
            led.set(1);
            delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
            led.set(0);
            delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.1);
         end loop;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(0.5);
         if not run_flasher then
            Ada.Synchronous_Task_Control.Suspend_Until_True(enable_flasher);
         end if;
      end loop;
   end flasher;
   --
   procedure ctrl_flasher(s : Boolean) is
   begin
      if s then
         Ada.Synchronous_Task_Control.Set_True(enable_flasher);
         run_flasher := True;
      else
         Ada.Synchronous_Task_Control.Set_False(enable_flasher);
         run_flasher := False;
      end if;
   end;
   --
   function state_flasher return Boolean is (run_flasher);
   --
   --  Task to toggle pin 23.
   --
   task body toggle is
      pin : constant pio.gpio_ptr := pio.pin23;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(enable_toggle);
      pin.config(pio.gpio_output);
      loop
         pin.set(1);
         pin.set(0);
         if not run_toggle then
            Ada.Synchronous_Task_Control.Suspend_Until_True(enable_toggle);
         end if;
      end loop;
   end toggle;
   --
   procedure ctrl_toggle(s : Boolean) is
   begin
      if s then
         Ada.Synchronous_Task_Control.Set_True(enable_toggle);
         run_toggle := True;
      else
         Ada.Synchronous_Task_Control.Set_False(enable_toggle);
         run_toggle := False;
      end if;
   end;
   --
   function state_toggle return Boolean is (run_toggle);
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
   --
   --  Decode the I2C status register
   --
   procedure print_i2c_sr(s : SAM3x8e.TWI.TWI0_SR_Register) is
      stdout : serial.int.serial_port := serial.int.get_port(0);
      flag   : Boolean := False;
   begin
      if s.TXCOMP = 1 then
         stdout.put("TXCOMP ");
         flag := True;
      end if;
      if s.RXRDY = 1 then
         stdout.put("RXRDY ");
         flag := True;
      end if;
      if s.TXRDY = 1 then
         stdout.put("TXDRY ");
         flag := True;
      end if;
      if s.SVREAD = 1 then
         stdout.put("SVREAD ");
      end if;
      if s.SVACC = 1 then
         stdout.put("SVACC ");
      end if;
      if s.GACC = 1 then
         stdout.put("GACC ");
      end if;
      if s.OVRE = 1 then
         stdout.put("OVRE ");
      end if;
      if s.NACK = 1 then
         stdout.put("NACK ");
      end if;
      if s.ARBLST = 1 then
         stdout.put("ARBLST ");
      end if;
      if s.SCLWS = 1 then
         stdout.put("SCLWS ");
      end if;
      if s.EOSACC = 1 then
         stdout.put("EOSACC ");
      end if;
      if s.ENDRX = 1 then
         stdout.put("ENDRX ");
      end if;
      if s.ENDTX = 1 then
         stdout.put("ENDTX ");
      end if;
      if s.RXBUFF = 1 then
         stdout.put("RXBUFF ");
      end if;
      if s.TXBUFE = 1 then
         stdout.put("TXBUFE");
      end if;
      if flag then
         stdout.new_line;
      end if;
   end;
   --
   --  Hex conversion routines
   --
   function hex_to_char(v : SAM3x8e.UInt4) return Character is
   begin
      case v is
         when 0 =>
            return '0';
         when 1 =>
            return '1';
         when 2 =>
            return '2';
         when 3 =>
            return '3';
         when 4 =>
            return '4';
         when 5 =>
            return '5';
         when 6 =>
            return '6';
         when 7 =>
            return '7';
         when 8 =>
            return '8';
         when 9 =>
            return '9';
         when 10 =>
            return 'A';
         when 11 =>
            return 'B';
         when 12 =>
            return 'C';
         when 13 =>
            return 'D';
         when 14 =>
            return 'E';
         when 15 =>
            return 'F';
      end case;
   end;
   --
   function byte_to_str(v : SAM3x8e.Byte) return String is
   begin
      return hex_to_char(SAM3x8e.UInt4((v/16) and 16#f#)) &
        hex_to_char(SAM3x8e.UInt4(v and 16#f#));
   end;
   --
   function byte_to_str(v : BBS.embed.uint8) return String is
   begin
      return hex_to_char(SAM3x8e.UInt4((v/16) and 16#f#)) &
        hex_to_char(SAM3x8e.UInt4(v and 16#f#));
   end;
end utils;
