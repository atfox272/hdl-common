module memory
#(
    parameter DATA_W    = 8,
    parameter ADDR_W    = 8,
    parameter MEM_SIZE  = 1<<ADDR_W,
    parameter MEM_FILE  = ""
)
(
    input                   clk,
    input                   rst_n,

    // Input declaration
    input   [DATA_W-1:0]    wr_data_i,
    input   [ADDR_W-1:0]    wr_addr_i,
    input                   wr_vld_i,
    input   [ADDR_W-1:0]    rd_addr_i,
    input                   rd_vld_i,

    // Ouptut declaration
    output                  wr_rdy_o,
    output  [DATA_W-1:0]    rd_data_o,
    output                  rd_rdy_o
);
    // Local parameters
    localparam SKY130_SRAM_WIDTH    = 32;
    localparam SKY130_SRAM_DEPTH    = 256;
    localparam NUM_SRAMS            = (DATA_W + SKY130_SRAM_WIDTH - 1) / SKY130_SRAM_WIDTH; // Each SRAM is 32 bits wide
    localparam NUM_BANKS            = (MEM_SIZE + SKY130_SRAM_DEPTH - 1) / SKY130_SRAM_DEPTH; // Number of banks needed
    localparam ALIGN_ADDR_W         = $clog2(MEM_SIZE);
    // Internal signal
    // -- wire
    // -- reg
    wire    [DATA_W-1:0]    rd_data_int;
    reg                     rd_rdy_q1;
    reg     [DATA_W-1:0]    rd_data_q1;

    // Combinational logic
    assign wr_rdy_o     = 1'b1;
    assign rd_data_o    = rd_data_q1;
    assign rd_rdy_o     = rd_rdy_q1;
    
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            rd_rdy_q1 <= 1'b0;
        end 
        else begin
            rd_rdy_q1 <= rd_vld_i;
            if(rd_vld_i) begin
                rd_data_q1 <= rd_data_int;
            end
        end 
    end
    
    // Generate SRAM instances
    genvar i, j;
    generate
        for (i = 0; i < NUM_SRAMS; i = i + 1) begin : gen_sram
            for (j = 0; j < NUM_BANKS; j = j + 1) begin : gen_bank
                wire [SKY130_SRAM_WIDTH-1:0] sram_dout;
                wire [SKY130_SRAM_WIDTH-1:0] sram_din = wr_data_i[(i+1)*SKY130_SRAM_WIDTH-1:i*SKY130_SRAM_WIDTH];
                wire sram_we = wr_vld_i && (wr_addr_i < MEM_SIZE) && (wr_addr_i[ALIGN_ADDR_W-1:8] == j);
                wire sram_cs = (wr_addr_i < MEM_SIZE) && (wr_addr_i[ALIGN_ADDR_W-1:8] == j) && rd_vld_i;

                sky130_sram_1kbyte_1rw1r_32x256_8 sram_inst (
                    .clk0(clk),
                    .csb0(!sram_cs),
                    .web0(!sram_we),
                    .wmask0(4'b1111), // Full mask
                    .addr0(wr_addr_i[7:0]), // Address within the bank (Higher bits are used to map banks)
                    .din0(sram_din),
                    .dout0(sram_dout),

                    .clk1(1'b0),
                    .csb1(1'b1),
                    .addr1(1'b0),
                    .dout1()
                );

                // Combine read data
                if (j == wr_addr_i[ALIGN_ADDR_W-1:8]) begin
                    assign rd_data_int[(i+1)*SKY130_SRAM_WIDTH-1:i*SKY130_SRAM_WIDTH] = sram_dout;
                end
            end
        end
    endgenerate
endmodule