with SAM3x8e;
package i2c.BME280 is
   --
   -- Addresses for the BME280 pressure and temperature sensor
   --
   addr : constant SAM3x8e.UInt7 := 16#77#; -- Device address on I2C bus
   data_start : constant SAM3x8e.Byte := 16#f7#;
   up : constant SAM3x8e.Byte := 16#f7#; -- uncomponsated pressure (msb, lsb, xlsb)
   ut : constant SAM3x8e.Byte := 16#fa#; -- uncomponsated temperature (msb, lsb, xlsb)
   uh : constant SAM3x8e.Byte := 16#fd#; -- uncomponsated humidity (msb, lsb)
   ctrl_hum : constant SAM3x8e.Byte := 16#f2#;
   status : constant SAM3x8e.Byte := 16#f3#;
   ctrl_meas : constant SAM3x8e.Byte := 16#f4#;
   config : constant SAM3x8e.Byte := 16#f5#;
   reset : constant SAM3x8e.Byte := 16#e0#;
   id : constant SAM3x8e.Byte := 16#d0#;
   dig_T1 : constant SAM3x8e.Byte := 16#88#; -- uint16
   dig_T2 : constant SAM3x8e.Byte := 16#8a#; -- int16
   dig_T3 : constant SAM3x8e.Byte := 16#8d#; -- int16
   dig_P1 : constant SAM3x8e.Byte := 16#8e#; -- uint16
   dig_P2 : constant SAM3x8e.Byte := 16#90#; -- int16
   dig_P3 : constant SAM3x8e.Byte := 16#92#; -- int16
   dig_P4 : constant SAM3x8e.Byte := 16#94#; -- int16
   dig_P5 : constant SAM3x8e.Byte := 16#96#; -- int16
   dig_P6 : constant SAM3x8e.Byte := 16#98#; -- int16
   dig_P7 : constant SAM3x8e.Byte := 16#9c#; -- int16
   dig_P8 : constant SAM3x8e.Byte := 16#9e#; -- int16
   dig_P9 : constant SAM3x8e.Byte := 16#9f#; -- int16
   dig_H1 : constant SAM3x8e.Byte := 16#a1#; -- SAM3x8e.Byte
   dig_H2 : constant SAM3x8e.Byte := 16#e1#; -- int16
   dig_H3 : constant SAM3x8e.Byte := 16#e3#; -- SAM3x8e.Byte
--
-- Note that H4 and H5 are actually 12 bit integers packed into 3 bytes.
--
   dig_H4 : constant SAM3x8e.Byte := 16#e4#; -- int12
   dig_H45 : constant SAM3x8e.Byte := 16#e5#; -- SAM3x8e.Byte
   dig_H5 : constant SAM3x8e.Byte := 16#e6#; -- int12
   dig_H6 : constant SAM3x8e.Byte := 16#e7#; -- SAM3x8e.Byte
   --
   -- Mode constants
   --
   mode_sleep  : constant SAM3x8e.Byte := 2#000_000_00#;
   mode_force  : constant SAM3x8e.Byte := 2#000_000_10#; -- 2#01# also works
   mode_normal : constant SAM3x8e.Byte := 2#000_000_11#;
   --
   -- Oversampling constants
   -- Humidity
   --
   hum_over_0  : constant SAM3x8e.Byte := 2#000#; -- datasheet says skipped
   hum_over_1  : constant SAM3x8e.Byte := 2#001#;
   hum_over_2  : constant SAM3x8e.Byte := 2#010#;
   hum_over_4  : constant SAM3x8e.Byte := 2#011#;
   hum_over_8  : constant SAM3x8e.Byte := 2#100#;
   hum_over_16 : constant SAM3x8e.Byte := 2#101#; -- apparently the other values work as well
   --
   -- Pressure
   --
   press_over_0  : constant SAM3x8e.Byte := 2#000_000_00#; -- skipped
   press_over_1  : constant SAM3x8e.Byte := 2#001_000_00#;
   press_over_2  : constant SAM3x8e.Byte := 2#010_000_00#;
   press_over_4  : constant SAM3x8e.Byte := 2#011_000_00#;
   press_over_8  : constant SAM3x8e.Byte := 2#100_000_00#;
   press_over_16 : constant SAM3x8e.Byte := 2#101_000_00#;
   --
   -- Temperature
   --
   temp_over_0  : constant SAM3x8e.Byte := 2#000_000_00#; -- skipped
   temp_over_1  : constant SAM3x8e.Byte := 2#000_001_00#;
   temp_over_2  : constant SAM3x8e.Byte := 2#000_010_00#;
   temp_over_4  : constant SAM3x8e.Byte := 2#000_011_00#;
   temp_over_8  : constant SAM3x8e.Byte := 2#000_100_00#;
   temp_over_16 : constant SAM3x8e.Byte := 2#000_101_00#;
   --
   -- Status bits
   --
   stat_measuring : constant SAM3x8e.Byte := 2#0000_1000#;
   stat_im_update : constant SAM3x8e.Byte := 2#0000_0001#;
   --
   --
   -- The configure procedure needs to be called first to initialize the
   -- calibration constants from the device.
   --
   procedure configure(i2c_port : port_id; addr : SAM3x8e.UInt7; error : out err_code);
   --
   -- Starts the BME280 converting data.  Temperature, pressure, and humidity
   -- are converted at the same time.
   --
   procedure start_conversion(error : out err_code);
   --
   -- Check for data ready.  Reading a value before data is ready will have
   -- undesirable results.
   --
   function data_ready(error : out err_code) return boolean;
   --
   -- Read the temperature, pressure, and humidity value (there's less overhead
   -- to read all three value than to try and read each individually) and compute
   -- the calibrated values
   --
   procedure read_data(error : out err_code);
   --
   -- Return the raw uncompensated values.  Used for debugging purposes after
   -- read_data() has been called.
   --
--   procedure get_raw(self : not null access BME280_record'class; raw_temp : out uint32;
--                     raw_press : out uint32; raw_hum : out uint32);
   --
   -- Return the t_fine value.  Used for debugging purposes after
   -- read_data() has been called.
   --
--   function get_t_fine(self : not null access BME280_record'class) return int32;
   --
   -- Return the calibrated temperature value.  Temperature is returned in units
   -- of 0.01 degrees Celsius.
   --
   function get_temp return integer;
   --
   -- Return temperature in various units.
   --
--   function get_temp(self : not null access BME280_record'class) return BBS.units.temp_c;
--   function get_temp(self : not null access BME280_record'class) return BBS.units.temp_f;
--   function get_temp(self : not null access BME280_record'class) return BBS.units.temp_k;
   --
   -- Return the calibrated pressure value.  Pressure is returned in units of
   -- 1/256 Pascals.
   --
   function get_press return integer;
   --
   -- Return pressure in various units.
   --
--   function get_press(self : not null access BME280_record'class) return BBS.units.press_p;
--   function get_press(self : not null access BME280_record'class) return BBS.units.press_mb;
--   function get_press(self : not null access BME280_record'class) return BBS.units.press_atm;
--   function get_press(self : not null access BME280_record'class) return BBS.units.press_inHg;
   --
   -- Return the calibrated relative humidity.  The result is in units of
   -- 1/1024 %.
   --
   function get_hum return integer;
   --
   -- Return the relative humidity in percent.
   --
   function get_hum return float;
   --
private
   debug : constant Boolean := True;

   buff : aliased buffer;
   --
   type BME280_record is record
      port : port_id;
      T1 : SAM3x8e.UInt16 := 0;
      T2 : SAM3x8e.int16 := 0;
      T3 : SAM3x8e.int16 := 0;
      P1 : SAM3x8e.UInt16 := 0;
      P2 : SAM3x8e.int16 := 0;
      P3 : SAM3x8e.int16 := 0;
      P4 : SAM3x8e.int16 := 0;
      P5 : SAM3x8e.int16 := 0;
      P6 : SAM3x8e.int16 := 0;
      P7 : SAM3x8e.int16 := 0;
      P8 : SAM3x8e.int16 := 0;
      P9 : SAM3x8e.int16 := 0;
      H1 : SAM3x8e.Byte := 0;
      H2 : SAM3x8e.int16 := 0;
      H3 : SAM3x8e.Byte := 0;
      H4 : SAM3x8e.int16 := 0;
      H5 : SAM3x8e.int16 := 0;
      H6 : SAM3x8e.Byte := 0;
      --
      -- Data read from device
      --
      raw_press : SAM3x8e.UInt32;
      raw_temp : SAM3x8e.UInt32;
      raw_hum : SAM3x8e.UInt32;
      --
      -- Compensated values
      t_fine : SAM3x8e.int32;
      p_cal : SAM3x8e.UInt32; -- LSB = Pa/256
      h_cal : SAM3x8e.UInt32; -- LSB = %/1024
   end record;

   self : BME280_record;
end i2c.BME280;
