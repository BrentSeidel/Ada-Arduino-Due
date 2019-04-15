with Ada.Interrupts.Names;
with Ada.Synchronous_Task_Control;
with System;
with SAM3x8e;
use type SAM3x8e.UInt32;
use type SAM3x8e.Bit;

package analogs is
   --
   --  Define a subtype for the analog outputs
   --
   subtype AOUT_Num is Integer range 0 .. 1;
   --
   --  Setup the digital to analog controller
   --
   procedure setup_aout;
   --
   --  Enable or disable a specified analog output channel
   --
   procedure enable_aout(c : AOUT_Num; b : Boolean);
   --
   --  Write a value to an analog output
   --
   procedure put(c : AOUT_Num; v : SAM3x8e.UInt12);
   --
private
   --
   --  Interrupt handler for Analog Outs.  Since both outputs share the same
   --  interrupt and the same TXRDY flag, the handler is very simple compared
   --  to the serial handler.
   --
   protected type aout_handler is
      --
      --  Start the wait for transmission complete
      --
      procedure start_wait;
   private
      procedure int_handler;
      pragma Attach_Handler (int_handler, Ada.Interrupts.Names.DACC_Interrupt);
      pragma Interrupt_Priority(System.Interrupt_Priority'First);
   end aout_handler;

   aout_interrupt : aout_handler;
   aout_ready     : Ada.Synchronous_Task_Control.Suspension_Object;

end analogs;
