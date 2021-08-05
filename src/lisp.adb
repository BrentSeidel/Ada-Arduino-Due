with Utils;
with BBS.lisp.evaluate;
package body lisp is
   --
   --  Initialize the lisp interpreter and install custom lisp commands
   --
   --
   procedure init is
   begin
      BBS.lisp.add_builtin("due-flash", due_flash'Access);
      BBS.lisp.add_builtin("info-enable", info_enable'Access);
      BBS.lisp.add_builtin("info-disable", info_disable'Access);
   end;
   --
   --
   --  Simple lisp function to set the number of times to quickly flash the LED.
   --
   procedure due_flash(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index) is
      param : BBS.lisp.element_type;
      rest : BBS.lisp.cons_index := s;
   begin
      --
      --  Get the first value
      --
      param := BBS.lisp.evaluate.first_value(rest);
      --
      --  Check if the first value is an integer element.
      --
      if param.kind = BBS.lisp.V_INTEGER then
         utils.flash_count := Integer(param.i);
      else
         BBS.lisp.error("due-flash", "Parameter must be integer.");
         e := BBS.lisp.make_error(BBS.lisp.ERR_WRONGTYPE);
         return;
      end if;
   end;
   --
   --  Enable display of info messages
   --
   procedure info_enable(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index) is
      pragma Unreferenced (s);
   begin
      utils.info.enable;
      e := BBS.lisp.NIL_ELEM;
   end;
   --
   --  Disable display of info messages
   --
   procedure info_disable(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index) is
      pragma Unreferenced (s);
   begin
      utils.info.disable;
      e := BBS.lisp.NIL_ELEM;
   end;
   --
end;
