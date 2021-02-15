--with BBS.embed.due.serial.int;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed.i2c.BMP180;
with BBS.lisp.memory;
with cli;
use type cli.i2c_device_location;
package body lisp.bmp180 is
   --
   --  Read the BMP180 sensor
   --
--   function read_bmp180(s : BBS.lisp.cons_index) return BBS.lisp.element_type is
   procedure read_bmp180(e : out BBS.lisp.element_type; s : BBS.lisp.cons_index) is
      pragma Unreferenced (s);
      err    : BBS.embed.i2c.err_code;
      flag   : Boolean;
      temperature : Integer;
      pressure : Integer;
      temp_flag : Boolean := False;
      press_flag : Boolean := False;
      temp_cons : BBS.lisp.cons_index;
      press_cons : BBS.lisp.cons_index;
   begin
      --
      --  First check if the BMP180 is present
      --
      if cli.bmp180_found = cli.absent then
         BBS.lisp.error("read_bmp180", "BMP180 not configured in system");
         e := (kind => BBS.lisp.E_ERROR);
         return;
      end if;
      --
      --  Then get values from the sensor
      --
      cli.BMP180.start_conversion(BBS.embed.i2c.BMP180.cvt_temp, err);
      loop
         flag := cli.BMP180.data_ready(err);
         exit when flag;
         exit when err /= BBS.embed.i2c.none;
      end loop;
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bmp180", "BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
         e := (kind => BBS.lisp.E_ERROR);
         return;
      else
         temperature := cli.BMP180.get_temp(err)/10;
         if err = BBS.embed.i2c.none then
            temp_flag := True;
         end if;
         cli.BMP180.start_conversion(BBS.embed.i2c.BMP180.cvt_press0, err);
         loop
            flag := cli.BMP180.data_ready(err);
            exit when flag;
            exit when err /= BBS.embed.i2c.none;
         end loop;
         if err /= BBS.embed.i2c.none then
            BBS.lisp.error("read-bmp180", "BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
            e := (kind => BBS.lisp.E_ERROR);
            return;
         else
            pressure := cli.BMP180.get_press(err);
            if err = BBS.embed.i2c.none then
               press_flag := True;
            end if;
         end if;
      end if;
      --
      --  Now, construct the return value.  There are 4 possibilities since
      --  each of the two values can be present or absent.
      --
      --  If things failed and neither value is present (the simplest case):
      --
      if (not temp_flag) and (not press_flag) then
         e := BBS.lisp.NIL_ELEM;
         return;
      end if;
      --
      --  Now need to allocate two conses for the list
      --
      flag := BBS.lisp.memory.alloc(temp_cons);
      if not flag then
         BBS.lisp.error("read-bmp180", "Unable to allocate cons for temperature");
         e := (kind => BBS.lisp.E_ERROR);
         return;
      end if;
      flag := BBS.lisp.memory.alloc(press_cons);
      if not flag then
         BBS.lisp.error("read-bmp180", "Unable to allocate cons for pressure");
         BBS.lisp.memory.deref(temp_cons);
         e := (kind => BBS.lisp.E_ERROR);
         return;
      end if;
      --
      --  The conses have been successfully allocated.  Now build the list.
      --
      BBS.lisp.cons_table(temp_cons).car := BBS.lisp.NIL_ELEM;
      BBS.lisp.cons_table(temp_cons).cdr := (kind => BBS.lisp.E_CONS, ps => press_cons);
      BBS.lisp.cons_table(press_cons).car := BBS.lisp.NIL_ELEM;
      BBS.lisp.cons_table(press_cons).cdr := BBS.lisp.NIL_ELEM;
      --
      --  Now, add the values to the list if they are present
      --
      if temp_flag then
         BBS.lisp.cons_table(temp_cons).car := (kind => BBS.lisp.E_VALUE,
                                                v => (kind => BBS.lisp.V_INTEGER,
                                                      i => BBS.lisp.int32(temperature*10)));
      end if;
      if press_flag then
         BBS.lisp.cons_table(press_cons).car := (kind => BBS.lisp.E_VALUE,
                                                 v => (kind => BBS.lisp.V_INTEGER,
                                                       i => BBS.lisp.int32(pressure)));
      end if;
      e := (kind => BBS.lisp.E_CONS, ps => temp_cons);
   end;
   --
end;
