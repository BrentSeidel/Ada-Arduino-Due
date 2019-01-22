with Ada.Interrupts.Names;
with SAM3x8e;
use type SAM3x8e.Bit;
use type SAM3x8e.Byte;
use type SAM3x8e.UInt32;
with SAM3x8e.UART;
with pio;
--
--  This is an interrupt driven serial package that can be used to print
--  text with reduced overhead for the user code.  Characters are written
--  to a buffer which is sent to the UART under control of interrupts.
--
--  An even more processor efficient option would be to use DMA for handling
--  the I/O.  This is left for a future project.
--
package serial.int is
   --
   --  Very simple procedure to write a character to the UART.  It does a
   --  busy wait on the UART_SR TXRDY (transmit ready) bit.  It does a loop
   --  until the value of the bit is 1 and then write the character.
   --
   procedure put(c : Character);
   procedure put(chan : port_id; c : Character);
   --
   --  Procedure to put a string to the serial port
   --
   procedure put(s : string);
   procedure put(chan : port_id; s : string);
   --
   --  Procedure to put a string to the serial port followed by a CR/LF
   --
   procedure put_line(s : string);
   procedure put_line(chan : port_id; s : string);

private

   --
   --  Declare types for the transmit buffers.  This size can be adjusted as
   --  needed.
   --
   type tx_buff_ptr is mod 2**8;
   type tx_buff_type is array (tx_buff_ptr'Range) of SAM3x8e.Byte;

   --
   --  A protected type defining the transmit and receive (not yet implemented)
   --  buffers as well as an interface to the buffers.  This also includes an
   --  interrupt handler to communicate with the U/SART.
   --
   protected type buffer(chan : port_id) is
      entry add_buffer(c : Character);
   private
      procedure int_handler;
      pragma Attach_Handler (int_handler, channel(chan).int_id);

      channel_id       : port_id := chan;
      tx_buff_empty    : Boolean := True;
      tx_buff_Not_full : Boolean := True;
      tx_fill          : tx_buff_ptr := 0;
      tx_empty         : tx_buff_ptr := 0;
      tx_buff          : tx_buff_type;
   end buffer;

   --
   --  Declare a buffer for each serial port
   --
   buff0 : aliased buffer(0);
   buff1 : aliased buffer(1);
   buff2 : aliased buffer(2);
   buff3 : aliased buffer(3);

   --
   --  An array of the buffers so that the I/O routines can access a buffer by
   --  the port ID.
   --
   type buffer_access is access all buffer;
   buff : array (port_id'Range) of buffer_access :=
     (buff0'access, buff1'access, buff2'access, buff3'access);
end serial.int;

