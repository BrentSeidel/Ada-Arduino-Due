
package body serial.int is
   --
   --  If the transmitter is ready, write directly to the transmitter and
   --  enable the TX interrupt.  If the transmitter is not ready, check if
   --  the buffer is full.  If not full, add character to buffer.  If full,
   --  wait for buffer to be not full.
   --
   procedure put(c : Character) is
   begin
      if tx_ready then
         Serial.THR.TXCHR := Character'Pos(c);
         Serial.IER.TXRDY := 1;
      else
         buff0.add_buffer(c);
      end if;
   end;
   --
   --  Procedure to put a string to the serial port
   --
   procedure put(s : string) is
   begin
      for i in s'Range loop
         put(s(i));
      end loop;
   end;
   --
   --  Procedure to put a string to the serial port followed by a CR/LF
   --
   procedure put_line(s : string) is
   begin
      for i in s'Range loop
         put(s(i));
      end loop;
      put(CR);
      put(LF);
   end;
   --
   --  -----------------------------------------------------------------------
   --  Enhanced transmission to work on all channels.
   --
   --  If the transmitter is ready, write directly to the transmitter and
   --  enable the TX interrupt.  If the transmitter is not ready, check if
   --  the buffer is full.  If not full, add character to buffer.  If full,
   --  wait for buffer to be not full.
   --
   procedure put(chan : port_id; c : Character) is
   begin
      if tx_ready(chan) then
         channel(chan).port.THR.TXCHR := Character'Pos(c);
         channel(chan).port.IER.TXRDY := 1;
      else
         buff(chan).add_buffer(c);
      end if;
   end;
   --
   --  Procedure to put a string to the serial port
   --
   procedure put(chan : port_id; s : string) is
   begin
      for i in s'Range loop
         put(chan, s(i));
      end loop;
   end;
   --
   --  Procedure to put a string to the serial port followed by a CR/LF
   --
   procedure put_line(chan : port_id; s : string) is
   begin
      for i in s'Range loop
         put(chan, s(i));
      end loop;
      put(chan, CR);
      put(chan, LF);
   end;
   --
   protected body buffer is
      --
      --  Add a character to the buffer.  Disable interrupts, add the character
      --  to the buffer and update the pointers, then renable interrupts.
      --
      entry add_buffer(c : Character) when tx_buff_not_full is
      begin
         channel(channel_id).port.IDR.TXRDY := 1;
         tx_buff(tx_fill) := Character'Pos(c);
         tx_fill := tx_fill + 1;
         tx_buff_Not_full := (tx_fill + 1) /= tx_empty;
         channel(channel_id).port.IER.TXRDY := 1;
      end;
      --
      --  This is the interrupt handler.  Check to see if the transmitter is
      --  ready.  If so, process it.  Check to see if the receiver is ready.
      --  If so, TBD.  If neither are ready, then the interrupt reason is
      --  unknown, so just return.
      --
      procedure int_handler is
      begin
         if channel(channel_id).port.SR.TXRDY = 1 then
            channel(channel_id).port.THR.TXCHR := tx_buff(tx_empty);
            tx_empty := tx_empty + 1;
            tx_buff_empty := tx_empty = tx_fill;
            if tx_buff_empty then
               channel(channel_id).port.IDR.TXRDY := 1;
            end if;
         end if;
         if channel(channel_id).port.SR.RXRDY = 1 then
            null;  --  Receive is not yet implemented.
         end if;
      end;
   end buffer;
   --
end serial.int;
