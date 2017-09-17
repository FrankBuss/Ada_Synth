# Ada_Synth
Ada Synthesizer with MIDI support.
Tested on Debian Linux and the STM32F407 Discovery board.

## Prerequisites
- STM32F4 Discovery board with STM32F407
- STLINK, install it like this:
```
cd
git clone https://github.com/texane/stlink.git
cd stlink
make release
cd build/Release
sudo make install
sudo ldconfig
```
- latest GNAT compiler for Linux and for ARM, download and install it from here: http://libre.adacore.com
- checkout these repositories:
```
git clone https://github.com/FrankBuss/Ada_Drivers_Library
git clone https://github.com/FrankBuss/ada-synth-lib
git clone https://github.com/FrankBuss/Ada_Synth
```

## Build and run the Linux version
See the comments in the file https://github.com/FrankBuss/Ada_Synth/blob/master/ada/linux/ada_synth.adb

## Build and run the ARM version
- connect the Discovery board. It should show up with `lsusb` as something like this:
```
Bus 001 Device 016: ID 0483:374b STMicroelectronics ST-LINK/V2.1 (Nucleo-F103RB)
```
- start gps
- open Ada_Synth/Ada/discovery/ada_synth.gpr
- click the "build all" button
- click on the "flash to board" button

When plug in a headphone in the audio jack of the Discovery board, you should hear a short chord at start. You can connect a digital 3 V MIDI-in signal to PB7, to play some notes with a MIDI piano.
