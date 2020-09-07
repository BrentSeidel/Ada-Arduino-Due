//
// Small trays for various things for arduinos
//
use <../../Things/bbs_tray.scad>
use <../../Things/bbs_breadboard.scad>
use <../../Things/bbs_arduino.scad>
use <../../Things/bbs_constants.scad>

payload_x = 5;
payload_y = 15;
module arduino_due_tray()
{
    difference()
    {
        union()
        {
            bbs_tray(10, 7, false);
            translate([payload_x, payload_y + 5, 3]) bbs_arduino_mega2560_standoffs(5, screw_6_size(), 12);
        }
        union()
        {
            translate([payload_x, payload_y + 5, -2])
                bbs_arduino_mega2560_standoffs(5 + 6, screw_6_size()/2, 12);
            translate([30, 10, -1]) minkowski()
            {
                cube([30, 65, 10]);
                cylinder(r=1, h=10);
            }
        }
    }
}


arduino_due_tray();
//translate([payload_x, payload_y, 7]) color("red") bbs_arduino_uno();
//translate([payload_x + 70, payload_y, 7]) color("red") bbs_quarter_permaprotoboard();
