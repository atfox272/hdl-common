module gray2bin_converter
#(
    parameter DATA_WIDTH = 4
)
(
    input   [DATA_WIDTH-1:0]    gray_i,
    output  [DATA_WIDTH-1:0]    bin_o
);
    // Internal variable declaration
    genvar idx;

    // Combinational logic
    generate
        for(idx = 0; idx < DATA_WIDTH; idx = idx + 1) begin : BIN_LOGIC_GEN
            if(idx == DATA_WIDTH - 1) begin
                assign bin_o[idx] = gray_i[idx];
            end
            else begin
                assign bin_o[idx] = gray_i[idx] ^ bin_o[idx+1];
            end
        end
    endgenerate
endmodule
