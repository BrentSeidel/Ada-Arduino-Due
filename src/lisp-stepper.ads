--
--  This package contains code for the lisp interpreter to run stepper motors.
--
with BBS.embed;
with BBS.lisp;
package lisp.stepper is

   --
   --  Data for stepper motors.  Each stepper motor is controlled by 4 digital
   --  I/O pins.  I currently have 4 controllers and motors, so I've set
   --  num_steppers to 4.  Change if you have more, or less.
   --
   num_steppers : constant Integer := 4;
   type stepper_rec is record
      initialized : Boolean := False;
      pin_a : Integer;
      pin_b : Integer;
      pin_c : Integer;
      pin_d : Integer;
      phase : Integer;
      time  : Integer := 5;
   end record;
   steppers : array (1 .. num_steppers) of stepper_rec;
   --
   --  (stepper-init num a b c d)
   --    Initializes stepper controller num and sets the pin numbers for pins a,
   --    b, c, and d.  Phase is set to 1 and the pins are set appropriately.
   --
   function stepper_init(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  (stepper-delay num delay)
   --    Set the delay between steps for the specified stepper to the specified
   --    number of milliseconds.  The default is 5mS.
   --
   function stepper_delay(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  (step num amount)
   --    Moves the specified stepper motor the specified number of steps.
   --    Direction is indicated by the sign.  The actual direction depends on
   --    the wiring.
   --
   function stepper_step(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  (stepper-off num)
   --    Turns the coils for the specified stepper off..
   --
   function stepper_off(e : BBS.lisp.element_type) return BBS.lisp.element_type;

private
   step_phase : constant array (1 .. 8, 1 .. 4) of BBS.embed.bit :=
     ((1, 0, 1, 0),  --  1. +A +B
      (1, 0, 0, 0),  --  2. +A 0B
      (1, 0, 0, 1),  --  3. +A -B
      (0, 0, 0, 1),  --  4. 0A -B
      (0, 1, 0, 1),  --  5. -A -B
      (0, 1, 0, 0),  --  6. -A 0B
      (0, 1, 1, 0),  --  7. -A +B
      (0, 0, 1, 0)); --  8. 0A +B
--     ((1, 0, 1, 0),  --  +A +B
--      (1, 0, 0, 0),  --  +A 0B
--      (1, 0, 0, 1),  --  +A -B
--      (0, 0, 0, 1),  --  0A -B
--      (0, 1, 0, 1),  --  -A -B
--      (0, 1, 0, 0),  --  -A 0B
--      (0, 1, 1, 0),  --  -A +B
--      (0, 0, 1, 0)); --  0A +B
--     ((1, 0, 0, 1),  --  +A -B
--      (1, 0, 0, 0),  --  +A 0B
--      (1, 1, 0, 0),  --  0A 0B
--      (0, 1, 0, 0),  --  -A 0B
--      (0, 1, 1, 0),  --  -A +B
--      (0, 0, 1, 0),  --  0A +B
--      (0, 0, 1, 1),  --  0A 0B
--      (0, 0, 0, 1)); --  0A -B
end;
