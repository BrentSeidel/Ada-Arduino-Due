# Ada-Arduino-Due
I now have Ada running on my Arduino Due.  This comes without all the infrastructure that
the Arduino development environment provides.  So some research is in order.

This should be considered a working repository.  As functions get developed, they will
probably migrate to either my BBS-BBB-Ada repository or to the AdaCore Ada_Drivers_library
repository.

## Current Status

### General Purpose I/O
Pins can be configured as digital ouptuts or to support alternate (UART)
functions.  Digital input should work, but hasn't yet been tested.  Since the
on-board LED is connected to one of the GPIO pins, it can be flashed.

### Serial ports
The serial driver supports all four available serial ports on the Arduino Due.
Transmit and Receive is supported by both polled and interrupt driven drivers.
The interrupt driven driver also supports RS-485 mode, character echo, and
backspace and delete keys.  This should provide the basics for both console I/O
as well as serial communication with other devices.

### I2C
I2C reads are interrupt driven.  I2C writes only have a single byte write that
is partially polled.  These are also available in an object oriented version.
The write needs to be converted to fully interrupt driven and a block write added.

The interface is moving in the direction of the I2C interface in BBS-BBB-Ada,
though some changes will probably be required there.  Once the interfaces match,
all the I2C devices from BBS-BBB-Ada should work.

A BME280 is used for testing and some functions are working.  Note that 64 bit
arithmatic is required for the BME280.

### Analogs
Initial version of analog inputs is available.  Note that the internal channel
numbers don't match the Arduino pin numbers.  Since 16 channels are defined and
only 12 are actually used, there are four unused channels.  Enabling one of them
seems to cause problems with the I2C interface and with tasking.

Analog outputs are working on both channels.  Note that currently analog inputs
operate in the free running mode and analog outputs use a polled wait.  This
will probably be enhanced sometime in the future.

### Tasking
Moved the LED flasher into a separate task - multiple tasks are working.

### Lisp
The Tiny-Lisp interpreter has been incorporated and operations have been created
for accessing some of the hardware.  These can be used as examples for creating
your own.

The (peek) and (poke) operations have been tested.  Using (poke) to set discrete
output values with:
1. (dowhile (= 1 1) (set-pin 25 0) (set-pin 25 1))
2. (dotimes (n 1000000) (set-pin 25 0) (set-pin 25 1))
3. (defun set-25 (value)
    (if (= 0 value)
      (poke32 #x400E1434 #x01)
      (poke32 #x400E1430 #x01)))
  (defun toggle (count)
    (pin-mode 25 1)
    (dotimes (n count)
      (set-25 0)
      (set-25 1)))
4. (defun toggle (count)
     (pin-mode 25 1)
     (dotimes (n count) (poke32 #x400E1434 #x01) (poke32 #x400E1430 #x01)))

Measuring discretes with an oscilloscope,
1. dowhile toggles about 10kHz
2. dotimes toggles about 15kHz
3. toggles about 3kHz
4. toggles about 15hKz
0. A similar loop in Ada was measured about 384kHz

The timing differences should give a little idea of the overhead of different
Lisp operations.

## Command Line
You can login by typing anything as the user name and "override" as the password.
The user name will be used as a command prompt.  Internally, all commands are
converted to upper case before processing.  At the command line, there are
some commands that may or may not be useful:
* LOGOUT, LOGOFF, BYE - These commands all return to the username prompt.
* FLASH &lt;number&gt; - Sets the number of times the LED flashes
* EXIT, QUIT - Don't do much
* INFO - Prints the CPU info
* HELP - Doesn't help
* SERIAL - Sends a message out on serial lines 1, 2, and 3.
* ANALOG <number> - Prints values of the analog inputs and cycles analog outputs
* I2C - I2C related commands
* STOP - Stops tasks
* START - Starts tasks
* GPIO - GPIO related commands
* STATUS - Prints system status
* LISP - Enters the Tiny Lisp interpreter.

## Lisp
The following Lisp operations are added.
* (due-flash &lt;number&gt;) - Sets number of times for LED to flash
* (set-pin &lt;pin number&gt; &lt;state 0 or 1&gt;) - Sets digital output pin to specified level
* (pin-mode &lt;pin number&gt; &lt;mode 0 or 1&gt;) - Sets digital pin 0 = input, 1 = output
* (read-pin &lt;pin number&gt;) - Returns the state of a digital pin
* (read-analog &lt;analog input&gt;) - Returns the value of an analog input
* (info-enable) - Turns on some debugging information
* (info-disable) - Turns off some debugging information
* (read-bmp180) - Returns temperature (in tenth of a degree C) and pressure
  (in Pascals) from BMP180 sensor
* (set-pca9685 &lt;pin&gt; &lt;value&gt;) - Sets PWM value for the specified PCA9685 pin.
* (read-l3gd20) - Returns x, y, and z rotation rates in tenth of a degree per second.

## Dependencies
The material in this repository depends on the following other repositories:
* https://github.com/BrentSeidel/BBS-Ada - The root of all my Ada packages
* https://github.com/BrentSeidel/bb-runtimes - The Ada runtime for the Arduino Due.  This
  should get folded in to AdaCore's bb-runtimes, but it is unclear when or if it will
  ever happen.
* https://github.com/BrentSeidel/BBS-BBB-Ada - Device drivers in Ada for a number of
  devices.
* https://github.com/BrentSeidel/Things - Definitions for 3D printed objects.  Only
  needed if you want to 3D print items.

## License
This software is available under GPL 3.  If you wish to use it under another license,
please contact the author.  Note that the files with the names sam3x8s*.ads have been
autogenerated from the SAM3X8S SVD file, with some minor modifications.  I have no
claims to these file.
