with SAM3x8e;
use type SAM3x8e.UInt12;
use type SAM3x8e.int32;
use type SAM3x8e.int64;
with serial.int;
with utils;
package body i2c.BME280 is
   --
   procedure configure(i2c_port : port_id; addr : SAM3x8e.UInt7; error : out err_code) is
      temp_1 :SAM3x8e. Byte;
      temp_2 : SAM3x8e.Byte;
      temp_3 : SAM3x8e.Byte;
      temp_a : SAM3x8e.uint12;
      temp_b : SAM3x8e.uint12;
      stdout : serial.int.serial_port := serial.int.get_port(0);
   begin
      self.port := i2c_port;
      --
      -- Calibration parameters.  Most of these are either two byte with LSB
      -- first or a single byte.  The two exceptions are H4 and H5.
      --
      self.T1 := readm2(self.port, i2c.BME280.addr, dig_T1, error);
      if error /= none then
         return;
      end if;
      self.T2 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_T2, error));
      if error /= none then
         return;
      end if;
      self.T3 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_T3, error));
      if error /= none then
         return;
      end if;
      self.P1 := readm2(self.port, i2c.BME280.addr, dig_P1, error);
      if error /= none then
         return;
      end if;
      self.P2 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P2, error));
      if error /= none then
         return;
      end if;
      self.P3 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P3, error));
      if error /= none then
         return;
      end if;
      self.P4 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P4, error));
      if error /= none then
         return;
      end if;
      self.P5 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P5, error));
      if error /= none then
         return;
      end if;
      self.P6 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P6, error));
      if error /= none then
         return;
      end if;
      self.P7 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P7, error));
      if error /= none then
         return;
      end if;
      self.P8 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P8, error));
      if error /= none then
         return;
      end if;
      self.P9 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_P9, error));
      if error /= none then
         return;
      end if;
      self.H1 := read(self.port, i2c.BME280.addr, dig_H1, error);
      if error /= none then
         return;
      end if;
      self.H2 := utils.uint16_to_int16(readm2(self.port, i2c.BME280.addr, dig_H2, error));
      if error /= none then
         return;
      end if;
      self.H3 := read(self.port, i2c.BME280.addr, dig_H3, error);
      if error /= none then
         return;
      end if;
      --
      -- Specification of H4 is given as 0xE4/0xE5[3:0] => dig_H4[11:4]/[3:0]
      -- Specification of H5 is given as 0xE5[7:4]/0xE6 => dig_H5[3:0]/[11:4]
      -- These are actually 12 bit integers packed into three bytes.
      --
      temp_1 := read(self.port, i2c.BME280.addr, dig_H4, error);
      if error /= none then
         return;
      end if;
      temp_2 := read(self.port, i2c.BME280.addr, dig_H45, error);
      if error /= none then
         return;
      end if;
      temp_3 := read(self.port, i2c.BME280.addr, dig_H5, error);
      if error /= none then
         return;
      end if;
      temp_a := SAM3x8e.uint12(temp_1)*16 + SAM3x8e.uint12(temp_2 mod 16);
      temp_b := SAM3x8e.uint12(temp_3)*16 + SAM3x8e.uint12(temp_2/16);
      self.H4 := SAM3x8e.int16(utils.uint12_to_int12(temp_a));
      self.H5 := SAM3x8e.int16(utils.uint12_to_int12(temp_b));
      self.H6 := read(self.port, i2c.BME280.addr, dig_H6, error);
      if error /= none then
         return;
      end if;
      if debug then
         stdout.Put_Line("BME280: Calibration parameters");
         stdout.put_line("BME280: T1 = " & Integer'Image(integer(self.T1)));
         stdout.put_line("BME280: T2 = " & Integer'Image(integer(self.T2)));
         stdout.put_line("BME280: T3 = " & Integer'Image(integer(self.T3)));
         stdout.put_line("BME280: P1 = " & Integer'Image(integer(self.P1)));
         stdout.put_line("BME280: P2 = " & Integer'Image(integer(self.P2)));
         stdout.put_line("BME280: P3 = " & Integer'Image(integer(self.P3)));
         stdout.put_line("BME280: P4 = " & Integer'Image(integer(self.P4)));
         stdout.put_line("BME280: P5 = " & Integer'Image(integer(self.P5)));
         stdout.put_line("BME280: P6 = " & Integer'Image(integer(self.P6)));
         stdout.put_line("BME280: P7 = " & Integer'Image(integer(self.P7)));
         stdout.put_line("BME280: P8 = " & Integer'Image(integer(self.P8)));
         stdout.put_line("BME280: P9 = " & Integer'Image(integer(self.P9)));
         stdout.put_line("BME280: H1 = " & Integer'Image(integer(self.H1)));
         stdout.put_line("BME280: H2 = " & Integer'Image(integer(self.H2)));
         stdout.put_line("BME280: H3 = " & Integer'Image(integer(self.H3)));
         stdout.put_line("BME280: temp_1 = " & Integer'Image(integer(temp_1)));
         stdout.put_line("BME280: temp_2 = " & Integer'Image(integer(temp_2)));
         stdout.put_line("BME280: temp_3 = " & Integer'Image(integer(temp_3)));
         stdout.put_line("BME280: H4 = " & Integer'Image(integer(self.H4)));
         stdout.put_line("BME280: H5 = " & Integer'Image(integer(self.H5)));
         stdout.put_line("BME280: H6 = " & Integer'Image(integer(self.H6)));
      end if;
      --
      -- Now set the mode.  Use forced mode to keep the interface similar to
      -- the BMP180.
      --
      -- First put into sleep more so configuration can be set.  Oversampling
      -- is set to 1 for each parameter.
      --
      write(self.port, i2c.BME280.addr, ctrl_meas, mode_sleep, error);
      --
      -- Set humidity oversampling
      --
      write(self.port, i2c.BME280.addr, ctrl_hum, hum_over_1, error);
      --
      -- Temperature, pressure, and mode are in the same register so set them
      -- all at once.
      --
      write(self.port, i2c.BME280.addr, ctrl_meas, temp_over_1 + press_over_1 +
                        mode_force, error);
   end;
   --
   procedure start_conversion(error : out err_code) is
   begin
      write(self.port, i2c.BME280.addr, ctrl_meas, temp_over_1 + press_over_1 +
                        mode_force, error);
   end;
   --
   function data_ready(error : out err_code) return boolean is
      data : SAM3x8e.Byte;
      err : err_code;
   begin
      data := read(self.port, i2c.BME280.addr, status, err);
      error := err;
      if ((data and stat_measuring) /= stat_measuring) and (err = none) then
         return true;
      else
         return false;
      end if;
   end;
   --
   -- Read 3 bytes for pressure and temperature and 2 bytes for humidity. 8 bytes
   -- total
   --
   procedure read_data(error : out err_code) is
      --
      -- Nested functions to do conversion of the temperature, pressure, and
      -- humidity values.  These are based on the example C code in the datasheet
      -- and are not the clearest code.
      --
      -- Temperature conversion (t_fine needs a little more processing before
      -- generating the final temperature, but it is used in other processing)
      --
      function cal_temp return SAM3x8e.int32 is
         var1 : SAM3x8e.int32;
         var2 : SAM3x8e.int32;
      begin
         var1 := (SAM3x8e.int32(self.raw_temp)/2**3 - SAM3x8e.int32(self.T1)*2)*SAM3x8e.int32(self.T2)/2**11;
         var2 := (SAM3x8e.int32(self.raw_temp)/2**4 - SAM3x8e.int32(self.T1))*
           (SAM3x8e.int32(self.raw_temp)/2**4 - SAM3x8e.int32(self.T1))/2**12*SAM3x8e.int32(self.T3)/2**14;
         return var1 + var2;
      end;
      --
      -- Pressure conversion.  The result is in Pascals * 256.
      --
      function cal_press return SAM3x8e.uint32 is
         var1 : SAM3x8e.int64;
         var2 : SAM3x8e.int64;
         p : SAM3x8e.int64;
      begin
         var1 := SAM3x8e.int64(self.t_fine) - 128000;
         var2 := var1*var1*SAM3x8e.int64(self.P6);
         var2 := var2 + var1*SAM3x8e.int64(self.P5)*2**17;
         var2 := var2 + SAM3x8e.int64(self.P4)*2**35;
         var1 := var1*var1*SAM3x8e.int64(self.P3)/2**8 + var1*SAM3x8e.int64(self.P2)*2**12;
         var1 := (2**47 + var1)*SAM3x8e.int64(self.P1)/2**33;
         if (var1 = 0) then
            return 0;
         end if;
         p := 1_048_576 - SAM3x8e.int64(self.raw_press);
         p := (p*2**31 - var2)*3125/var1;
         var1 := SAM3x8e.int64(self.P9)*(p/2**13)*(p/2**13)/2**25;
         var2 := SAM3x8e.int64(self.P8)*p/2**19;
         p := (p + var1 + var2)/2**8 + SAM3x8e.int64(self.P7)*2**4;
         return SAM3x8e.uint32(p);
      end;
      --
      -- Humidity conversion.  The result is in % * 1024.
      --
      function cal_hum return SAM3x8e.uint32 is
         v_x1 : SAM3x8e.int32;
      begin
         v_x1 := self.t_fine - 76_800;
         v_x1 := ((SAM3x8e.int32(self.raw_hum)*2**14 - SAM3x8e.int32(self.H4)*2**20 - SAM3x8e.int32(self.H5)*v_x1 + 16_384)/2**15)*
           ((((v_x1*SAM3x8e.int32(self.H6)/2**10)*
            (v_x1*SAM3x8e.int32(self.H3)/2**11 + 32_768)/2**10 + 2_097_152)*SAM3x8e.int32(self.H2) + 8192)/2**14);
         v_x1 := v_x1 - (v_x1/2**15)*(v_x1/2**15)/2**7*SAM3x8e.int32(self.H1)/2**4;
         if (v_x1 < 0) then
            v_x1 := 0;
         elsif (v_x1 > 419_430_400) then
            v_x1 := 419_430_400;
         end if;
         return SAM3x8e.uint32(v_x1/2**12);
      end;
      --
   begin
      read(self.port, addr, data_start, buff'access, 8, error);
      self.raw_press := (SAM3x8e.uint32(buff(0))*2**16 + SAM3x8e.uint32(buff(1))*2**8 + SAM3x8e.uint32(buff(2)))/16;
      self.raw_temp  := (SAM3x8e.uint32(buff(3))*2**16 + SAM3x8e.uint32(buff(4))*2**8 + SAM3x8e.uint32(buff(5)))/16;
      self.raw_hum   := SAM3x8e.uint32(buff(6))*2**8  + SAM3x8e.uint32(buff(7));
      if (debug) then
         serial.int.put_line("p_raw: " & Integer'Image(integer(self.raw_press)));
         serial.int.put_line("t_raw: " & Integer'Image(integer(self.raw_temp)));
         serial.int.put_line("h_raw: " & Integer'Image(integer(self.raw_hum)));
      end if;
      --
      -- Compute the calibrated values based on the algorithms in the datasheet.
      --
      self.t_fine := cal_temp;
      self.p_cal := cal_press;
      self.h_cal := cal_hum;
   end;
   --
   function get_temp return integer is
   begin
      return integer((self.t_fine*5 + 128)/2**8);
   end;
   --
   function get_press return integer is
   begin
      return integer(self.p_cal);
   end;
   --
   function get_hum return integer is
   begin
      return integer(self.h_cal);
   end get_hum;
   --
   function get_hum return float is
   begin
      return float(self.h_cal)/1024.0;
   end get_hum;
   --
end i2c.BME280;
