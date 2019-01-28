
package body serial.int is
   --
   --  Enhanced transmission to work on all channels.  If no channel is
   --  specified, default to channel 0.
   --
   --  Procedure to transmit a character on a serial port.
   --
   procedure put(chan : port_id; c : Character) is
   begin
      buff(chan).tx_write(c);
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
         buff(chan).tx_write(s(i));
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
         buff(chan).tx_write(s(i));
      end loop;
      for i in tx_eol'Range loop
         buff(chan).tx_write(tx_eol(i));
      end loop;
   end;
   --
   procedure put_line(s : string) is
   begin
      put_line(0, s);
   end;
   --
   --  Procedure to write a new line to the serial port
   --
   procedure new_line is
   begin
      new_line(0);
   end;
   --
   procedure new_line(chan : port_id) is
   begin
      for i in tx_eol'Range loop
         buff(chan).tx_write(tx_eol(i));
      end loop;
   end;
   --
   --  Enables RS-485 driver control via the specified pin.
   --
   procedure enable_rs485(chan : port_id; d : pio.digital_pin_rec_access) is
   begin
      buff(chan).enable_rs485(d);
   end;
   --
   --  Wait until transmit buffer is empty.
   --
   procedure flush(chan : port_id) is
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(susp_tx_buff_empty(chan));
   end;
   --
   --  Enable or disable rx interrupt.
   --
   procedure rx_enable(chan : port_id; b : Boolean) is
   begin
      buff(chan).set_rx_int(b);
   end;
   --
   --  Check to see if characters are available in the buffer
   --
   function rx_ready return Boolean is
   begin
      return rx_ready(0);
   end;
   --
   function rx_ready(chan : port_id) return Boolean is
   begin
      return Ada.Synchronous_Task_Control.Current_State(susp_rx_buff_not_empty(chan));
   end;
   --
   --  Read a character from the buffer.
   --
   function get return Character is
   begin
      return get(0);
   end;
   --
   function get(chan : port_id) return Character is
      c : Character;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(susp_rx_buff_not_empty(chan));
      buff(chan).rx_read(c);
      if rx_echo(chan) then
         if c = CR then
            new_line(chan);
         else
            buff(chan).tx_write(c);
         end if;
      end if;
      return c;
   end;
   --
   -- Return the next character in the receive buffer without removing it
   --
   function peek return Character is
   begin
      return peek(0);
   end;
   --
   function peek(chan : port_id) return Character is
      c : Character;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True(susp_rx_buff_not_empty(chan));
      buff(chan).rx_peek(c);
      return c;
   end;
   --
   --  Return a line of text.
   --
   procedure get_line(s : in out String; l : out Integer) is
   begin
      get_line(0, s, l);
   end;
   --
   procedure get_line(chan : port_id; s : in out String; l : out Integer) is
      i : Integer := s'First;
      c : Character;
   begin
      loop
         c := get(chan);
         if ((c = BS) or (c = DEL)) and rx_echo(chan) and rx_del_enable(chan) then
            if i > s'First then
               if c = BS then
                  put(chan, ' ' & BS);
               else
                  put(chan, BS & ' ' & BS);
               end if;
               i := i - 1;
            end if;
         else
            exit when c = CR;
            exit when c = LF;
            s(i) := c;
            i := i + 1;
            exit when i > s'Last;
         end if;
      end loop;
      l := i - s'First;
   end;
   --
   -- Procedures to control configuration settings
   --
   procedure set_echo(chan : port_id; b : Boolean) is
   begin
      rx_echo(chan) := b;
   end;
   --
   procedure set_del(chan : port_id; b : Boolean) is
   begin
      rx_del_enable(chan) := b;
   end;
   --
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
      --  Add a character to the buffer.  Note that if the buffer is empty and
      --  the transmitter is ready, the character is written directly to the
      --  transmitter.  The transmit interrupt is only enabled when transmitter
      --  is not ready and a character is written to the buffer.
      --
      entry tx_write(c : Character) when tx_buff_not_full is
      begin
         if rs485_mode then
            pio.set(rs485_pin, 1);
         end if;
         channel(channel_id).port.IDR.TXRDY := 1;
         if (channel(channel_id).port.SR.TXRDY = 1) and tx_buff_empty then
            channel(channel_id).port.THR.TXCHR := Character'Pos(c);
         else
            tx_buff(tx_fill_ptr) := Character'Pos(c);
            tx_fill_ptr := tx_fill_ptr + 1;
            tx_buff_not_full := (tx_fill_ptr + 1) /= tx_empty_ptr;
            channel(channel_id).port.IER.TXRDY := 1;
            tx_buff_empty := False;
            Ada.Synchronous_Task_Control.Set_False(susp_tx_buff_empty(channel_id));
         end if;
         if rs485_mode then
            channel(channel_id).port.IER.TXEMPTY := 1;
         end if;
      end;
      --
      --  Procedure to read a character from the receive buffer.  Calls to this
      --  procedure need to be synchronized using susp_rx_buff_not_empty.
      --
      procedure rx_read(c : out Character) is
      begin
         c := Character'Val(rx_buff(rx_empty_ptr));
         rx_empty_ptr := rx_empty_ptr + 1;
         if rx_empty_ptr = rx_fill_ptr then
            Ada.Synchronous_Task_Control.Set_False(susp_rx_buff_not_empty(channel_id));
         else
            Ada.Synchronous_Task_Control.Set_True(susp_rx_buff_not_empty(channel_id));
         end if;
      end;
      --
      --  Return the next character from the buffer, but don;t remove it from
      --  the buffer.  This also needs to be synchronized using
      --  susp_rx_buff_not_empty.
      --
      procedure rx_peek(c : out Character) is
      begin
         c := Character'Val(rx_buff(rx_empty_ptr));
         Ada.Synchronous_Task_Control.Set_True(susp_rx_buff_not_empty(channel_id));
      end;
      --
      --  Procedure to reset the receive buffer.  Set pointers and flags to
      --  their initial conditions.
      --
      procedure rx_clear is
      begin
         rx_fill_ptr       := 0;
         rx_empty_ptr      := 0;
      end;
      --
      --  Enable or disable the RX interrupt
      --
      procedure set_rx_int(b : Boolean) is
      begin
         if b then
            channel(channel_id).port.IER.RXRDY := 1;
         else
            channel(channel_id).port.IDR.RXRDY := 1;
         end if;
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
      --  Receiver ready:  Add characters to the receive buffer.  If buffer is
      --    full, the oldest character is discarded.
      --
      --  Transmitter empty: This is triggered when the UART is finished sending
      --    data and there is no more data ready.  This is used in RS-485 mode
      --    to clear the pin used to enable the drivers.
      --
      procedure int_handler is
      begin
         --
         --  Check for transmitter ready.  If so, send the next character(s).
         --
         while (channel(channel_id).port.SR.TXRDY = 1) and not tx_buff_empty loop
            channel(channel_id).port.THR.TXCHR := tx_buff(tx_empty_ptr);
            tx_empty_ptr := tx_empty_ptr + 1;
            if tx_empty_ptr = tx_fill_ptr then
               tx_buff_empty := True;
               Ada.Synchronous_Task_Control.Set_True(susp_tx_buff_empty(channel_id));
            else
               tx_buff_empty := False;
               Ada.Synchronous_Task_Control.Set_False(susp_tx_buff_empty(channel_id));
            end if;
            if tx_buff_empty then
               channel(channel_id).port.IDR.TXRDY := 1;
            end if;
            tx_buff_not_full := True;
         end loop;
         --
         --  Check for receiver ready.  If the buffer is full, discard the oldest
         --  character in the buffer.
         --
         while channel(channel_id).port.SR.RXRDY = 1 loop
            rx_buff(rx_fill_ptr) := channel(channel_id).port.RHR.RXCHR;
            rx_fill_ptr := rx_fill_ptr + 1;
            --
            --  Check if buffer is full.  If so, increment the rx_empty_ptr,
            --  thus discarding the oldest entry in the buffer.
            --
            if (rx_fill_ptr + 1) = rx_empty_ptr then
               rx_empty_ptr := rx_empty_ptr + 1;
            end if;
            Ada.Synchronous_Task_Control.Set_True(susp_rx_buff_not_empty(channel_id));
         end loop;
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
