with BBS.embed.GPIO.Due;

package discretes is
   max_pin : Natural := 53;
   pin : array (0 .. max_pin) of BBS.embed.GPIO.Due.Due_GPIO_ptr;

   procedure init;
end;
