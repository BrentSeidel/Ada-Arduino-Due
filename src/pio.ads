with SAM3x8e;
with SAM3x8e.PIO;
with pins;

package pio is
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

   procedure config_out(port : in out SAM3x8e.PIO.PIO_Peripheral; pin : Integer);
   procedure config_out(pin : pins.digital_pin_rec);
   procedure set(pin : pins.digital_pin_rec);
   procedure clear(pin : pins.digital_pin_rec);
end pio;
