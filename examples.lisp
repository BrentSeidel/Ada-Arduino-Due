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
(setq pin 0)
(setq value 0)
(dowhile (< pin 8)
  (setq value 0)
  (dowhile (< value 4095)
    (set-pca9685 pin value)
    (setq value (+ value 10)))
  (setq pin (+ pin 1)))
