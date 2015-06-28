module fastModulo1170(
            input logic clk, reset,
            input logic [12:0] encoder_input,
           output logic [12:0] input_mod_1170);

logic greater_than_1170;
logic greater_than_2340;
logic greater_than_3510;
logic greater_than_4680;
logic greater_than_5850;
/// TODO: make sure 1171 entries exist in the lookup table.
logic greater_than_7021;

logic [12:0] subtrahend;

logic [5:0] priority_vector;
assign priority_vector[5:0] = {greater_than_7021, greater_than_5850,
                               greater_than_4680, greater_than_3510,
                               greater_than_2340, greater_than_1170};

assign greater_than_1170 = encoder_input > 1170;
assign greater_than_2340 = encoder_input > 2340;
assign greater_than_3510 = encoder_input > 3510;
assign greater_than_4680 = encoder_input > 4680;
assign greater_than_5850 = encoder_input > 5850;
assign greater_than_7021 = encoder_input > 7021;


always_comb
begin
    casez (priority_vector)
        'b000000: subtrahend[12:0] = 0;
        'b000001: subtrahend[12:0] = 1170;
        'b00001?: subtrahend[12:0] = 2340;
        'b0001??: subtrahend[12:0] = 3510;
        'b001???: subtrahend[12:0] = 4680;
        'b01????: subtrahend[12:0] = 5850;
        'b1?????: subtrahend[12:0] = 7021;
    default: subtrahend = 0;
    endcase
end

assign input_mod_1170 = encoder_input - subtrahend;


endmodule
