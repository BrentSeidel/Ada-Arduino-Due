with BBS.lisp;
package lisp.bme280 is
   --
   --  (read-bme280)
   --    Reads the sensors and returns a list of three items containing the
   --    temperature (C), pressure (Pa), and humidity (%), in that order.
   --
   function read_bme280(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
   --
   -- (read-bme280-raw)
   --    Reads the sensors and returns a list of three items containing the raw
   --    values for temperature, pressure, and humidity, in that order.
   --
   function read_bme280_raw(s : BBS.lisp.cons_index) return BBS.lisp.element_type;
end;
