with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
with BBS.lisp.utilities;
with BBS.lisp.memory;
with BBS.embed;
with BBS.embed.due.serial.int;
with BBS.embed.GPIO.Due;
with BBS.embed.ain.due;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
use type bbs.embed.i2c.due.port_id;
with BBS.embed.i2c.BMP180;
with BBS.embed.i2c.PCA9685;
with utils;
with discretes;
with cli;

package body lisp is
   --
   --  Initialize the lisp interpreter and install custom lisp commands
   --
   procedure init is
   begin
      BBS.lisp.init(BBS.embed.due.serial.int.Put_Line'Access, BBS.embed.due.serial.int.Put'Access,
                    BBS.embed.due.serial.int.New_Line'Access, BBS.embed.due.serial.int.Get_Line'Access);
      BBS.lisp.add_builtin("due-flash", due_flash'Access);
      BBS.lisp.add_builtin("set-pin", set_pin'Access);
      BBS.lisp.add_builtin("pin-mode", pin_mode'Access);
      BBS.lisp.add_builtin("read-pin", read_pin'Access);
      BBS.lisp.add_builtin("read-analog", read_analog'Access);
      BBS.lisp.add_builtin("info-enable", info_enable'Access);
      BBS.lisp.add_builtin("info-disable", info_disable'Access);
      BBS.lisp.add_builtin("read-bmp180", read_bmp180'Access);
      BBS.lisp.add_builtin("set-pca9685", set_pca9685'Access);
   end;
   --
   --  Functions for custom lisp commands for the Arduino Due
   --
   --
   --  Simple lisp function to set the number of times to quickly flash the LED.
   --
   function due_flash(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      rest : BBS.lisp.element_type;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.E_VALUE then
         if param.v.kind = BBS.lisp.V_INTEGER then
            utils.flash_count := param.v.i;
         else
            BBS.lisp.error("due-flash", "Parameter must be integer.");
         end if;
      else
         BBS.lisp.error("due-flash", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function set_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pin_elem : BBS.lisp.element_type;
      state_elem  : BBS.lisp.element_type;
      pin : Integer;
      state : Integer;
      rest : BBS.lisp.element_type;
      ok : Boolean := True;
   begin
      --
      --  Get the first and second values
      --
      BBS.lisp.utilities.first_value(e, pin_elem, rest);
      BBS.lisp.utilities.first_value(rest, state_elem, rest);
      --
      --  Check if the pin number value is an integer atom.
      --
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin := pin_elem.v.i;
         else
            BBS.lisp.error("set-pin", "Pin number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pin", "Pin number must be an atom.");
         ok := False;
      end if;
      --
      --  Check if the pin state is an integer atom.
      --
      if state_elem.kind = BBS.lisp.E_VALUE then
         if state_elem.v.kind = BBS.lisp.V_INTEGER then
            state := state_elem.v.i;
         else
            BBS.lisp.error("set-pin", "Pin state must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pin", "Pin state must be an atom.");
         ok := False;
      end if;
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
      if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
         BBS.lisp.error("set-pin", "Pin number is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then set the pin
      --
      if ok then
         if state = 0 then
            discretes.pin(pin).all.set(0);
         else
            discretes.pin(pin).all.set(1);
         end if;
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Set the state of a digital pin  Two parameters are read.  The first
   --  parameter is the pin number (0 .. discretes.max_pin).  The second
   --  is the state (0 is low, 1 is high).
   --
   function read_pin(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      pin : Integer;
      rest : BBS.lisp.element_type;
      el : BBS.lisp.element_type;
      value : BBS.embed.Bit;
      ok : Boolean := True;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.E_VALUE then
         if param.v.kind = BBS.lisp.V_INTEGER then
            pin := param.v.i;
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
            if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
               BBS.lisp.error("read-pin", "Pin number is out of range.");
               ok := False;
            end if;
         else
            ok := False;
            BBS.lisp.error("read-pin", "Parameter must be integer.");
         end if;
      else
         ok := False;
         BBS.lisp.error("read-pin", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      --
      --  If the parameter is an integer and in range, then read the pin and try
      --  to return the value.
      --
      if ok then
         value := discretes.pin(pin).all.get;
         el := (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER, i => Integer(value)));
      else
         el := BBS.lisp.NIL_ELEM;
      end if;
      return el;
   end;
   --
   --  Set the mode (input or output) of a digital pin.  Two parameters are read.
   --  The first parameter is the pin number (0 .. discretes.max_pin).  The
   --  second is the mode (0 is input, 1 is output).
   --
   function pin_mode(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pin_elem : BBS.lisp.element_type;
      mode_elem  : BBS.lisp.element_type;
      pin : Integer;
      state : Integer;
      rest : BBS.lisp.element_type;
      ok : Boolean := True;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, pin_elem, rest);
      --
      --  Get the second value
      --
      BBS.lisp.utilities.first_value(rest, mode_elem, rest);
      --
      --  Check if the pin number value is an integer atom.
      --
      if pin_elem.kind = BBS.lisp.E_VALUE then
         if pin_elem.v.kind = BBS.lisp.V_INTEGER then
            pin := pin_elem.v.i;
         else
            BBS.lisp.error("pin-mode", "Pin number must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("pin-mode", "Pin number must be an atom.");
         BBS.lisp.print(pin_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the pin state is an integer atom.
      --
      if mode_elem.kind = BBS.lisp.E_VALUE then
         if mode_elem.v.kind = BBS.lisp.V_INTEGER then
            state := mode_elem.v.i;
         else
            BBS.lisp.error("pin-mode", "Pin mode must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("pin-mode", "Pin mode must be an atom.");
         BBS.lisp.print(mode_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the pin number is within range of the valid pins.  Not that
      --  pin 4 cannot be used.
      --
      if (pin < 0) or (pin > discretes.max_pin) or (pin = 4) then
         BBS.lisp.error("pin-mode", "Pin number is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then set the pin
      --
      if ok then
         if state = 0 then
            discretes.pin(pin).all.config(BBS.embed.GPIO.Due.gpio_input);
         else
            discretes.pin(pin).all.config(BBS.embed.GPIO.Due.gpio_output);
         end if;
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Read the value of one of the analog inputs.
   --
   function read_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      pin : Integer;
      rest : BBS.lisp.element_type;
      el : BBS.lisp.element_type;
      value : BBS.embed.uint12;
      ok : Boolean := True;
      ain  : BBS.embed.AIN.due.Due_AIN_record;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, param, rest);
      --
      --  Check if the first value is an integer atom.
      --
      if param.kind = BBS.lisp.E_VALUE then
         if param.v.kind = BBS.lisp.V_INTEGER then
            pin := param.v.i;
      --
      --  Check if the pin number is within range of the valid pins.  Note that
      --  pin 4 cannot be used.
      --
            if (pin < BBS.embed.ain.due.AIN_Num'First) or (pin > BBS.embed.ain.due.AIN_Num'Last) then
               BBS.lisp.error("read-analog", "Pin number is out of range.");
               ok := False;
            end if;
         else
            ok := False;
            BBS.lisp.error("read-analog", "Parameter must be integer.");
         end if;
      else
         ok := False;
         BBS.lisp.error("read-analog", "Parameter must be an atom.");
         BBS.lisp.print(param, False, True);
      end if;
      --
      --  If the parameter is an integer and in range, then read the pin and try
      --  to return the value.
      --
      if ok then
         ain.channel := pin;
         value := ain.get;
         el := (Kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER, i => Integer(value)));
      else
         el := BBS.lisp.NIL_ELEM;
      end if;
      return el;
   end;
   --
   --
   --  Read the value of one of the analog inputs.
   --
   function set_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
   begin
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Enable display of info messages
   --
   function info_enable(e : BBS.lisp.element_type) return BBS.lisp.element_type is
   begin
      utils.info.enable;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Disable display of info messages
   --
   function info_disable(e : BBS.lisp.element_type) return BBS.lisp.element_type is
   begin
      utils.info.disable;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Read the BMP180 sensor
   --
   function read_bmp180(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      err    : BBS.embed.i2c.err_code;
      flag   : Boolean;
      temperature : Integer;
      pressure : Integer;
      temp_flag : Boolean := False;
      press_flag : Boolean := False;
      temp_cons : BBS.lisp.cons_index;
      press_cons : BBS.lisp.cons_index;
   begin
      --
      --  First get values from the sensor
      --
      cli.BMP180.start_conversion(BBS.embed.i2c.BMP180.cvt_temp, err);
      loop
         flag := cli.BMP180.data_ready(err);
         exit when flag;
         exit when err /= BBS.embed.i2c.none;
      end loop;
      if err /= BBS.embed.i2c.none then
         BBS.lisp.error("read-bmp180", "BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
      else
         temperature := cli.BMP180.get_temp(err)/10;
         if err = BBS.embed.i2c.none then
            temp_flag := True;
         end if;
         cli.BMP180.start_conversion(BBS.embed.i2c.BMP180.cvt_press0, err);
         loop
            flag := cli.BMP180.data_ready(err);
            exit when flag;
            exit when err /= BBS.embed.i2c.none;
         end loop;
         if err /= BBS.embed.i2c.none then
            BBS.lisp.error("read-bmp180", "BMP180 Error: " & BBS.embed.i2c.err_code'Image(err));
         else
            pressure := cli.BMP180.get_press(err);
            if err = BBS.embed.i2c.none then
               press_flag := True;
            end if;
         end if;
      end if;
      --
      --  Now, construct the return value.  There are 4 possibilities since
      --  each of the two values can be present or absent.
      --
      --  If things failed and neither value is present (the simplest case):
      --
      if (not temp_flag) and (not press_flag) then
         return BBS.lisp.NIL_ELEM;
      end if;
      --
      --  Now need to allocate two conses for the list
      --
      flag := BBS.lisp.memory.alloc(temp_cons);
      if not flag then
         BBS.lisp.error("read-bmp180", "Unable to allocate cons for temperature");
         return BBS.lisp.NIL_ELEM;
      end if;
      flag := BBS.lisp.memory.alloc(press_cons);
      if not flag then
         BBS.lisp.error("read-bmp180", "Unable to allocate cons for pressure");
         BBS.lisp.memory.deref(temp_cons);
         return BBS.lisp.NIL_ELEM;
      end if;
      --
      --  The conses have been successfully allocated.  Now build the list.
      --
      BBS.lisp.cons_table(temp_cons).car := BBS.lisp.NIL_ELEM;
      BBS.lisp.cons_table(temp_cons).cdr := (kind => BBS.lisp.E_CONS, ps => press_cons);
      BBS.lisp.cons_table(press_cons).car := BBS.lisp.NIL_ELEM;
      BBS.lisp.cons_table(press_cons).cdr := BBS.lisp.NIL_ELEM;
      --
      --  Now, add the values to the list if they are present
      --
      if temp_flag then
            BBS.lisp.cons_table(temp_cons).car := (kind => BBS.lisp.E_VALUE,
                                                   v => (kind => BBS.lisp.V_INTEGER,
                                                         i => temperature));
      end if;
      if press_flag then
            BBS.lisp.cons_table(press_cons).car := (kind => BBS.lisp.E_VALUE,
                                                    v => (kind => BBS.lisp.V_INTEGER,
                                                          i => pressure));
      end if;
      return (kind => BBS.lisp.E_CONS, ps => temp_cons);
   end;
   --
   --  (set-pca9685 integer integer)
   --    The first integer is the channel number (0-15).  The second integer is
   --    the PWM value to set (0-4095).  Sets the specified PCA9685 PWM channel
   --    to the specified value.  Returns NIL.
   --
   function set_pca9685(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      err    : BBS.embed.i2c.err_code;
      chan_elem : BBS.lisp.element_type;
      value_elem  : BBS.lisp.element_type;
      channel : Integer;
      value : Integer;
      rest : BBS.lisp.element_type;
      ok : Boolean := True;
   begin
      --
      --  Get the first value
      --
      BBS.lisp.utilities.first_value(e, chan_elem, rest);
      --
      --  Get the second value
      --
      BBS.lisp.utilities.first_value(rest, value_elem, rest);
      --
      --  Check if the channel number value is an integer atom.
      --
      if chan_elem.kind = BBS.lisp.E_VALUE then
         if chan_elem.v.kind = BBS.lisp.V_INTEGER then
            channel := chan_elem.v.i;
         else
            BBS.lisp.error("set-pca9685", "PCA9685 channel must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pca9685", "PCA9685 channel must be an element.");
         BBS.lisp.print(chan_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the channel value is an integer atom.
      --
      if value_elem.kind = BBS.lisp.E_VALUE then
         if value_elem.v.kind = BBS.lisp.V_INTEGER then
            value := value_elem.v.i;
         else
            BBS.lisp.error("sset-pca9685", "PCA9685 channel value must be integer.");
            ok := False;
         end if;
      else
         BBS.lisp.error("set-pca9685", "PCA9685 channel value must be an atom.");
         BBS.lisp.print(value_elem, False, True);
         ok := False;
      end if;
      --
      --  Check if the channel number is within range of the valid pins.
      --
      if (channel < 0) or (channel > 15) then
         BBS.lisp.error("set-pca9685", "PCA9685 channel number is out of range.");
         ok := False;
      end if;
      --
      --  Check that the cannel value is within the range 0-4095.
      --
      if (value < 0) or (value > 4095) then
         BBS.lisp.error("set-pca9685", "PCA9685 channel value is out of range.");
         ok := False;
      end if;
      --
      --  If everything is OK, then set the channel
      --
      if ok then
         cli.PCA9685.set(BBS.embed.i2c.PCA9685.channel(channel), 0,
                         BBS.embed.uint12(value), err);
         if err /= BBS.embed.i2c.none then
            BBS.lisp.error("set-pca9685", "PCA9685 Error: " & BBS.embed.i2c.err_code'Image(err));
         end if;
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
end lisp;
