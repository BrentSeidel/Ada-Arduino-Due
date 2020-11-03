with BBS.units;
with BBS.embed.due.serial.int;
with BBS.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed.i2c.BME280;
with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
with BBS.lisp.memory;
with cli;
use type cli.i2c_device_location;
package body lisp.bme280 is
   --
   --  (read-bme280) returns a list of three items containing the x, y, and z
   --  rotations in integer values of degrees per second.
   --
   function read_bme280(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pragma Unreferenced (e);
      s : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      err  : BBS.embed.i2c.err_code;
      flag : Boolean;
      temp : BBS.units.temp_c;
      press : BBS.units.press_p;
      hum  : Integer;
      head : BBS.lisp.cons_index;
      t1   : BBS.lisp.cons_index;
      t2   : BBS.lisp.cons_index;
   begin
      --
      --  First check if the L3GD20 is present
      --
      if cli.bme280_found = cli.absent then
         BBS.lisp.error("read_bme280", "BME280 not configured in system");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Then get values from the sensor
      --
      cli.BME280.start_conversion(err);
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280", "Error starting conversion: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      loop
         flag := cli.BME280.data_ready(err);
         exit when flag;
         exit when err /= BBS.embed.i2c.none;
      end loop;
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280", "Error waiting for conversion: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      cli.BME280.read_data(err);
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280", "Error reading data: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      temp := cli.BME280.get_temp;
      s.put_line("BME280 Temperature " & Integer'Image(Integer(temp)));
      press := cli.BME280.get_press;
      s.put_line("BME280 Pressure " & Integer'Image(Integer(press)));
      hum := cli.BME280.get_hum;
      s.put_line("BME280 Humidity " & Integer'Image(Integer(Float(hum)/102.4)));
      flag := BBS.lisp.memory.alloc(head);
      if not flag then
         BBS.lisp.error("read_bme280", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(float(temp)*10.0)));
      flag := BBS.lisp.memory.alloc(t1);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_bme280", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).cdr := (kind => BBS.lisp.E_CONS, ps => t1);
      BBS.lisp.cons_table(t1).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(float(press))));
      flag := BBS.lisp.memory.alloc(t2);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_bme280", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(t1).cdr := (kind => BBS.lisp.E_CONS, ps => t2);
      BBS.lisp.cons_table(t2).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(hum)));
      return (kind => BBS.lisp.E_CONS, ps => head);
   end;
   --
   -- (read-bme280-raw)
   --    Reads the sensors and returns a list of three items containing the raw
   --    values for temperature, pressure, and humidity, in that order.
   --
   function read_bme280_raw(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pragma Unreferenced (e);
      s : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
      err  : BBS.embed.i2c.err_code;
      flag : Boolean;
      raw_temp : BBS.embed.uint32;
      raw_press : BBS.embed.uint32;
      raw_hum  : BBS.embed.uint32;
      head : BBS.lisp.cons_index;
      t1   : BBS.lisp.cons_index;
      t2   : BBS.lisp.cons_index;
   begin
      --
      --  First check if the L3GD20 is present
      --
      if cli.bme280_found = cli.absent then
         BBS.lisp.error("read_bme280-raw", "BME280 not configured in system");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Then get values from the sensor
      --
      cli.BME280.start_conversion(err);
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280-raw", "Error starting conversion: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      loop
         flag := cli.BME280.data_ready(err);
         exit when flag;
         exit when err /= BBS.embed.i2c.none;
      end loop;
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280-raw", "Error waiting for conversion: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      cli.BME280.read_data(err);
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bme280-raw", "Error reading data: " & BBS.embed.i2c.err_code'Image(err));
         return (kind => BBS.lisp.E_ERROR);
      end if;
      cli.BME280.get_raw(raw_temp, raw_press, raw_hum);
      s.put_line("BME280 Temperature " & Integer'Image(Integer(raw_temp)));
      s.put_line("BME280 Pressure " & Integer'Image(Integer(raw_press)));
      s.put_line("BME280 Humidity " & Integer'Image(Integer(raw_hum)));
      flag := BBS.lisp.memory.alloc(head);
      if not flag then
         BBS.lisp.error("read_bme280-raw", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(raw_temp)));
      flag := BBS.lisp.memory.alloc(t1);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_bme280-raw", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(head).cdr := (kind => BBS.lisp.E_CONS, ps => t1);
      BBS.lisp.cons_table(t1).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(raw_press)));
      flag := BBS.lisp.memory.alloc(t2);
      if not flag then
         BBS.lisp.memory.deref(head);
         BBS.lisp.error("read_bme280-raw", "Unable to allocate cons for results");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.cons_table(t1).cdr := (kind => BBS.lisp.E_CONS, ps => t2);
      BBS.lisp.cons_table(t2).car := (kind => BBS.lisp.E_VALUE,
                                        v => (kind => BBS.lisp.V_INTEGER, i =>
                                                BBS.lisp.int32(raw_hum)));
      return (kind => BBS.lisp.E_CONS, ps => head);
   end;
   --
end;
