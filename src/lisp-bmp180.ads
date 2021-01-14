with BBS.lisp;
package lisp.bmp180 is
   --
   --  (read-bmp180)
   --    Reads the ambient temperature in degrees C and atmospheric pressure  in
   --    Pascals from the BMP180 sensor.
   --
   function read_bmp180(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
end;
