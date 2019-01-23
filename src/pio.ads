with SAM3x8e;
use type SAM3x8e.Bit;
with SAM3x8e.PIO;
--
--  This package contains definitions and routines for the PIO controllers.  It
--  also has functions for setting and getting pin values.
--
package pio is
   type direction is (input, output);
   --
   --  Access type to controller address
   --
   type pio_access is access all SAM3x8e.PIO.PIO_Peripheral;
   --
   --  Record containing information to translate pin number to actual I/O
   --  signals.
   --
   type digital_pin_rec is record
      ctrl : pio_access;
      bit  : Integer range 0 .. 31;
   end record;

   --
   --  Configures a pin to be controlled by the PIO controller.  Output is
   --  enabled or disabled based on the value of dir.
   --
   procedure config(pin : digital_pin_rec; dir : direction);

   --
   --  Set a pin to a high or low value.
   --
   procedure set(pin : digital_pin_rec; val : SAM3x8e.Bit);
   --
   --  Read the value of a pin regardless of what is controlling it
   --
   function get(pin : digital_pin_rec) return SAM3x8e.Bit;

   --  Parallel Input/Output Controller A
   PIOA : aliased SAM3x8e.PIO.PIO_Peripheral
     with Import, Address => SAM3x8e.PIOA_Base;

   --  Parallel Input/Output Controller B
   PIOB : aliased SAM3x8e.PIO.PIO_Peripheral
     with Import, Address => SAM3x8e.PIOB_Base;

   --  Parallel Input/Output Controller C
   PIOC : aliased SAM3x8e.PIO.PIO_Peripheral
     with Import, Address => SAM3x8e.PIOC_Base;

   --  Parallel Input/Output Controller D
   PIOD : aliased SAM3x8e.PIO.PIO_Peripheral
     with Import, Address => SAM3x8e.PIOD_Base;

   LED_PIN : constant digital_pin_rec := (ctrl => SAM3x8e.PIO.PIOB_Periph'Access,
                                          bit => 27);

end pio;
