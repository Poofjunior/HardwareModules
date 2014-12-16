Hardware Modules
================

A collection of hardware modules for FPGA development.

These have been implemented on a Cyclone IV from a DE0 Nano, though the 
SystemVerilog files are currently platform (manufacturer) independent.

## Usage
Currently, each folder should contain a project that runs independently. Some
projects reference some (or all) files in other projects. To get around a 
single user-specific file-path structure, the file: _filepaths.sv_ contains a 
macro that contains the file path to this directory (where this README.md is 
located).

![pinout](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/DE0Nano_some_pins.png)

A Feel free to cut out the pinout diagram on a laser cutter to replace the 
original dust shield. (.svg file is the unaltered original)

### udev Rules (if developing on a Linux Machine)
[udev rules](https://gist.github.com/gmarkall/6f0a1c16476e8e0a9026)
