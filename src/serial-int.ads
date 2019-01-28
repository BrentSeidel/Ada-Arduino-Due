with Ada.Interrupts.Names;
with Ada.Synchronous_Task_Control;
with System;
with SAM3x8e;
use type SAM3x8e.Bit;
use type SAM3x8e.Byte;
use type SAM3x8e.UInt32;
with SAM3x8e.UART;
with pio;
use type pio.pio_access;
--
--  This is an interrupt driven serial package that can be used to print
--  text with reduced overhead for the user code.  Characters are written
--  to a buffer which is sent to the UART under control of interrupts.
--
--  An even more processor efficient option would be to use DMA for handling
--  the I/O.  This is left for a future project.
--
--  There are two goals for this driver.  The first is to provide console I/O
--  for a person to communicate with the device.  The second is to be able to
--  communicate with other devices.  There are many features that could be
--  added, but it should be kept fairly simple and primitive.
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
   --
   --  Procedure to write a new line to the serial port
   --
   procedure new_line;
   procedure new_line(chan : port_id);
   --
   --  Procedure to enable RS-485 mode on an I/O channel.  It requires an
   --  initialized digital I/O pin record.  If d.ctrl isn't pointing to a
   --  PIO control record, bad things can happen, so make this a precondition.
   --
   procedure enable_rs485(chan : port_id; d : pio.digital_pin_rec_access)
     with pre => ((d.ctrl = pio.PIOA'Access) or (d.ctrl = pio.PIOB'Access) or
                      (d.ctrl = pio.PIOC'Access) or (d.ctrl = pio.PIOD'Access));
   --
   --  Wait until transmit buffer is empty.  Since the Ravenscar profile doesn't
   --  allow more than one entry in a protected object, look into using
   --  suspension_objects from Ada.Synchronous_Task_Control.
   --
   procedure flush(chan : port_id);
   --
   --  Enable or disable rx interrupt.
   --
   procedure rx_enable(chan : port_id; b : Boolean);
   --
   --  Check to see if characters are available in the buffer
   --
   function rx_ready return Boolean;
   function rx_ready(chan : port_id) return Boolean;
   --
   --  Read a character from the buffer.
   --
   function get return Character;
   function get(chan : port_id) return Character;
   --
   -- Return the next character in the receive buffer without removing it
   --
   function peek return Character;
   function peek(chan : port_id) return Character;
   --
   --  Return a line of text.
   --
   procedure get_line(s : in out String; l : out Integer);
   procedure get_line(chan : port_id; s : in out String; l : out Integer);
   --
   -- Procedures to control configuration settings
   --
   procedure set_echo(chan : port_id; b : Boolean);
   procedure set_del(chan : port_id; b : Boolean);


private
   --
   --  Some configuration values.
   --
   rx_echo : array (port_id'Range) of Boolean := (True, False,
                                                           False, False);
   tx_eol  : constant String := CR & LF;
   rx_del_enable : array (port_id'Range) of Boolean :=
     (True, False, False, False);
   --
   --  Declare types for the transmit buffers.  This size can be adjusted as
   --  needed.
   --
   type tx_buff_ptr is mod 2**8;
   type tx_buff_type is array (tx_buff_ptr'Range) of SAM3x8e.Byte;
   --
   --  Declare types for the receive buffers.  This size can be adjusted as
   --  needed.
   --
   type rx_buff_ptr is mod 2**8;
   type rx_buff_type is array (rx_buff_ptr'Range) of SAM3x8e.Byte;

   --
   --  A protected type defining the transmit and receive (not yet implemented)
   --  buffers as well as an interface to the buffers.  This also includes an
   --  interrupt handler to communicate with the U/SART.
   --
   protected type buffer(chan : port_id) is
      --
      --  Functions to return statuses
      --
      function tx_buffer_full return Boolean;
      function tx_complete return Boolean;
      --
      --  Entry point to transmit a character.  Per Ravenscar, there can be
      --  only one entry.
      --
      entry tx_write(c : Character);
      --
      --  Procedure to reset the receive buffer.
      --
      procedure rx_clear;
      --
      --  Procedure to read a character from the receive buffer.  Calls to this
      --  procedure need to be synchronized using susp_rx_buff_not_empty.
      --
      procedure rx_read(c : out Character);
      --
      --  Return the next character from the buffer, but don;t remove it from
      --  the buffer.  This also needs to be synchronized using
      --  susp_rx_buff_not_empty.
      --
      procedure rx_peek(c : out Character);
      --
      --  Enable or disable the RX interrupt
      --
      procedure set_rx_int(b : Boolean);
      --
      --  Procedure to enable RS-485 mode.
      --
      procedure enable_rs485(d : pio.digital_pin_rec_access);
   private
      procedure int_handler;
      pragma Attach_Handler (int_handler, channel(chan).int_id);
      pragma Interrupt_Priority(System.Interrupt_Priority'First);

      channel_id : port_id := chan;
      rs485_mode : Boolean := False;
      rs485_pin  : pio.digital_pin_rec_access;

      tx_buff_empty    : Boolean := True;
      tx_buff_not_full : Boolean := True;
      tx_fill_ptr      : tx_buff_ptr := 0;
      tx_empty_ptr     : tx_buff_ptr := 0;
      tx_buff          : tx_buff_type;

      rx_fill_ptr       : rx_buff_ptr := 0;
      rx_empty_ptr      : rx_buff_ptr := 0;
      rx_buff           : rx_buff_type;
   end buffer;

   --
   --  Since the Ravenscar profile allows only one entry barrier per protected
   --  objects, use some suspension objects to accomplish the same purpose.
   --
   susp_tx_buff_empty : array (port_id'Range) of
     Ada.Synchronous_Task_Control.Suspension_Object;
   --
   susp_rx_buff_not_empty : array (port_id'Range) of
     Ada.Synchronous_Task_Control.Suspension_Object;
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

