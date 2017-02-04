Turris Omnia I2C LCD example program
====================================
This program was created as an presentation program for FOSDEM 2017. It contains C
program handling 20x4 LCD display connected trough I2C (3.3 to 5 volts shift is
required), accepting input from fifo /tmp/turris-lcd.

Another part of this is web. In `web` directory there is lighttpd configuration
and website, that allows LCD input trough web.
