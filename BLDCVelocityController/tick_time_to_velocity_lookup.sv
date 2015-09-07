`define HARDWARE_MODULES_DIR(filepath) `"/home/poofjunior/Projects/HardwareModules/filepath`"

module TickTimeToVelocityLookup(
/// TODO: figure out bit width of input time_per_tick.
            input logic [13:0] time_per_tick,
/// TODO: figure out bit width of output velocity value.
           output logic [15:0] velocity);

(* ram_init_file = `HARDWARE_MODULES_DIR(BLDCVelocityController/velocity_lut.mif) *) logic [15:0] velocity_lut [0:2047];

assign velocity = velocity_lut[time_per_tick];


endmodule
