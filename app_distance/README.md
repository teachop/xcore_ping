##Ping Example Application
The app distance demonstrates readings from the HC-SR04 ultrasonic ping sensor.  It reads the sensor and displays distance values on a serial [display](https://github.com/sparkfun/Serial7SegmentDisplay/wiki/Serial-7-Segment-Display-Datasheet) using the asynchronous serial option (9600 Baud **RX** input).

###Required Modules
For an xCore xC application, the required modules are listed in the Makefile:
- USED_MODULES = module_ping module_seven_seg

The modules can be found [here](https://github.com/teachop/xcore_ping) and [here](https://github.com/teachop/xcore_seven_seg).

###Wiring
On the startKIT J7 connector:
- **J7.10** - trig_pin, output port to the sensor Trig input.
- **J7.11** - echo_pin, input port from the sensor Echo output.
- **J7.5** - txd_pin, output port to the display rx data.

These port assignments can be easily customized as desired by editing the declarations located just before main() in the app_distance.c file.

**Note:** The sensor is 5V and the XCore part on the startKIT not 5V tolerant.  A voltage divider was used between the ECHO signal and the input port to avoid any possible damage to the CPU from over-voltage.
