with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.atom_kind;
with BBS.embed.due.serial.int;
with utils;

package body lisp is

   procedure init is
   begin
      BBS.lisp.init(BBS.embed.due.serial.int.Put_Line'Access, BBS.embed.due.serial.int.Put'Access,
                    BBS.embed.due.serial.int.New_Line'Access, BBS.embed.due.serial.int.Get_Line'Access);
      BBS.lisp.add_builtin("due-flash", due_flash'Access);
   end;
   --
   --  Simple lisp function to set the number of times to quickly flash the LED.
   --
   function due_flash(e : BBS.lisp.element_type) return BBS.lisp.element_type is
   begin
      --
      --  If the parameter is an atom, it's easy.  Check if the atom is an
      --  integer and get the value.
      --
      if e.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(e.pa).kind = BBS.lisp.ATOM_INTEGER then
            utils.flash_count := BBS.lisp.atom_table(e.pa).i;
            BBS.lisp.msg("due-flash", "Setting flash count to " &
                           Integer'Image(BBS.lisp.atom_table(e.pa).i));
         else
            BBS.lisp.error("due-flash", "Parameter must be integer.");
         end if;
      else
         BBS.lisp.error("due-flash", "Parameter must be an atom.");
      end if;
      return BBS.lisp.NIL_ELEM;
   end;

end lisp;
