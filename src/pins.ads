with SAM3x8e;
with SAM3x8e.PIO;
package pins is
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

   LED_PIN : constant digital_pin_rec := (ctrl => SAM3x8e.PIO.PIOB_Periph'Access,
                                          bit => 27);
end pins;
