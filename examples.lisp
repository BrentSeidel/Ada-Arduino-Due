;
;  Example Lisp code and functions for the Ada Lisp interpreter running on the
;  Arduino Due.  These examples show how to use some of the special hardware
;  interface operations on the Due.
;
;  Digital pin commands.  Pin 10 in input, pins 11 and 12 are outputs.  Toggles
;  pins 11 and 12 as long as pin 10 is held high.
;
(pin-mode 10 0)
(pin-mode 11 1)
(pin-mode 12 1)
(dowhile (= (read-pin 10) (+ 0 1))
  (set-pin 11 0)
  (set-pin 12 1)
  (set-pin 11 1)
  (set-pin 12 0))
;
;  Read an analog pin and print the value repeatedly.
;  Digital pin 10 is tied high to keep looping and tied low to exit the loop.
;
(defun monitor-analog (n)
  (pin-mode 10 0)
  (print "Connect digital pin 10 to high to continue looping or to gnd to exit")
  (terpri)
  (print "Connect analog pin " n " to the analog value to monitor")
  (terpri)
  (print "Press <return> to continue")
  (read-line)
  (dowhile (= (read-pin 10) (+ 0 1))
    (print "Analog value is " (read-analog n))
    (terpri)
    (set-pca9685 15 (read-analog n)))
  (print "Exiting")
  (terpri))
;
;  LEDs are hooked up to channels 0-7 of the PCA9685.  This sets all LEDs to the
;  same value.
;
(setq pin 0)
(setq value 0)
(setq count 0)
;
(defun set-leds (n)
  (setq pin 0)
  (dowhile (< pin 8)
    (set-pca9685 pin n)
    (setq pin (+ pin 1))))
;
;  Rewritten to use dotimes
;
(defun set-leds (n)
  (dotimes (pin 8)
    (set-pca9685 pin n)))
;
;  Cycle the LEDs, turn them on one by one and then off one by one.
;
(defun cycle-leds (n)
  (setq count 0)
  (dowhile (< count n)
    (print "Starting cycle " count)
    (terpri)
    (setq count (+ count 1))
    (set-leds 0)
    (setq pin 0)
    (setq value 0)
    (dowhile (< pin 8)
      (setq value 0)
      (dowhile (< value 4095)
        (set-pca9685 pin value)
        (setq value (+ value 100)))
      (setq pin (+ pin 1)))
    (setq pin 0)
    (setq value 4095)
    (dowhile (< pin 8)
      (setq value 4095)
      (dowhile (> value 0)
        (set-pca9685 pin value)
        (setq value (- value 100)))
      (setq pin (+ pin 1)))
    (set-leds 0)))
;
;  Rewritten to use dotimes
;
(defun cycle-leds (n)
  (dotimes (count n)
    (print "Starting cycle " count)
    (terpri)
    (set-leds 0)
    (dotimes (pin 8)
      (setq value 0)
      (dowhile (< value 4095)
        (set-pca9685 pin value)
        (setq value (+ value 100))))
    (setq value 4095)
    (dotimes (pin 8)
      (setq value 4095)
      (dowhile (> value 0)
        (set-pca9685 pin value)
        (setq value (- value 100))))
    (set-leds 0)))
;
;  Cycle the LEDs using sleep time set by analog input 1
;
(defun cycle-leds (n)
  (dotimes (count n)
    (print "Starting cycle " count)
    (terpri)
    (set-leds 0)
    (dotimes (pin 8)
      (set-pca9685 pin 4095)
      (sleep (read-analog 1)))
    (dotimes (pin 8)
      (set-pca9685 pin 0)
      (sleep (read-analog 1)))
    (set-leds 0)))
;
(setq pin 0)
(setq value 0)
(dowhile (< pin 8)
  (setq value 0)
  (dowhile (< value 4095)
    (set-pca9685 pin value)
    (setq value (+ value 10)))
  (setq pin (+ pin 1)))
;
;  Test PEEK operation by reading analog inputs.  The 16 Analog Channel Data
;  Registers start at address #x400C0050 and are four bytes wide.  Only the
;  12 least significan bits are used so a PEEK16 is used to read the address.
;
;  Important Note:  The analog channel numbers do not match the numbers on the
;  Arduino Due connectors.
;  Pin  Chan
;   0     7
;   1     6
;   2     5
;   3     4
;   4     3
;   5     2
;   6     1
;   7     0
;   8    10
;   9    11
;  10    12
;  11    13
;
(defun ain (chan)
    (peek16 (+ #x400C0050 (* chan 4))))
;
;  Try to toggle Arduino Pin 11.
;     pin11_rec : ctrl => BBS.embed.GPIO.Due.PIOC'Access, bit => 29
;   procedure set(self : Due_GPIO_record; val : Bit) is
;   begin
;      if val = 1 then
;         self.ctrl.SODR.Arr(self.bit) := 1;
;      else
;         self.ctrl.CODR.Arr(self.bit) := 1;
;      end if;
;   end;
;
;  PIOA base address: #x400E0E00
;  PIOB base addressL #x400E1000
;  PIOC base address: #x400E1200
;  PIOD base address: #x400E1400
;  PIOE base addressL #x400E1500
;  PIOF base address: #x400E1600
;  SODR offset: #x0030
;  CODR offset: #x0034
;
(defun set-25 (value)
  (if (= 0 value)
    (poke32 #x400E1434 #x01)
    (poke32 #x400E1430 #x01)))

(defun toggle (count)
  (pin-mode 25 1)
  (dotimes (n count)
    (set-25 0)
    (set-25 1)))
;
;  Measuring discretes with an oscilloscope,
;  (dowhile (= 1 1) (set-pin 25 0) (set-pin 25 1)) toggles about 10kHz
;  (dotimes (n 1000000) (set-pin 25 0) (set-pin 25 1)) toggles about 15kHz
;  (toggle 10000) toggles about 3kHz
;
;
;  Read an analog pin and display the upper 7 bits of the binary value in LEDs.
;  Digital pin 0 is tied high to keep looping and tied low to exit the loop.
;
(defun monitor-analog (ana ctrl)
  (let (value)
    (dowhile (> (read-pin ctrl) 0)
      (setq value (read-analog ana))
      (if (= 0 (and value #x0800))
        (set-pca9685 6 0)
        (set-pca9685 6 #x0FFF))
      (if (= 0 (and value #x0400))
        (set-pca9685 5 0)
        (set-pca9685 5 #x0FFF))
      (if (= 0 (and value #x0200))
        (set-pca9685 4 0)
        (set-pca9685 4 #x0FFF))
      (if (= 0 (and value #x0100))
        (set-pca9685 3 0)
        (set-pca9685 3 #x0FFF))
      (if (= 0 (and value #x0080))
        (set-pca9685 2 0)
        (set-pca9685 2 #x0FFF))
      (if (= 0 (and value #x0040))
        (set-pca9685 1 0)
        (set-pca9685 1 #x0FFF))
      (if (= 0 (and value #x0020))
        (set-pca9685 0 0)
        (set-pca9685 0 #x0FFF))))
  (print "Exiting")
  (terpri))
;
;  Stuff for the MCP23017.
;    Address 0 is LEDs
;    Address 2 is switches
;
;  Test for installed LEDs.
;  Set the LED discretes to inputs, enable the pullup resistors, and read
;  the values.  If no LED is installed, that bit should have a high (1) value
;  while if an LED is installed, there should be a low value.  Note that if
;  an input is shorted or otherwise pulled to ground, it will show as an installed
;  LED.
;
(defun installed-leds ()
  (mcp23017-dir 0 #xffff)
  (mcp23017-pullup 0 #xffff)
  (print "Uninstalled LEDs at bits " (mcp23017-read 0))
  (mcp23017-dir 0 0)
  (mcp23017-data 0 #xffff))
;
;  Setup MCP23017 #0 as output and #2 as input.  Discrete pins 51 and 52 are set
;  as outputs.
;
(defun setup ()
  (mcp23017-dir 0 0)
  (sleep 10)
  (mcp23017-dir 2 #xffff)
  (sleep 10)
  (pin-mode 50 0)
  (pin-pullup 50 t)
  (pin-mode 51 1)
  (pin-mode 52 0)
  (pin-pullup 52 t)
  (pin-mode 53 1))
;
;  Counts on the LEDs.
;
(defun count (time)
  (dotimes (x 65536)
    (mcp23017-data 0 x)
    (sleep time)))
;
;  Copies the switch value to the LEDs.
;
(defun copy (time)
  (let ((switch))
    (dowhile t
      (setq switch (mcp23017-read 2))
      (mcp23017-data 0 switch)
      (sleep time))))
;
;  Cycle LEDs for MCP23017 - upper 8 bits
;  Cycles the lights from right to left.
;
(defun cycle-leds (n)
  (let (value)
    (dotimes (count n)
      (mcp23017-data 0 0)
      (setq value 128)
      (dotimes (x 8)
        (setq value (* value 2))
        (mcp23017-data 0 value)
        (sleep 50))))
  (mcp23017-data 0 0))
;
;  Cycles the LEDs from right to left and then back.  Stop when the switches
;  return 0.  Updated for all 16 switches and LEDs.  The lower 12 bits of the
;  switch register sets the delay time in mS.  The upper bit is an exit flag.
;
(defun bounce ()
  (let ((v1) (v2) (switch) (delay))
    (setq switch (mcp23017-read 2))
    (setq delay (and switch #x0fff))
    (print "Delay set to " delay "mS")
    (terpri)
    (dowhile (= (and switch #x8000) 0)
      (setq v1 #x0001)
      (setq v2 #x8000)
      (dotimes (x 8)
        (mcp23017-data 0 (or v1 v2))
        (setq v1 (* v1 2))
        (setq v2 (/ v2 2))
        (sleep delay))
      (setq v1 #x0080)
      (setq v2 #x0100)
      (dotimes (x 8)
        (mcp23017-data 0 (or v1 v2))
        (setq v1 (/ v1 2))
        (setq v2 (* v2 2))
        (sleep delay))
      (setq switch (mcp23017-read 2))
      (setq delay (and switch #x0fff)))
  (mcp23017-data 0 0)
  (mcp23017-read 2)))
;
;  An example test function.  This just checks for GPIO bit 52 to be set.
;
(defun test-exit ()
  (= (read-pin 52) 1))
(defun run ()
  (= (read-pin 52) 1))
(defun run ()
  (= (read-pin 52) 0))

;
;  An example work function.  This reads analog input 2 and sleeps for a tenth
;  of that value.
;
(defun example-work ()
  (sleep (/ (read-analog 2) 10)))
;
;  A more elaborate work function.  This checks the light level on analog
;  channel 1.  If above a threshold, set the PWM channel output to the value
;  from analog channel 3.  Then sleep for a tenth of the value of ananlog
;  channel 2 in mS.
;
(defun example-work2 ()
  (if (> (read-analog 1) 64)
    (set-pca9685 15 (read-analog 3)))
  (sleep (/ (read-analog 2) 10)))
;
(defun example-work2 ()
  (if (> (read-analog 1) 64)
    (set-pin 51 0)
    (set-pin 51 1))
  (if (> (read-analog 1) 128)
    (set-pin 53 0)
    (set-pin 53 1))
  (sleep (/ (read-analog 2) 10)))
;
;  Bounce calling functions.
;
(defun bounce ()
  (let ((value))
    (dowhile (test-exit)
      (mcp23017-data 0 0)
      (setq value 128)
      (dotimes (x 8)
        (setq value (* value 2))
        (mcp23017-data 0 value)
        (example-work))
      (setq value #x10000)
      (dotimes (x 8)
        (setq value (/ value 2))
        (mcp23017-data 0 value)
        (example-work))))
  (mcp23017-data 0 0)
  (mcp23017-read 2))
;
;  Bounce using lambdas.  Functions passed in for the test to continue processing
;  and the work.
;
(defun bounce (test-fun work-fun)
  (let ((v1) (v2))
    (dowhile (test-fun)
      (mcp23017-data 0 0)
      (setq v1 #x0001)
      (setq v2 #x8000)
      (dotimes (x 8)
        (mcp23017-data 0 (or v1 v2))
        (setq v1 (* v1 2))
        (setq v2 (/ v2 2))
        (work-fun))
      (setq v1 #x0080)
      (setq v2 #x0100)
      (dotimes (x 8)
        (mcp23017-data 0 (or v1 v2))
        (setq v1 (/ v1 2))
        (setq v2 (* v2 2))
        (work-fun))))
  (mcp23017-data 0 0)
  (mcp23017-read 2))
;
;  Example command
;
(bounce (lambda () (test-exit)) (lambda () (example-work2)))
;
;  Display values.  This can be used to display sensor values on the LEDs for
;  test purposes.
;
(defun display-val (test-fun work-fun)
  (let ((temp))
    (dowhile (test-fun)
      (setq temp (work-fun))
      (mcp23017-data 0 temp)
      (sleep 10))))
;
;  Examples to read the analog inputs.  Right now the following are configured:
:  0 - No connection
;  1 - Phototransistor
;  2 - Potentiometer
;  3 - Potentiometer
;  4-11 - No connection
;
;
(defun analog (n)
  (sleep 10)
  (read-analog n))

(display-val (lambda () (test-exit)) (lambda () (analog 1)))
(display-val (lambda () (test-exit)) (lambda () (analog 2)))
(display-val (lambda () (test-exit)) (lambda () (analog 3)))

;
;
;  Example of a lambda as a condition.
;
(setq *value* 10)

(defun test-example ()
  (setq *value* (- *value* 1))
  (< 0 *value*))

(defun test-work ()
  (print "Value is " *value*)
  (terpri))

(defun test-lam (test-func work-func)
  (dowhile (test-func) (work-func)))

(test-lam (lambda () (test-example)) (lambda () (test-work)))


