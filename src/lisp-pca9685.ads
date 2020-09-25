with BBS.lisp;
package lisp.pca9685 is
   --
   --  (set-pca9685 integer integer)
   --    The first integer is the channel number (0-15).  The second integer is
   --    the PWM value to set (0-4095).  Sets the specified PCA9685 PWM channel
   --    to the specified value.  Returns NIL.
   --
   function set_pca9685(e : BBS.lisp.element_type) return BBS.lisp.element_type;
end;
