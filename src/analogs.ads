with SAM3x8e.ADC;
with SAM3x8e.PMC;

package analogs is
   --
   --  Note that enabling an analog input will superceed any other use for that
   --  pin.  The architecture has defined 16 analog inputs, 0-15, with input 15
   --  being used to measure the CPU temperature.
   --
   --  Mapping between SAM3X8E analog channels and Arduino analog numbers
   --
   --  SAM3X8E   Arduino
   --  -------   -------
   --  AD0       AD07
   --  AD1/WKUP1 AD06
   --  AD2       AD05
   --  AD3       AD04
   --  AD4       AD03
   --  AD5       AD02
   --  AD6       AD01
   --  AD7       AD00
   --  AD8       <unused>
   --  AD9       <unused>
   --  AD10      AD08
   --  AD11      AD09
   --  AD12      AD10
   --  AD13      AD11/TXD3
   --  AD14      <unused>
   --  AD15      CPU temp sensor
   --
   --  Do not use channels marked as unused.  It may cause problems.  Using AD15.
   --  the CPU temperature sensor also seems to cause trouble with tasking.
   --
   subtype AIN_type is Integer range 0 .. 15;
   cpu_temp : constant AIN_type := 15;
   --
   --  Setup the analog to digital controller
   --
   procedure setup;
   --
   --  Enable or disable a specified channel
   --
   procedure enable(c : AIN_type; b : Boolean);
   --
   --  Start conversion
   --
   procedure start;
   --
   --  Set free running conversion.
   --
   procedure free_run(b : Boolean);
   --
   --  Read an ADC value from a channel
   --
   function get(c : AIN_type) return SAM3x8e.UInt16;

end analogs;
