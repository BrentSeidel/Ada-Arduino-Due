
package body serial.int is
   --  -----------------------------------------------------------------------
   --  Enhanced transmission to work on all channels.  If no channel is
   --  specified, default to channel 0.
   --
   --  Procedure to transmit a character on a serial port.
   --
   procedure put(chan : port_id; c : Character) is
   begin
      buff(chan).add_buffer(c);
   end;
   --
   procedure put(c : Character) is
   begin
      put(0, c);
   end;
   --
   --  Procedure to put a string to the serial port
   --
   procedure put(chan : port_id; s : string) is
   begin
      for i in s'Range loop
         buff(chan).add_buffer(s(i));
      end loop;
   end;
   --
   procedure put(s : string) is
   begin
      put(0, s);
   end;
   --
   --  Procedure to put a string to the serial port followed by a CR/LF
   --
   procedure put_line(chan : port_id; s : string) is
   begin
      for i in s'Range loop
         buff(chan).add_buffer(s(i));
      end loop;
      buff(chan).add_buffer(CR);
      buff(chan).add_buffer(LF);
   end;
   --
   procedure put_line(s : string) is
   begin
      put_line(0, s);
   end;
   --
   procedure enable_rs485(chan : port_id; d : pio.digital_pin_rec_access) is
   begin
      buff(chan).enable_rs485(d);
   end;
   --  -----------------------------------------------------------------------
   --  Protected buffer.  This handles the low level details of transmitting
   --  characters on the serial port.
   --
   protected body buffer is
      --
      --  Functions to return status about the buffer
      --
      function tx_buffer_full return Boolean is
      begin
           return not tx_buff_not_full;
      end;
      --
      function tx_complete return Boolean is
      begin
         return tx_buff_empty and (channel(channel_id).port.SR.TXEMPTY = 1);
      end;
      --
      --  rx is not yet implemented
      --
      function rx_buffer_empty return Boolean is
      begin
         return true;
      end;
      --
      --  Add a character to the buffer.  Note that if the buffer is empty and
      --  the transmitter is ready, the character is written directly to the
      --  transmitter.  This is necessary in order to trigger the interrupt
      --  handler to start pulling additional characters in.  Otherwise,
      --  characters are written to the buffer to wait for the interrupt
      --  handler to process them.
      --
      entry add_buffer(c : Character) when tx_buff_not_full is
      begin
         if rs485_mode then
            pio.set(rs485_pin, 1);
         end if;
         channel(channel_id).port.IDR.TXRDY := 1;
         if (channel(channel_id).port.SR.TXRDY = 1) and tx_buff_empty then
            channel(channel_id).port.THR.TXCHR := Character'Pos(c);
         else
            tx_buff(tx_fill) := Character'Pos(c);
            tx_fill := tx_fill + 1;
            tx_buff_not_full := (tx_fill + 1) /= tx_empty;
         end if;
         if rs485_mode then
            channel(channel_id).port.IER.TXEMPTY := 1;
         end if;
         channel(channel_id).port.IER.TXRDY := 1;
         tx_buff_empty := False;
      end;
      --
      --  Procedure to enable RS-485 mode.
      --
      procedure enable_rs485(d : pio.digital_pin_rec_access) is
      begin
         rs485_pin := d;
         pio.set(rs485_pin, 0);
         rs485_mode := True;
      end;
      --
      --  This is the interrupt handler.  There are three different things that
      --  may cause an interrupt:
      --  Transmitter ready:  If the buffer is not empty, then pull the next
      --    character out of the buffer and write it to the transmitter.  Update
      --    pointers and check if that was the last character.
      --
      --  Receiver ready:  Not yet implemented.  This will add receive characters
      --    to the receive buffer.
      --
      --  Transmitter empty: This is triggered when the UART is finished sending
      --    data and there is no more data ready.  This is used in RS-485 mode
      --    to clear the pin used to enable the drivers.
      --
      procedure int_handler is
      begin
         --
         --  Check for transmitter ready.
         --
         if (channel(channel_id).port.SR.TXRDY = 1) and not tx_buff_empty then
            channel(channel_id).port.THR.TXCHR := tx_buff(tx_empty);
            tx_empty := tx_empty + 1;
            tx_buff_empty := tx_empty = tx_fill;
            if tx_buff_empty then
               channel(channel_id).port.IDR.TXRDY := 1;
            end if;
            tx_buff_not_full := True;
         end if;
         --
         --  Check for receiver ready
         --
         if channel(channel_id).port.SR.RXRDY = 1 then
            null;  --  Receive is not yet implemented.
         end if;
         --
         --  Check for transmitter empty
         --
         if (channel(channel_id).port.SR.TXEMPTY = 1) and rs485_mode then
            pio.set(rs485_pin, 0);
            channel(channel_id).port.IDR.TXEMPTY := 1;
         end if;
      end int_handler;
   end buffer;
   --
end serial.int;
