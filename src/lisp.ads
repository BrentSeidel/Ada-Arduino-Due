with BBS.lisp;
package lisp is

   procedure init;

private
   --
   --  Functions for custom lisp operations for the Arduino Due
   --
   --  Currently defined lisp operations are:
   --
   function due_flash(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   --  (due-flash integer)
   --    Sets the flash count for the LED flashing task.  A simple, proof-of-
   --    concept lisp operation.  Returns NIL.
   --
   --
   --  Read the value of one of the analog inputs.
   --
   function read_analog(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   --  (read-analog integer)
   --    The integer is the pin number range checked to the subtype
   --    BBS.embed.ain.due.AIN_Num.  Returns the analog value of the pin.
   --
   --
   --  Sets the value of one of the analog outputs.
   --
   function set_analog(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   --  (set-analog integer integer)
   --    The first integer is the pin number range checked to 0 or 1.  The second
   --    integer is the value to write to the output, range limited to 0-4095.
   --    Returns NIL.
   --
   function info_enable(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   function info_disable(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   --
   --  (info-enable) and (info-disable)
   --    Enable or disable the display of info messages.  Both return NIL.
   --
end lisp;
