with cli;
use type cli.i2c_device_location;
with BBS.lisp;
use type BBS.lisp.ptr_type;
use type BBS.lisp.value_type;
use type BBS.lisp.int32;
with BBS.lisp.evaluate;
with BBS.embed;
with bbs.embed.i2c;
use type bbs.embed.i2c.err_code;
with BBS.embed.i2c.MCP23017;
package body lisp.mcp23017 is
   --
   --  Some helper functions.
   --
   --  Process the address parameter.
   --
   function process_address(p : BBS.lisp.element_type; device : out BBS.embed.i2c.MCP23017.MCP23017_record)
                            return Boolean is
      addr : BBS.lisp.int32;
   begin
      device := cli.MCP23017_0;
      if p.kind = BBS.lisp.E_VALUE then
         if p.v.kind = BBS.lisp.V_INTEGER then
            addr := p.v.i;
            if (addr = 0) and (cli.mcp23017_0_found /= cli.absent) then
               device := cli.MCP23017_0;
               return True;
            elsif (addr = 2) and (cli.mcp23017_2_found /= cli.absent) then
               device := cli.MCP23017_2;
               return True;
            elsif (addr = 6) and (cli.mcp23017_6_found /= cli.absent) then
               device := cli.MCP23017_6;
               return True;
            else
               BBS.lisp.error("process_address", "Address must be 0, 2, or 6.");
            end if;
         else
            BBS.lisp.error("process_address", "Address must be integer.");
         end if;
      else
         BBS.lisp.error("process_address", "Address must be an element.");
         BBS.lisp.print(p, False, True);
      end if;
      return False;
   end;
   --
   --  Process the data parameter.  This should always be a 16 bit unsigned integer
   --
   function process_data(p : BBS.lisp.element_type; data : out BBS.embed.uint16)
                         return Boolean is
   begin
      data := 0;
      if p.kind = BBS.lisp.E_VALUE then
         if p.v.kind = BBS.lisp.V_INTEGER then
            if p.v.i >= 0 and p.v.i <= 16#FFFF# then
               data := BBS.embed.uint16(p.v.i);
               return True;
            else
               BBS.lisp.error("process_data", "Data must be in range 0-#xFFFF.");
            end if;
         else
            BBS.lisp.error("process_data", "Data must be integer.");
         end if;
      else
         BBS.lisp.error("process_data", "Data must be an element.");
         BBS.lisp.print(p, False, True);
      end if;
      return False;
   end;

   --
   --  Set direction of bits in the MCP23017 port.
   --  (mcp23017-set-dir addr dir)
   --    addr is the device address
   --    dir is the direction (0-read, 1-write) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_dir(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      param : BBS.lisp.element_type;
      data : BBS.embed.uint16;
      MCP23017 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
      err    : BBS.embed.i2c.err_code;
   begin
      --
      --  Process the first parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_address(param, MCP23017) then
         BBS.lisp.error("mcp23017-dir", "Error occured processing address parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Process the second parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_data(param, data) then
         BBS.lisp.error("mcp23017-dir", "Error processing data parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Both parameters are valid and in range.  Perform the function
      --
      MCP23017.set_dir(data, err);
      if err = BBS.embed.i2c.none then
--         data := MCP23017.get_dir(err);
--         if err = BBS.embed.i2c.none then
            return (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER,
                                                 i => BBS.lisp.int32(data)));
--         end if;
--         BBS.lisp.error("mcp23017-dir", "Error getting direction: " &
--                       BBS.embed.i2c.err_code'Image(err));
--         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.error("mcp23017-dir", "Error setting direction: " &
                       BBS.embed.i2c.err_code'Image(err));
      return (kind => BBS.lisp.E_ERROR);
   end;
   --
   --  Enable/disable pull-up resistors for bits in the MCP23017 port.
   --  (mcp23017-pullup addr pull)
   --    addr is the device address
   --    dir is the pullup setting (0-disable, 1-enable) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_pullup(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      param : BBS.lisp.element_type;
      data : BBS.embed.uint16;
      MCP23017 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
      err    : BBS.embed.i2c.err_code;
   begin
      --
      --  Process the first parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_address(param, MCP23017) then
         BBS.lisp.error("mcp23017-pullup", "Error occured processing address parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Process the second parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_data(param, data) then
         BBS.lisp.error("mcp23017-pullup", "Error processing data parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Both parameters are valid and in range.  Perform the function
      --
      MCP23017.set_pullup(data, err);
      if err = BBS.embed.i2c.none then
--         data := MCP23017.get_pullup(err);
--         if err = BBS.embed.i2c.none then
            return (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER,
                                                 i => BBS.lisp.int32(data)));
--         end if;
--         BBS.lisp.error("mcp23017-pullup", "Error getting pullup: " &
--                       BBS.embed.i2c.err_code'Image(err));
--         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.error("mcp23017-pullup", "Error setting pullup: " &
                       BBS.embed.i2c.err_code'Image(err));
      return (kind => BBS.lisp.E_ERROR);
   end;
   --
   --  Set polarity of bits in the MCP23017 port.
   --  (mcp23017-set-dir addr pol)
   --    addr is the device address
   --    pol is the polarity (0-normal, 1-inverted) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_polarity(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      param : BBS.lisp.element_type;
      data : BBS.embed.uint16;
      MCP23017 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
      err    : BBS.embed.i2c.err_code;
   begin
      --
      --  Process the first parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_address(param, MCP23017) then
         BBS.lisp.error("mcp23017-polarity", "Error occured processing address parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Process the second parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_data(param, data) then
         BBS.lisp.error("mcp23017-polarity", "Error processing data parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Both parameters are valid and in range.  Perform the function
      --
      MCP23017.set_polarity(data, err);
      if err = BBS.embed.i2c.none then
--         data := MCP23017.get_polarity(err);
--         if err = BBS.embed.i2c.none then
            return (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER,
                                                 i => BBS.lisp.int32(data)));
--         end if;
--         BBS.lisp.error("mcp23017-polarity", "Error getting polarity: " &
--                       BBS.embed.i2c.err_code'Image(err));
--         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.error("mcp23017-polarity", "Error setting polarity: " &
                       BBS.embed.i2c.err_code'Image(err));
      return (kind => BBS.lisp.E_ERROR);
   end;
   --
   --  Set output data of bits in the MCP23017 port.
   --  (mcp23017-write addr data)
   --    addr is the device address
   --    data is the output value as a 16 bit unsigned integer
   --
   function mcp23017_data(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      param : BBS.lisp.element_type;
      data : BBS.embed.uint16;
      MCP23017 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
      err    : BBS.embed.i2c.err_code;
   begin
      --
      --  Process the first parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_address(param, MCP23017) then
         BBS.lisp.error("mcp23017-data", "Error occured processing address parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Process the second parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_data(param, data) then
         BBS.lisp.error("mcp23017-data", "Error processing data parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      --
      --  Both parameters are valid and in range.  Perform the function
      --
      MCP23017.set_data(data, err);
      if err = BBS.embed.i2c.none then
--         data := MCP23017.get_data(err);
--         if err = BBS.embed.i2c.none then
            return (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER,
                                                 i => BBS.lisp.int32(data)));
--         end if;
--         BBS.lisp.error("mcp23017-data", "Error getting data: " &
--                       BBS.embed.i2c.err_code'Image(err));
--         return (kind => BBS.lisp.E_ERROR);
      end if;
      BBS.lisp.error("mcp23017-data", "Error setting data: " &
                       BBS.embed.i2c.err_code'Image(err));
      return (kind => BBS.lisp.E_ERROR);
   end;
   --
   --  Read data from a MCP23017 port
   --  (mcp23017-read addr)
   --    addr is the device address
   --    returns the bits read as a 16 bit unsigned integer
   --
   function mcp23017_read(e : BBS.lisp.element_type) return BBS.lisp.element_type is
      rest : BBS.lisp.element_type := e;
      param : BBS.lisp.element_type;
      data : BBS.embed.uint16;
      MCP23017 : aliased BBS.embed.i2c.MCP23017.MCP23017_record;
      err    : BBS.embed.i2c.err_code;
   begin
      --
      --  Process the first parameter.
      --
      param := BBS.lisp.evaluate.first_value(rest);
      if not process_address(param, MCP23017) then
         BBS.lisp.error("mcp23017-data", "Error occured processing address parameter");
         return (kind => BBS.lisp.E_ERROR);
      end if;
      data := mcp23017.get_data(err);
      if err = BBS.embed.i2c.none then
         return (kind => BBS.lisp.E_VALUE, v => (kind => BBS.lisp.V_INTEGER,
                                                 i => BBS.lisp.int32(data)));
      end if;
      BBS.lisp.error("mcp23017-read", "Error getting data: " &
                       BBS.embed.i2c.err_code'Image(err));
      return (kind => BBS.lisp.E_ERROR);
   end;
end;
