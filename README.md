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
Basic polled I2C interface is working.  Some cleanup is still probably needed.  A
BME280 is used for testing and some functions are working.  Note that 64 bit
arithmatic is required for this.

### Analogs
Initial version of analog inputs is available.  Note that the internal channel
numbers don't match the Arduino pin numbers.  Since 16 channels are defined and
only 12 are actually used, there are four unused channels.  Enabling one of them
seems to cause problems with the I2C interface and with tasking.

### Tasking
Moved the LED flasher into a separate task - multiple tasks are working.

## License
This software is available under GPL 3.  If you wish to use it under another license,
please contact the author.  Note that the files with the names sam3x8s*.ads have been
autogenerated from the SAM3X8S SVD file, with some minor modifications.  I have no
claims to these file.
