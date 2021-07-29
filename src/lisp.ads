with BBS.lisp;
use type BBS.lisp.value_type;
package lisp is
   procedure init;
   --
   --  (due-flash integer)
   --    Sets the flash count for the LED flashing task.  A simple, proof-of-
   --    concept lisp operation.  Returns NIL.
   procedure due_flash(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index);
   --
   --
   --  (info-enable) and (info-disable)
   --    Enable or disable the display of info messages.  Both return NIL.
   procedure info_enable(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index);
   procedure info_disable(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index);
   --
end;
