with Ada.Real_Time;
use type Ada.Real_Time.Time;
with BBS.embed.GPIO.Due;
with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
with BBS.lisp.evaluate;
with discretes;
package body lisp.stepper is
   --
   --  (stepper-init num a b c d)
   --    Initializes stepper controller num and sets the pin numbers for pins a,
   --    b, c, and d.  Phase is set to 1 and the pins are set appropriately.
   --
   function stepper_init(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      pin_elem : BBS.lisp.element_type;
      stepper_elem  : BBS.lisp.element_type;
      stepper : Integer;
      pin_a : Integer;
      pin_b : Integer;
      pin_c : Integer;
      pin_d : Integer;
      ok : Boolean := True;
   begin
      --
      --  Check if the stepper number value is an integer element.
      --
      stepper_elem := BBS.lisp.evaluate.first_value(rest);
      if stepper_elem.kind = BBS.lisp.E_VALUE then
         if stepper_elem.v.kind = BBS.lisp.V_INTEGER then
            stepper := Integer(stepper_elem.v.i);
         else
            BBS.lisp.error("stepper-init", "Stepper number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-init", "Stepper number must be an element.");
         ok := False;
      end if;
      --
      --  Check if pin a is an integer element.
      --
      pin_elem := BBS.lisp.evaluate.first_value(rest);
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin_a := Integer(pin_elem.v.i);
         else
            BBS.lisp.error("stepper-init", "Pin-a number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-init", "Pin-a number must be an element.");
         ok := False;
      end if;
      --
      --  Check if pin b is an integer element.
      --
      pin_elem := BBS.lisp.evaluate.first_value(rest);
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin_b := Integer(pin_elem.v.i);
         else
            BBS.lisp.error("stepper-init", "Pin-b number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-init", "Pin-b number must be an element.");
         ok := False;
      end if;
      --
      --  Check if pin c is an integer element.
      --
      pin_elem := BBS.lisp.evaluate.first_value(rest);
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin_c := Integer(pin_elem.v.i);
         else
            BBS.lisp.error("stepper-init", "Pin-c number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-init", "Pin-c number must be an element.");
         ok := False;
      end if;
      --
      --  Check if pin d is an integer element.
      --
      pin_elem := BBS.lisp.evaluate.first_value(rest);
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin_d := Integer(pin_elem.v.i);
         else
            BBS.lisp.error("stepper-init", "Pin-d number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-init", "Pin-d number must be an element.");
         ok := False;
      end if;
      --
      --  Now range check the values
      --
      if stepper < 1 or stepper > num_steppers then
         BBS.lisp.error("stepper-init", "Stepper number out of range.");
         ok := False;
      end if;
      --
      --  Check if pin numbers are within range of the valid pins.  Note that
      --  pin 4 cannot be used.
      --
      if (pin_a < 0) or (pin_a > discretes.max_pin) or (pin_a = 4) then
         BBS.lisp.error("stepper-init", "Pin-a is out of range.");
         ok := False;
      end if;
      if (pin_b < 0) or (pin_b > discretes.max_pin) or (pin_b = 4) then
         BBS.lisp.error("stepper-init", "Pin-b is out of range.");
         ok := False;
      end if;
      if (pin_c < 0) or (pin_c > discretes.max_pin) or (pin_c = 4) then
         BBS.lisp.error("stepper-init", "Pin-c is out of range.");
         ok := False;
      end if;
      if (pin_d < 0) or (pin_d > discretes.max_pin) or (pin_d = 4) then
         BBS.lisp.error("stepper-init", "Pin-d is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then setup the stepper
      --
      if ok then
         steppers(stepper).pin_a := pin_a;
         steppers(stepper).pin_b := pin_b;
         steppers(stepper).pin_c := pin_c;
         steppers(stepper).pin_d := pin_d;
         steppers(stepper).phase := 1;
         steppers(stepper).initialized := True;
         discretes.pin(pin_a).all.config(BBS.embed.GPIO.Due.gpio_output);
         discretes.pin(pin_b).all.config(BBS.embed.GPIO.Due.gpio_output);
         discretes.pin(pin_c).all.config(BBS.embed.GPIO.Due.gpio_output);
         discretes.pin(pin_d).all.config(BBS.embed.GPIO.Due.gpio_output);
         discretes.pin(pin_a).all.set(step_phase(1, 1));
         discretes.pin(pin_b).all.set(step_phase(1, 2));
         discretes.pin(pin_c).all.set(step_phase(1, 3));
         discretes.pin(pin_d).all.set(step_phase(1, 4));
      else
         return (kind => BBS.lisp.E_ERROR);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  (stepper-delay num delay)
   --    Set the delay between steps for the specified stepper to the specified
   --    number of milliseconds.  The default is 5mS.
   --
   function stepper_delay(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      delay_elem : BBS.lisp.element_type;
      stepper_elem  : BBS.lisp.element_type;
      stepper : Integer;
      delay_time : Integer;
      ok : Boolean := True;
   begin
      --
      --  Check if the stepper number value is an integer element.
      --
      stepper_elem := BBS.lisp.evaluate.first_value(rest);
      if stepper_elem.kind = BBS.lisp.E_VALUE then
         if stepper_elem.v.kind = BBS.lisp.V_INTEGER then
            stepper := Integer(stepper_elem.v.i);
         else
            BBS.lisp.error("stepper-delay", "Stepper number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-delay", "Stepper number must be an element.");
         ok := False;
      end if;
      --
      --  Check if delay time is an integer element.
      --
      delay_elem := BBS.lisp.evaluate.first_value(rest);
      if delay_elem.kind = BBS.lisp.E_VALUE then
         if delay_elem.v.kind = BBS.lisp.V_INTEGER then
            delay_time := Integer(delay_elem.v.i);
         else
            BBS.lisp.error("stepper-delay", "Delay time must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("stepper-delay", "Delay time must be an element.");
         ok := False;
      end if;
      if delay_time < 0 then
         BBS.lisp.error("stepper-delay", "Delay time must be zero or greater.");
         ok := False;
      end if;
      if ok then
         steppers(stepper).time := delay_time;
      else
         return (kind => BBS.lisp.E_ERROR);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;

   --
   --  (step num amount)
   --    Moves the specified stepper motor the specified number of steps.
   --    Direction is indicated by the sign.  The actual direction depends on
   --    the wiring.
   --
   function stepper_step(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      amount_elem : BBS.lisp.element_type;
      stepper_elem  : BBS.lisp.element_type;
      stepper : Integer;
      amount : Integer;
      ok : Boolean := True;
   begin
      --
      --  Check if the stepper number value is an integer element.
      --
      stepper_elem := BBS.lisp.evaluate.first_value(rest);
      if stepper_elem.kind = BBS.lisp.E_VALUE then
         if stepper_elem.v.kind = BBS.lisp.V_INTEGER then
            stepper := Integer(stepper_elem.v.i);
         else
            BBS.lisp.error("step", "Stepper number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("step", "Stepper number must be an element.");
         ok := False;
      end if;
      --
      --  Check if step amount is an integer element.
      --
      amount_elem := BBS.lisp.evaluate.first_value(rest);
      if amount_elem.kind = BBS.lisp.E_VALUE then
         if amount_elem.v.kind = BBS.lisp.V_INTEGER then
            amount := Integer(amount_elem.v.i);
         else
            BBS.lisp.error("step", "Amount must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("step", "Amount must be an element.");
         ok := False;
      end if;
      --
      --  If everything is OK, do the stepping.
      --
      if ok then
         --
         --  Check for stepping one way or the other.  Zero steps does nothing.
         --
         if amount > 0 then
            for step in 1 .. amount loop
               if steppers(stepper).phase = 8 then
                  steppers(stepper).phase := 1;
               else
                  steppers(stepper).phase := steppers(stepper).phase + 1;
               end if;
--               BBs.lisp.error("step", "Stepping up to phase " & Integer'Image(steppers(stepper).phase) &
--                                ", A =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 1))) &
--                                ", B =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 2))) &
--                                ", C =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 3))) &
--                                ", D =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 4))));
               discretes.pin(steppers(stepper).pin_a).all.set(step_phase(steppers(stepper).phase, 1));
               discretes.pin(steppers(stepper).pin_b).all.set(step_phase(steppers(stepper).phase, 2));
               discretes.pin(steppers(stepper).pin_c).all.set(step_phase(steppers(stepper).phase, 3));
               discretes.pin(steppers(stepper).pin_d).all.set(step_phase(steppers(stepper).phase, 4));
               delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(Duration(steppers(stepper).time)/1000.0);
            end loop;
         elsif amount < 0 then
            for step in 1 .. -amount loop
               if steppers(stepper).phase = 1 then
                  steppers(stepper).phase := 8;
               else
                  steppers(stepper).phase := steppers(stepper).phase - 1;
               end if;
--               BBs.lisp.error("step", "Stepping down to phase " & Integer'Image(steppers(stepper).phase) &
--                                ", A =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 1))) &
--                                ", B =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 2))) &
--                                ", C =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 3))) &
--                                ", D =" & Integer'Image(Integer(step_phase(steppers(stepper).phase, 4))));
               discretes.pin(steppers(stepper).pin_a).all.set(step_phase(steppers(stepper).phase, 1));
               discretes.pin(steppers(stepper).pin_b).all.set(step_phase(steppers(stepper).phase, 2));
               discretes.pin(steppers(stepper).pin_c).all.set(step_phase(steppers(stepper).phase, 3));
               discretes.pin(steppers(stepper).pin_d).all.set(step_phase(steppers(stepper).phase, 4));
               delay until Ada.Real_Time.Clock + Ada.Real_Time.To_Time_Span(Duration(steppers(stepper).time)/1000.0);
            end loop;
         end if;
      else
         return (kind => BBS.lisp.E_ERROR);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  (stepper-off num)
   --    Turns the coils for the specified stepper off..
   --
   function stepper_off(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      stepper_elem  : BBS.lisp.element_type;
      stepper : Integer;
      ok : Boolean := True;
   begin
      --
      --  Check if the stepper number value is an integer element.
      --
      stepper_elem := BBS.lisp.evaluate.first_value(rest);
      if stepper_elem.kind = BBS.lisp.E_VALUE then
         if stepper_elem.v.kind = BBS.lisp.V_INTEGER then
            stepper := Integer(stepper_elem.v.i);
         else
            BBS.lisp.error("step", "Stepper number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("step", "Stepper number must be an element.");
         ok := False;
      end if;
      if ok then
         discretes.pin(steppers(stepper).pin_a).all.set(0);
         discretes.pin(steppers(stepper).pin_b).all.set(0);
         discretes.pin(steppers(stepper).pin_c).all.set(0);
         discretes.pin(steppers(stepper).pin_d).all.set(0);
      else
         return (kind => BBS.lisp.E_ERROR);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
end;
