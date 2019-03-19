with SAM3x8e.ADC;
with SAM3x8e.DACC;
with SAM3x8e.PMC;

with BBS.embed.due.dev;
package body analogs is
   --
   --  Setup the analog to digital controller
   --
   procedure setup_ain is
   begin
      --
      --  Enable clock for ADC
      --
      SAM3x8e.PMC.PMC_Periph.PMC_PCER1.PID.Arr(BBS.embed.due.dev.ADC_ID) := 1;
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
   end setup_ain;
   --
   --  Setup the digital to analog controller
   --
   procedure setup_aout is
   begin
      --
      --  Enable clock for ADC
      --
      SAM3x8e.PMC.PMC_Periph.PMC_PCER1.PID.Arr(BBS.embed.due.dev.DACC_ID) := 1;
      --
      --  Setup some reasonable values for the DAC
      --
      SAM3x8e.DACC.DACC_Periph.MR.TRGEN := SAM3x8e.DACC.Dis;
      SAM3x8e.DACC.DACC_Periph.MR.WORD  := SAM3x8e.DACC.Half;
      SAM3x8e.DACC.DACC_Periph.MR.SLEEP := 0;  --  Normal mode
      SAM3x8e.DACC.DACC_Periph.MR.TAG   := SAM3x8e.DACC.En;
      SAM3x8e.DACC.DACC_Periph.MR.REFRESH := 1;
      --
      --  Once the Analog outs are initialized, set the ready flag to true
      --
      ada.Synchronous_Task_Control.Set_True(aout_ready);
   end;
   --
   --  Enable or disable a specified analog input channel
   --
   procedure enable_ain(c : AIN_Num; b : Boolean) is
      ain : constant AIN_type := AIN_map(c);
   begin
      if b then
         SAM3x8e.ADC.ADC_Periph.CHER.CH.Arr(ain) := 1;
      else
         SAM3x8e.ADC.ADC_Periph.CHDR.CH.Arr(ain) := 1;
      end if;
   end;
   --
   --  Enable or disable a specified analog output channel
   --
   procedure enable_aout(c : AOUT_Num; b : Boolean) is
   begin
      if b then
         SAM3x8e.DACC.DACC_Periph.CHER.CH.Arr(c) := 1;
      else
         SAM3x8e.DACC.DACC_Periph.CHDR.CH.Arr(c) := 1;
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
   function get(c : AIN_Num) return SAM3x8e.UInt16 is
      ain : constant AIN_type := AIN_map(c);
   begin
      return SAM3x8e.UInt16(SAM3x8e.ADC.ADC_Periph.CDR(ain).DATA);
   end;
   --
   --  Write a value to an analog output
   --
   procedure put(c : AOUT_Num; v : SAM3x8e.UInt12) is
   begin
      --
      --  Busy wait for the channel to be ready
      --
--      while SAM3x8e.DACC.DACC_Periph.ISR.TXRDY = 0 loop
--         null;
--      end loop;
      ada.Synchronous_Task_Control.Suspend_Until_True(aout_ready);
      --
      --  Write the data
      --
      SAM3x8e.DACC.DACC_Periph.CDR := SAM3x8e.UInt32(v) + SAM3x8e.UInt32(c)*16#1000#;
      aout_interrupt.start_wait;
   end;
   --
   --  Interrupt handler for Analog Outs.  Since both outputs share the same
   --  interrupt and the same TXRDY flag, the handler is very simple compared
   --  to the serial handler.
   --
   protected body aout_handler is
      --
      --  Start the wait for transmission complete.  Basically enable the TXRDY
      --  interrupt.
      --
      procedure start_wait is
      begin
         SAM3x8e.DACC.DACC_Periph.IER.TXRDY := 1;
      end;
      --
      --  If there is a TXDRY interrupt, then disable the interrupt and enable
      --  the semaphore.
      --
      procedure int_handler is
      begin
         if SAM3x8e.DACC.DACC_Periph.ISR.TXRDY = 1 then
            SAM3x8e.DACC.DACC_Periph.IDR.TXRDY := 1;
            ada.Synchronous_Task_Control.Set_True(aout_ready);
         end if;
      end;
   end aout_handler;

end;
