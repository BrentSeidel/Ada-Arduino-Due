with dev;
package body analogs is
   --
   --  Setup the analog to digital controller
   --
   procedure setup is
   begin
      --
      --  Enable clock for ADC
      --
      SAM3x8e.PMC.PMC_Periph.PMC_PCER1.PID.Arr(dev.ADC_ID) := 1;
      --
      --  Setup some reasonable values for the ADC
      --
      --
      --  Set modes - these are probably defaults.
      --
      SAM3x8e.ADC.ADC_Periph.MR.TRGEN    := SAM3x8e.ADC.Dis;
      SAM3x8e.ADC.ADC_Periph.MR.LOWRES   := SAM3x8e.ADC.Bits_12;
      SAM3x8e.ADC.ADC_Periph.MR.SLEEP    := SAM3x8e.ADC.Sleep;
      SAM3x8e.ADC.ADC_Periph.MR.FWUP     := SAM3x8e.ADC.Off;
      SAM3x8e.ADC.ADC_Periph.MR.FREERUN  := SAM3x8e.ADC.Off;
      SAM3x8e.ADC.ADC_Periph.MR.STARTUP  := SAM3x8e.ADC.Sut0;
      SAM3x8e.ADC.ADC_Periph.MR.SETTLING := SAM3x8e.ADC.Ast3;
      SAM3x8e.ADC.ADC_Periph.MR.ANACH    := SAM3x8e.ADC.None;
      SAM3x8e.ADC.ADC_Periph.MR.USEQ     := SAM3x8e.ADC.Num_Order;
      --
      --  Use a gain of 1.
      --
      for i in AIN_type'Range loop
         SAM3x8e.ADC.ADC_Periph.CGR.Arr(i) := 1;
      end loop;
      --
      --  Turn the temperature sensor on
      --
      SAM3x8e.ADC.ADC_Periph.ACR.TSON := 1;
   end;
   --
   --  Enable or disable a specified channel
   --
   procedure enable(c : AIN_type; b : Boolean) is
   begin
      if b then
         SAM3x8e.ADC.ADC_Periph.CHER.CH.Arr(c) := 1;
      else
         SAM3x8e.ADC.ADC_Periph.CHDR.CH.Arr(c) := 1;
      end if;
   end;
   --
   --  Start conversion
   --
   procedure start is
   begin
      SAM3x8e.ADC.ADC_Periph.CR.START := 1;
   end;
   --
   --  Set free running conversion.
   --
   procedure free_run(b : Boolean) is
   begin
      if b then
         SAM3x8e.ADC.ADC_Periph.MR.FREERUN := SAM3x8e.ADC.On;
      else
         SAM3x8e.ADC.ADC_Periph.MR.FREERUN := SAM3x8e.ADC.Off;
      end if;
   end;
   --
   --  Read an ADC value from a channel
   --
   function get(c : AIN_type) return SAM3x8e.UInt16 is
   begin
      return SAM3x8e.UInt16(SAM3x8e.ADC.ADC_Periph.CDR(c).DATA);
   end;

end;
