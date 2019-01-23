package body pio is
   --
   procedure config(pin : digital_pin_rec_access; dir : direction) is
   begin
      pin.ctrl.PER.Arr(pin.bit) := 1;
      if dir = output then
         pin.ctrl.OER.Arr(pin.bit) := 1;
      else
         pin.ctrl.ODR.Arr(pin.bit) := 1;
      end if;
   end;
   --
   procedure set(pin : digital_pin_rec_access; val : SAM3x8e.Bit) is
   begin
      if val = 1 then
         pin.ctrl.SODR.Arr(pin.bit) := 1;
      else
         pin.ctrl.CODR.Arr(pin.bit) := 1;
      end if;
   end;
   --
   function get(pin : digital_pin_rec_access) return SAM3x8e.Bit is
   begin
      return pin.ctrl.PDSR.Arr(pin.bit);
   end;
   --
end pio;
