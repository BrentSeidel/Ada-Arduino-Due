//
//  Models for stepper motors
//
//use <bbs_constants.scad>
use <../../Things/bbs_stepper.scad>
use <../../pd-gears/pd-gears.scad>


//--------------------------------------------------------------------------------------
// Model for a NEMA 17 mounting plate.  These are just the cutouts for the shaft and
// screw holes.
//
//module bbs_NEMA17_holes(height)
//module bbs_NEMA17_dshaft(height)


difference()
{
  translate([-20, -20, 0]) cube([60, 40, 4]);
  union()
  {
    hole = 5.56/2;
    translate([0, 0, -0.5]) bbs_NEMA17_holes(5);
    translate([30, 10, -0.5]) cylinder(r=hole, h=5, $fn=12);
    translate([30, -10, -0.5]) cylinder(r=hole, h=5, $fn=12);
  }
}

//difference()
//{
//  translate([30, -10, 0]) cube([30, 20, 2]);
//  translate([35, 0, -0.5]) bbs_NEMA17_dshaft(3);
//}

//difference()
//{
//  gear(5, 20, 4, 1);
//  translate([0, 0, -0.5]) bbs_NEMA17_dshaft(5);
//}

//translate([50, 0, 0]) difference()
//{
//  gear(5, 36, 4, 1);
//  translate([0, 0, -0.5]) bbs_NEMA17_dshaft(5);
//}

//translate([0, 60, 0]) difference()
//{
//  gear(5, 40, 4, 1);
//  translate([0, 0, -0.5]) bbs_NEMA17_dshaft(5);
//}
