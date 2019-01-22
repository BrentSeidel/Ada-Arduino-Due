package body pio is
   procedure config_out(port : in out SAM3x8e.PIO.PIO_Peripheral; pin : Integer) is
   begin
      port.PER.Arr(pin) := 1;
      port.OER.Arr(pin) := 1;
   end;
   --
   procedure config_out(pin : pins.digital_pin_rec) is
   begin
      pin.ctrl.PER.Arr(pin.bit) := 1;
      pin.ctrl.OER.Arr(pin.bit) := 1;
   end;
   --
   procedure set(pin : pins.digital_pin_rec) is
   begin
      pin.ctrl.SODR.Arr(pin.bit) := 1;
   end;
   --
   procedure clear(pin : pins.digital_pin_rec) is
   begin
      pin.ctrl.CODR.Arr(pin.bit) := 1;
   end;
end pio;
