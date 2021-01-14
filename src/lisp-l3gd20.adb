with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed.i2c.L3GD20H;
with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
with BBS.lisp.memory;
with cli;
use type cli.i2c_device_location;
package body lisp.l3gd20 is
   --
   --  (read-l3gd20) returns a list of three items containing the x, y, and z
   --  rotations in integer values of degrees per second.
   --
   function read_l3gd20(s : BBS.lisp.cons_index) return BBS.lisp.element_type is
      pragma Unreferenced (s);
      err  : BBS.embed.i2c.err_code;
      flag : Boolean;
      rot  : BBS.embed.i2c.L3GD20H.rotations_dps;
      head : BBS.lisp.cons_index;
      t1   : BBS.lisp.cons_index;
      t2   : BBS.lisp.cons_index;
   begin
      --
      --  First check if the L3GD20 is present
      --
      if cli.l3gd20_found = cli.absent then
         BBS.lisp.error("read_l3gd20", "L3GD20 not configured in system");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      rot := cli.L3GD20.get_rotations(err);
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read_l3gd20", "Error occured reading from device " &
                 BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      flag := BBS.lisp.memory.alloc(head);
      if not flag then
         BBS.lisp.error("read_l3gd20", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(float(rot.x)*10.0)));
      flag := BBS.lisp.memory.alloc(t1);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_l3gd20", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).cdr := (kind => BBS.lisp.E_CONS, ps => t1);
      BBS.lisp.cons_table(t1).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(float(rot.y)*10.0)));
      flag := BBS.lisp.memory.alloc(t2);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_l3gd20", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(t1).cdr := (kind => BBS.lisp.E_CONS, ps => t2);
      BBS.lisp.cons_table(t2).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(float(rot.z)*10.0)));
      return (kind => BBS.lisp.E_CONS, ps => head);
   end;
   --
end;
