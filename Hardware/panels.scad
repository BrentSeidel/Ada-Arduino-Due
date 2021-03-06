//
//  These are a collection of panels for my Arduino Due development system.  The panels
//  include switches and LEDs and a couple of LCD displays.  Select which panels you
//  want, then you can render them for printing.  My printer is not big enough to print
//  them all in one batch.
//
use <../../Things/bbs_panel.scad>
use <../../Things/bbs_leds.scad>
use <../../Things/bbs_switches.scad>
use <../../Things/bbs_lcd_20x4.scad>
use <../../Things/bbs_lcd7.scad>

width = 220;
//
//  This panel has mounting for 8 switches and LEDs.  Numbers are embossed between the
//  switch and LEDs.  The number values increase from right to left starting with the
//  passed "start" value.
module panel_switch(start)
{
  union()
  {
    difference()
    {
      bbs_panel(10, 3);
      union()
      {
        for(a = [1:8])
        {
          y = a*(width - 30)/8;
          translate([15, y, -0.1]) bbs_spdt_switch_cutout(2.2);
          translate([40, y, -0.1]) bbs_led_cutout(5, 2.2);
          translate([28, y, 1.5]) linear_extrude(height = 0.6) rotate([0, 0, -90])
              text(str(a + start), halign="center", valign="center", size=6);
        }
      }
    }
    for(a = [1:8])
    {
      y = a*(width - 30)/8;
      translate([40, y, 0]) bbs_led_mount(5, 2);
    }
  }
}


module panel_lcd7()
{
  difference()
  {
    bbs_panel(10, 6);
    union()
    {
      translate([110, 30, -0.1]) rotate([0, 0, 90]) bbs_lcd7();
    }
  }
}

module panel_lcd20x4()
{
  switch_x = 15;
  switch_y = 150;
  switch_space_y = 35;
  switch_space_x = 25;
  union()
  {
    difference()
    {
      union()
      {
        bbs_panel(10, 4);
      }
      union()
      {
        translate([70, 30, -0.1]) rotate([0, 0, 90]) bbs_20x4_lcd_cutouts(2.2, 10);
        translate([switch_x, switch_y, -0.1]) bbs_spdt_switch_cutout(2.2);
        translate([switch_x, switch_y + switch_space_y, -0.1]) bbs_spdt_switch_cutout(2.2);
        translate([switch_x+switch_space_x, switch_y, -0.1]) rotate([0, 0, 270]) bbs_pot2_cutout(2.2);
        translate([switch_x+switch_space_x, switch_y + switch_space_y, -0.1]) rotate([0, 0, 270]) bbs_pot2_cutout(2.2);
        for(a = [6:8])
        {
          y = a*(width - 30)/8;
          translate([65, y, -0.1]) bbs_led_cutout(5, 3);
        }
      }
    }
    for(a = [6:8])
    {
      y = a*(width - 30)/8;
      translate([65, y, 0]) bbs_led_mount(5, 2);
    }
  }
}
rotate([0, 0, 90])
{
//  panel_switch(0);
//  translate([70, 0, 0]) panel_switch(8);
//  translate([140, 0, 0]) panel_lcd7();
//  translate([0, 0, 0]) panel_lcd20x4();
    bbs_pot2_knob();
//  translate([40, 150, -0.1]) rotate([0, 0, 270]) color("red") bbs_pot2();
//  translate([40, 185, -0.1]) rotate([0, 0, 270]) color("red") bbs_pot2();
//  translate([15, 150, -0.1]) color("red") bbs_spdt_switch();
//  translate([15, 185, -0.1]) color("red") bbs_spdt_switch();
}
