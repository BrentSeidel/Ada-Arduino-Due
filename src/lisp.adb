with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.atom_kind;
with BBS.lisp.utilities;
with BBS.lisp.memory;
with BBS.embed;
with BBS.embed.due.serial.int;
with BBS.embed.GPIO.Due;
with BBS.embed.ain.due;
with utils;
with discretes;

package body lisp is
   --
   --  Initialize the lisp interpreter and install custom lisp commands
   procedure init is
   begin
      BBS.lisp.init(BBS.embed.due.serial.int.Put_Line'Access, BBS.embed.due.serial.int.Put'Access,
                    BBS.embed.due.serial.int.New_Line'Access, BBS.embed.due.serial.int.Get_Line'Access);
      BBS.lisp.add_builtin("due-flash", due_flash'Access);
      BBS.lisp.add_builtin("set-pin", set_pin'Access);
      BBS.lisp.add_builtin("pin-mode", pin_mode'Access);
      BBS.lisp.add_builtin("read-pin", read_pin'Access);
      BBS.lisp.add_builtin("read-analog", read_analog'Access);
   end;
   --
   --  Functions for custom lisp commands for the Arduino Due
   --
   --
   --  Simple lisp function to set the number of times to quickly flash the LED.
   --
   function due_flash(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      rest : BBS.lisp.element_type;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(param.pa).kind = BBS.lisp.ATOM_INTEGER then
            utils.flash_count := BBS.lisp.atom_table(param.pa).i;
         else
            BBS.lisp.error("due-flash", "Parameter must be integer.");
         end if;
      else
         BBS.lisp.error("due-flash", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function set_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pin_elem : BBS.lisp.element_type;
      state_elem  : BBS.lisp.element_type;
      pin : Integer;
      state : Integer;
      rest : BBS.lisp.element_type;
      ok : Boolean := True;
   begin
      --
      --  Get the first and second values
      --
      BBS.lisp.utilities.first_value(e, pin_elem, rest);
      BBS.lisp.utilities.first_value(rest, state_elem, rest);
      --
      --  Check if the pin number value is an integer atom.
      --
      if pin_elem.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(pin_elem.pa).kind = BBS.lisp.ATOM_INTEGER then
            pin := BBS.lisp.atom_table(pin_elem.pa).i;
            BBS.lisp.memory.deref(pin_elem);
         else
            BBS.lisp.error("set-pin", "Pin number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pin", "Pin number must be an atom.");
         ok := False;
      end if;
      --
      --  Check if the pin state is an integer atom.
      --
      if state_elem.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(state_elem.pa).kind = BBS.lisp.ATOM_INTEGER then
            state := BBS.lisp.atom_table(state_elem.pa).i;
            BBS.lisp.memory.deref(state_elem);
         else
            BBS.lisp.error("set-pin", "Pin state must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pin", "Pin state must be an atom.");
         ok := False;
      end if;
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
      if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
         BBS.lisp.error("set-pin", "Pin number is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then set the pin
      --
      if ok then
         if state = 0 then
            discretes.pin(pin).all.set(0);
         else
            discretes.pin(pin).all.set(1);
         end if;
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function read_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      pin : Integer;
      rest : BBS.lisp.element_type;
      a : BBS.lisp.atom_index;
      el : BBS.lisp.element_type;
      value : BBS.embed.Bit;
      flag : Boolean;
      ok : Boolean := True;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(param.pa).kind = BBS.lisp.ATOM_INTEGER then
            pin := BBS.lisp.atom_table(param.pa).i;
            BBS.lisp.memory.deref(param);
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
            if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
               BBS.lisp.error("read-pin", "Pin number is out of range.");
               ok := False;
            end if;
         else
            ok := False;
            BBS.lisp.error("read-pin", "Parameter must be integer.");
         end if;
      else
         ok := False;
         BBS.lisp.error("read-pin", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      --
      --  If the parameter is an integer and in range, then read the pin and try
      --  to return the value.
      --
      if ok then
         value := discretes.pin(pin).all.get;
         flag := bbs.lisp.memory.alloc(a);
         if flag then
            BBS.lisp.atom_table(a) := (ref => 1, Kind => BBS.lisp.ATOM_INTEGER, i => Integer(value));
            el := (Kind => BBS.lisp.ATOM_TYPE, pa => a);
         else
            BBS.lisp.error("read-pin", "Unable to allocate atom");
            ok := False;
            el := BBS.lisp.NIL_ELEM;
         end if;
      else
         el := BBS.lisp.NIL_ELEM;
      end if;
      return el;
   end;
   --
   --  Set the mode (input or output) of a digital pin.  Two parameters are read.
   --  The first parameter is the pin number (0 .. discretes.max_pin).  The
   --  second is the mode (0 is input, 1 is output).
   --
   function pin_mode(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pin_elem : BBS.lisp.element_type;
      mode_elem  : BBS.lisp.element_type;
      pin : Integer;
      state : Integer;
      rest : BBS.lisp.element_type;
      ok : Boolean := True;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, pin_elem, rest);
      --
      --  Get the second value
      --
      BBS.lisp.utilities.first_value(rest, mode_elem, rest);
      --
      --  Check if the pin number value is an integer atom.
      --
      if pin_elem.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(pin_elem.pa).kind = BBS.lisp.ATOM_INTEGER then
            pin := BBS.lisp.atom_table(pin_elem.pa).i;
            BBS.lisp.memory.deref(pin_elem);
         else
            BBS.lisp.error("pin-mode", "Pin number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("pin-mode", "Pin number must be an atom.");
         BBS.lisp.print(pin_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the pin state is an integer atom.
      --
      if mode_elem.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(mode_elem.pa).kind = BBS.lisp.ATOM_INTEGER then
            state := BBS.lisp.atom_table(mode_elem.pa).i;
            BBS.lisp.memory.deref(mode_elem);
         else
            BBS.lisp.error("pin-mode", "Pin mode must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("pin-mode", "Pin mode must be an atom.");
         BBS.lisp.print(mode_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
      if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
         BBS.lisp.error("pin-mode", "Pin number is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then set the pin
      --
      if ok then
         if state = 0 then
            discretes.pin(pin).all.config(BBS.embed.GPIO.Due.gpio_input);
         else
            discretes.pin(pin).all.config(BBS.embed.GPIO.Due.gpio_output);
         end if;
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Read the value of one of the analog inputs.
   --
   function read_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      pin : Integer;
      rest : BBS.lisp.element_type;
      a : BBS.lisp.atom_index;
      el : BBS.lisp.element_type;
      value : BBS.embed.uint12;
      flag : Boolean;
      ok : Boolean := True;
      ain  : BBS.embed.AIN.due.Due_AIN_record;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.ATOM_TYPE then
         if BBS.lisp.atom_table(param.pa).kind = BBS.lisp.ATOM_INTEGER then
            pin := BBS.lisp.atom_table(param.pa).i;
            BBS.lisp.memory.deref(param);
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
            if (pin < BBS.embed.ain.due.AIN_Num'First) or (pin > BBS.embed.ain.due.AIN_Num'Last) then
               BBS.lisp.error("read-analog", "Pin number is out of range.");
               ok := False;
            end if;
         else
            ok := False;
            BBS.lisp.error("read-analog", "Parameter must be integer.");
         end if;
      else
         ok := False;
         BBS.lisp.error("read-analog", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      --
      --  If the parameter is an integer and in range, then read the pin and try
      --  to return the value.
      --
      if ok then
         ain.channel := pin;
         value := ain.get;
         flag := bbs.lisp.memory.alloc(a);
         if flag then
            BBS.lisp.atom_table(a) := (ref => 1, Kind => BBS.lisp.ATOM_INTEGER, i => Integer(value));
            el := (Kind => BBS.lisp.ATOM_TYPE, pa => a);
         else
            BBS.lisp.error("read-analog", "Unable to allocate atom");
            ok := False;
            el := BBS.lisp.NIL_ELEM;
         end if;
      else
         el := BBS.lisp.NIL_ELEM;
      end if;
      return el;
   end;
   --
   --
   --  Read the value of one of the analog inputs.
   --
   function set_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
   begin
      return BBS.lisp.NIL_ELEM;
   end;


end lisp;
