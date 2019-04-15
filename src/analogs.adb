with SAM3x8e.ADC;
with SAM3x8e.DACC;
with SAM3x8e.PMC;

with BBS.embed.due.dev;
package body analogs is
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
   --  Write a value to an analog output
   --
   procedure put(c : AOUT_Num; v : SAM3x8e.UInt12) is
   begin
      --
      --  Busy wait for the channel to be ready
      --
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
