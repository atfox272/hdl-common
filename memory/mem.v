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
    // Internal signal
    // -- wire
    // -- reg
    reg                     rd_rdy_q1;
    reg     [DATA_W-1:0]    rd_data_q1;
    reg     [DATA_W-1:0]    mem         [0:MEM_SIZE-1];

    // Combinational logic
    assign wr_rdy_o     = 1'b1;
    assign rd_data_o    = rd_data_q1;
    assign rd_rdy_o     = rd_rdy_q1;
    
    // RAM Inference
    always @(posedge clk) begin
        if(wr_vld_i & wr_rdy_o) begin
            mem[wr_addr_i] <= wr_data_i;
        end
    end
    always @(posedge clk) begin
        if(rd_vld_i) begin
            rd_data_q1 <= mem[rd_addr_i];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            rd_rdy_q1 <= 1'b0;
        end 
        else begin
            rd_rdy_q1 <= rd_vld_i;
        end 
    end
    initial begin
        if(MEM_FILE != "") begin
            $readmemh(MEM_FILE, mem); // Load memory from file
        end
    end
endmodule