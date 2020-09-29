with BBS.lisp;
package lisp.gpio is
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   --  (set-pin integer integer)
   --    The first integer is the pin number and the second integer is the
   --    pin state.  The pin number is range checked to be between 0 and 53
   --    inclusive and not equal to 4.  The pin state is set to low for a
   --    value of 0 and high otherwise.  Returns NIL.
   function set_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   --  (pin-mode integer integer)
   --    The first integer is the pin number and the second integer is the mode
   --    to set for the pin.  The pin number is range checked as above.  Mode 0
   --    sets the pin to input mode while any other value sets the pin to output
   --    mode.  Returns NIL.
   function read_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --
   --  Set the mode (input or output) of a digital pin.  Two parameters are read.
   --  The first parameter is the pin number (0 .. discretes.max_pin).  The
   --  second is the mode (0 is input, 1 is output).
   --
   --  (read-pin integer)
   --    The integer is the pin number range checked as above.  Returns the state
   --    of the pin.  0 for low and 1 for high.  This may not work for pins set
   --    to output mode.
   function pin_mode(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
end;
