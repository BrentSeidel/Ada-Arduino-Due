with BBS.lisp;
package lisp.bme280 is
   --
   --  (read-bme280)
   --    Reads the gyroscope and returns a list of three items containing the
   --    x, y, and z rotations in integer values of degrees per second.
   --
   function read_bme280(e : BBS.lisp.element_type) return BBS.lisp.element_type;
end;
