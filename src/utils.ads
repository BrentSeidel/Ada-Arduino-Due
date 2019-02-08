with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with Ada.Synchronous_Task_Control;
with Ada.Unchecked_Conversion;
with pio;
with SAM3x8e;
use type SAM3x8e.UInt16;
--
--  This package contains a random collection of utility functions used when
--  exploring the Arduino Due.
--
package utils is
   --
   --  Task to flash the LED.
   --
   flash_count : Integer := 2;
   task flasher;
   procedure start_flasher;
   --
   --  Print some information about the CPU
   --
   procedure cpu_info;
   --
   --  Definitions for bounded strings - to be moved to a separate package
   --
   type bounded(max : Integer) is record
      len : Integer;
      str : String(1 .. max);
   end record;
   --
   --  Some string functions
   --
   --
   --  Convert string to uppercase
   --
   procedure uppercase(s : in out String);
   --
   --  See if a string starts with another string.  's' is the sample string,
   --  'l' is the number of characters in the sample, 'test' is typically a
   --  constant string to see if 's' starts with it.
   --
   function starts_with(s : String; l : Integer; test : String) return Boolean;

   --
   -- A couple of unchecked conversions to convert unsigned into signed values.
   --
   function uint8_to_int8 is
     new Ada.Unchecked_Conversion(source => SAM3x8e.Byte, target => SAM3x8e.int8);
   function uint12_to_int12 is
     new Ada.Unchecked_Conversion(source => SAM3x8e.uint12, target => SAM3x8e.int12);
   function uint16_to_int16 is
     new Ada.Unchecked_Conversion(source => SAM3x8e.uint16, target => SAM3x8e.int16);
   --
   -- Get the high and low bytes (Byte) of a 16 bit uint
   --
   function highByte(x : SAM3x8e.uint16) return SAM3x8e.Byte is
     (SAM3x8e.Byte(x / 2**8));
   function lowByte(x : SAM3x8e.uint16) return SAM3x8e.Byte is
     (SAM3x8e.Byte(x and 16#FF#));
   --
private
   enable_flasher : Ada.Synchronous_Task_Control.Suspension_Object;

end utils;
