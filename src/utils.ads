with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with pio;
--
--  This package contains a random collection of utility functions used when
--  exploring the Arduino Due.
--
package utils is
   --
   --  Turn the LED on briefly and then turn it off a given number of times.
   --
   Procedure flash_led(times : Integer);
   --
   --  Print some information about the CPU
   --
   procedure cpu_info;
end utils;
