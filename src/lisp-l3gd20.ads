with BBS.lisp;
package lisp.l3gd20 is
   --
   --  (read-l3gd20)
   --    Reads the gyroscope and returns a list of three items containing the
   --    x, y, and z rotations in integer values of degrees per second.
   --
   function read_l3gd20(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
end;
