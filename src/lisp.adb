with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
with BBS.lisp.evaluate;
with BBS.embed;
with BBS.embed.due.serial.int;
with BBS.embed.ain.due;
with utils;
with lisp.bme280;
with lisp.bmp180;
with lisp.gpio;
with lisp.l3gd20;
with lisp.mcp23017;
with lisp.pca9685;
with lisp.stepper;

package body lisp is
   --
   --  Initialize the lisp interpreter and install custom lisp commands
   --
   --
   procedure init is
   begin
      BBS.lisp.init(BBS.embed.due.serial.int.Put_Line'Access,
                    BBS.embed.due.serial.int.Put'Access,
                    BBS.embed.due.serial.int.New_Line'Access,
                    BBS.embed.due.serial.int.Get_Line'Access);
      BBS.lisp.add_builtin("due-flash", due_flash'Access);
      BBS.lisp.add_builtin("set-pin", lisp.gpio.set_pin'Access);
      BBS.lisp.add_builtin("pin-mode", lisp.gpio.pin_mode'Access);
      BBS.lisp.add_builtin("pin-pullup", lisp.gpio.pin_pullup'Access);
      BBS.lisp.add_builtin("read-pin", lisp.gpio.read_pin'Access);
      BBS.lisp.add_builtin("read-analog", read_analog'Access);
      BBS.lisp.add_builtin("info-enable", info_enable'Access);
      BBS.lisp.add_builtin("info-disable", info_disable'Access);
      BBS.lisp.add_builtin("read-bme280", lisp.bme280.read_bme280'Access);
      BBS.lisp.add_builtin("read-bme280-raw", lisp.bme280.read_bme280_raw'Access);
      BBS.lisp.add_builtin("read-bmp180", lisp.bmp180.read_bmp180'Access);
      BBS.lisp.add_builtin("read-l3gd20", lisp.l3gd20.read_l3gd20'Access);
      BBS.lisp.add_builtin("set-pca9685", lisp.pca9685.set_pca9685'Access);
      BBS.lisp.add_builtin("mcp23017-dir", lisp.mcp23017.mcp23017_dir'Access);
      BBS.lisp.add_builtin("mcp23017-pullup", lisp.mcp23017.mcp23017_pullup'Access);
      BBS.lisp.add_builtin("mcp23017-polarity", lisp.mcp23017.mcp23017_polarity'Access);
      BBS.lisp.add_builtin("mcp23017-data", lisp.mcp23017.mcp23017_data'Access);
      BBS.lisp.add_builtin("mcp23017-read", lisp.mcp23017.mcp23017_read'Access);
      BBS.lisp.add_builtin("stepper-init", lisp.stepper.stepper_init'Access);
      BBS.lisp.add_builtin("stepper-delay", lisp.stepper.stepper_delay'Access);
      BBS.lisp.add_builtin("stepper-off", lisp.stepper.stepper_off'Access);
      BBS.lisp.add_builtin("step", lisp.stepper.stepper_step'Access);
   end;
   --
   --  Functions for custom lisp commands for the Arduino Due
   --
   --
   --  Simple lisp function to set the number of times to quickly flash the LED.
   --
   function due_flash(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      rest : BBS.lisp.element_type := e;
   begin
      --
      --  Get the first value
      --
      param := BBS.lisp.evaluate.first_value(rest);
      --
      --  Check if the first value is an integer element.
      --
      if param.kind = BBS.lisp.E_VALUE then
         if param.v.kind = BBS.lisp.V_INTEGER then
            utils.flash_count := Integer(param.v.i);
         else
            BBS.lisp.error("due-flash", "Parameter must be integer.");
         end if;
      else
         BBS.lisp.error("due-flash", "Parameter must be an element.");
         BBS.lisp.print(param, False, True);
      end if;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Read the value of one of the analog inputs.
   --
   function read_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      param : BBS.lisp.element_type;
      pin : Integer;
      rest : BBS.lisp.element_type := e;
      el : BBS.lisp.element_type;
      value : BBS.embed.uint12;
      ok : Boolean := True;
      ain  : BBS.embed.AIN.due.Due_AIN_record;
   begin
      --
      --  Get the first value
      --
      param := BBS.lisp.evaluate.first_value(rest);
      --
      --  Check if the first value is an integer element.
      --
      if param.kind = BBS.lisp.E_VALUE then
         if param.v.kind = BBS.lisp.V_INTEGER then
            pin := Integer(param.v.i);
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
         BBS.lisp.error("read-analog", "Parameter must be an element.");
         BBS.lisp.print(param, False, True);
      end if;
      --
      --  If the parameter is an integer and in range, then read the pin and try
      --  to return the value.
      --
      if ok then
         ain.channel := pin;
         value := ain.get;
         el := (Kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER, i => BBS.lisp.int32(value)));
      else
         el := (kind => BBS.lisp.E_ERROR);
      end if;
      return el;
   end;
   --
   --
   --  Read the value of one of the analog inputs.
   --
   function set_analog(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pragma Unreferenced (e);
   begin
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Enable display of info messages
   --
   function info_enable(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pragma Unreferenced (e);
   begin
      utils.info.enable;
      return BBS.lisp.NIL_ELEM;
   end;
   --
   --  Disable display of info messages
   --
   function info_disable(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      pragma Unreferenced (e);
   begin
      utils.info.disable;
      return BBS.lisp.NIL_ELEM;
   end;
   --
end lisp;
