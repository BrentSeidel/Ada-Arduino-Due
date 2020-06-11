with BBS.lisp;
package lisp is

   procedure init;

private
   --
   --  Functions for custom lisp operations for the Arduino Due
   --
   --  Currently defined lisp operations are:
   --
   function due_flash(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (due-flash integer)
   --    Sets the flash count for the LED flashing task.  A simple, proof-of-
   --    concept lisp operation.  Returns NIL.
   --
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function set_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (set-pin integer integer)
   --    The first integer is the pin number and the second integer is the
   --    pin state.  The pin number is range checked to be between 0 and 53
   --    inclusive and not equal to 4.  The pin state is set to low for a
   --    value of 0 and high otherwise.  Returns NIL.
   --
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function read_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (pin-mode integer integer)
   --    The first integer is the pin number and the second integer is the mode
   --    to set for the pin.  The pin number is range checked as above.  Mode 0
   --    sets the pin to input mode while any other value sets the pin to output
   --    mode.  Returns NIL.
   --
   --
   --  Set the mode (input or output) of a digital pin.  Two parameters are read.
   --  The first parameter is the pin number (0 .. discretes.max_pin).  The
   --  second is the mode (0 is input, 1 is output).
   --
   function pin_mode(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (read-pin integer)
   --    The integer is the pin number range checked as above.  Returns the state
   --    of the pin.  0 for low and 1 for high.  This may not work for pins set
   --    to output mode.
   --
   --
   --  Read the value of one of the analog inputs.
   --
   function read_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (read-analog integer)
   --    The integer is the pin number range checked to the subtype
   --    BBS.embed.ain.due.AIN_Num.  Returns the analog value of the pin.
   --
   --
   --  Sets the value of one of the analog outputs.
   --
   function set_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --  (set-analog integer integer)
   --    The first integer is the pin number range checked to 0 or 1.  The second
   --    integer is the value to write to the output, range limited to 0-4095.
   --    Returns NIL.
   --
   function info_enable(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   function info_disable(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  (info-enable) and (info-disable)
   --    Enable or disable the display of info messages.  Both return NIL.
   --
   function read_bmp180(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  (read-bmp180)
   --    Reads the ambient temperature in degrees C and atmospheric pressure  in
   --    Pascals from the BMP180 sensor.
end lisp;
