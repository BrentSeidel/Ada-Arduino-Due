package lisp.mcp23017 is

   --
   --  Set direction of bits in the MCP23017 port.
   --  (mcp23017-dir addr dir)
   --    addr is the device address
   --    dir is the direction (0-read, 1-write) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_dir(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  Enable/disable pull-up resistors for bits in the MCP23017 port.
   --  (mcp23017-pullup addr pull)
   --    addr is the device address
   --    dir is the pullup setting (0-disable, 1-enable) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_pullup(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  Set polarity of bits in the MCP23017 port.
   --  (mcp23017-set-dir addr pol)
   --    addr is the device address
   --    pol is the polarity (0-normal, 1-inverted) bit encoded into a 16 bit
   --      unsigned integer
   --
   function mcp23017_polarity(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  Set output data of bits in the MCP23017 port.
   --  (mcp23017-write addr data)
   --    addr is the device address
   --    data is the output value as a 16 bit unsigned integer
   --
   function mcp23017_data(e : BBS.lisp.element_type) return BBS.lisp.element_type;
   --
   --  Read data from a MCP23017 port
   --  (mcp23017-read addr)
   --    addr is the device address
   --    returns the bits read as a 16 bit unsigned integer
   --
   function mcp23017_read(e : BBS.lisp.element_type) return BBS.lisp.element_type;

end;
