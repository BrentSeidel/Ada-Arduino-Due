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
end i2c.BME280;
