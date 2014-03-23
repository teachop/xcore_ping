##Ping Example Application Bargraph
The app bargraph demonstrates readings from the HC-SR04 ultrasonic ping sensor.  It reads the sensor and displays distance values on a bargraph in a whimsical way.  The bargraph is constructed from an [RGB LED strip](http://www.adafruit.com/products/1138) with 60 pixels, 1 meter long.

###Required Modules
For an xCore xC application, the required modules are listed in the Makefile:
- USED_MODULES = module_ping module_neopixel

The modules can be found [here](https://github.com/teachop/xcore_neopixel_buffered) and [here](https://github.com/teachop/xcore_ping).

###Wiring
On the startKIT J7 connector:
- J7.1 - trig_pin, output port to the sensor Trig input.
- J7.2 - echo_pin, input port from the sensor Echo output.
- J7.3 - led_pin, output port to the NeoPixel strand data.

**Note:** The sensor is 5V and the XCore part on the startKIT not 5V tolerant.  A voltage divider was used between the ECHO signal and the input port to avoid damage to the CPU from over-voltage.
