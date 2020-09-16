//
//  Tray for holding the Arduino Due and some extra boards.
//
use <../../Things/bbs_tray.scad>
use <../../Things/bbs_breadboard.scad>
use <../../Things/bbs_arduino.scad>
use <../../Things/bbs_constants.scad>
use <../../Things/bbs_boards.scad>

payload_x = 15;
payload_y = 15;
proto1_y = 90;
proto2_y = 145;
module arduino_due_tray()
{
  screw_size = 3*screw_6_size()/4;
  screw_hole = screw_6_size()/2;
  difference()
  {
    union()
    {
      bbs_tray(10, 5, false);
      translate([payload_x, payload_y, 3]) bbs_arduino_mega2560_standoffs(5, screw_size, 12);
      translate([payload_x + 55, proto1_y, 3]) bbs_quarter_permaprotoboard_standoffs(5, screw_size, 12);
      translate([payload_x + 55, proto2_y, 3]) bbs_quarter_permaprotoboard_standoffs(5, screw_size, 12);
      translate([payload_x + 5, proto2_y, 3]) bbs_quarter_permaprotoboard_standoffs(5, screw_size, 12);
      translate([payload_x + 5, proto1_y, 3]) bbs_quarter_permaprotoboard_standoffs(5, screw_size, 12);
//      translate([payload_x - 10, proto1_y + 25, 3]) bbs_pwm16_standoffs(5, screw_size, 12);
//      translate([payload_x + 30, proto1_y, 3]) bbs_bme280_standoffs(5, screw_size, 12);
    }
    union()
    {
      translate([payload_x, payload_y, -2]) bbs_arduino_mega2560_standoffs(5 + 6, screw_hole, 12);
      translate([payload_x + 55, proto1_y, -2])  bbs_quarter_permaprotoboard_standoffs(5 + 6, screw_hole, 12);
      translate([payload_x + 55, proto2_y, -2]) bbs_quarter_permaprotoboard_standoffs(5 + 6, screw_hole, 12);
      translate([payload_x + 5, proto2_y, -2]) bbs_quarter_permaprotoboard_standoffs(5 + 6, screw_hole, 12);
      translate([payload_x + 5, proto1_y, -2]) bbs_quarter_permaprotoboard_standoffs(5 + 6, screw_hole, 12);
//      translate([payload_x - 10, proto1_y + 25, -2]) bbs_pwm16_standoffs(5 + 6, screw_hole, 12);
//      translate([payload_x + 30, proto1_y, -2]) bbs_bme280_standoffs(5 + 6, screw_hole, 12);
      translate([payload_x + 20, 10, -1]) minkowski()
      {
        cube([40, 65, 10]);
        cylinder(r=1, h=10);
      }
      translate([10, 10, -1]) minkowski()
      {
        cube([15, 65, 10]);
        cylinder(r=1, h=10);
      }
      translate([85, 10, -1]) minkowski()
      {
        cube([15, 65, 10]);
        cylinder(r=1, h=10);
      }
      translate([10, 175, -1]) minkowski()
      {
        cube([100, 20, 10]);
        cylinder(r=1, h=10);
      }
//      translate([10, 145, -1]) minkowski()
//      {
//        cube([100, 20, 10]);
//        cylinder(r=1, h=10);
//      }
      translate([10, 80, -1]) minkowski()
      {
        cube([100, 30, 10]);
        cylinder(r=1, h=10);
      }
      translate([10, 122, -1]) minkowski()
      {
        cube([100, 40, 10]);
        cylinder(r=1, h=10);
      }
//      translate([70, 120, -1]) minkowski()
//      {
//        cube([40, 20, 10]);
//        cylinder(r=1, h=10);
//      }
    }
  }
}


rotate([0, 0, 90]) arduino_due_tray();
//translate([payload_x, payload_y, 7]) color("red") bbs_arduino_mega2560();
//translate([payload_x + 55, proto1_y, 7]) color("red") bbs_quarter_permaprotoboard();
//translate([payload_x + 55, proto2_y, 7]) color("red") bbs_quarter_permaprotoboard();
//translate([payload_x + 5, proto1_y, 7]) color("red") bbs_quarter_permaprotoboard();
//translate([payload_x + 5, proto2_y, 7]) color("red") bbs_quarter_permaprotoboard();
//translate([payload_x - 10, proto1_y + 25, 7]) color("red") bbs_pwm16();
//translate([payload_x + 30, proto1_y, 7]) color("red") bbs_bme280();
