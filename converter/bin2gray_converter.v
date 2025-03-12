module bin2gray_converter
#(
    parameter DATA_WIDTH = 4
)
(
    input   [DATA_WIDTH-1:0]    bin_i,
    output  [DATA_WIDTH-1:0]    gray_o
);
    // Internal variable declaration
    genvar idx;

    // Combinational logic
    generate
        for(idx = 0; idx < DATA_WIDTH; idx = idx + 1) begin : GRAY_LOGIC_GEN
            if(idx == DATA_WIDTH - 1) begin
                assign gray_o[idx] = bin_i[idx];
            end
            else begin
                assign gray_o[idx] = bin_i[idx] ^ bin_i[idx+1];
            end
        end
    endgenerate
endmodule
