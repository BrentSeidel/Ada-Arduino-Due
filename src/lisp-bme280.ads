with BBS.lisp;
package lisp.bme280 is
   --
   --  (read-bme280)
   --    Reads the sensors and returns a list of three items containing the
   --    temperature (C), pressure (Pa), and humidity (%), in that order.
   --
--   function read_bme280(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   procedure read_bme280(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index);
   --
   -- (read-bme280-raw)
   --    Reads the sensors and returns a list of three items containing the raw
   --    values for temperature, pressure, and humidity, in that order.
   --
--   function read_bme280_raw(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   procedure read_bme280_raw(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index);
end;
