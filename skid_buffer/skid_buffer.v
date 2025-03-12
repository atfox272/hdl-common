module skid_buffer
#(
    parameter   SBUF_TYPE   = 0,
    parameter   DATA_WIDTH  = 8
)
(
    // Global declaration
    input                       clk,
    input                       rst_n,
    // Input declaration
    input   [DATA_WIDTH-1:0]    bwd_data_i,
    input                       bwd_valid_i,
    input                       fwd_ready_i,
    // Output declaration
    output  [DATA_WIDTH-1:0]    fwd_data_o,
    output                      bwd_ready_o,
    output                      fwd_valid_o
);
generate
    if(SBUF_TYPE == 0) begin : FULL_REGISTERED
        // Internal signal 
        // -- wire declaration
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        reg     [DATA_WIDTH-1:0]    bwd_data_d;
        reg     [DATA_WIDTH-1:0]    fwd_data_d;
        reg                         bwd_ready_d;
        reg                         fwd_valid_d;
        // -- reg declaration 
        reg     [DATA_WIDTH-1:0]    bwd_data_q;
        reg     [DATA_WIDTH-1:0]    fwd_data_q;
        reg                         bwd_ready_q;
        reg                         fwd_valid_q;
        
        // Combinational logic
        // -- Output
        assign fwd_data_o       = fwd_data_q;
        assign fwd_valid_o      = fwd_valid_q;
        assign bwd_ready_o      = bwd_ready_q;
        // -- Internal connection
        assign bwd_handshake    = bwd_valid_i & bwd_ready_o;
        assign fwd_handshake    = fwd_valid_o & fwd_ready_i;
        always @* begin
            bwd_data_d  = bwd_data_q;
            fwd_data_d  = fwd_data_q;
            bwd_ready_d = bwd_ready_q;
            fwd_valid_d = fwd_valid_q;
            if(bwd_handshake & fwd_handshake) begin 
                fwd_data_d = bwd_data_i;
            end
            else if (bwd_handshake) begin
                if(fwd_valid_q) begin // Have a valid data in the skid buffer
                    bwd_data_d  = bwd_data_i;
                    bwd_ready_d = 1'b0;
                end
                else begin  // The skid buffer is empty
                    fwd_data_d  = bwd_data_i;
                    fwd_valid_d = 1'b1;
                end
            end
            else if (fwd_handshake) begin
                if(bwd_ready_q) begin   // Have 1 empty slot in the skid buffer
                    fwd_valid_d = 1'b0;
                end
                else begin // The skid buffer is full
                    fwd_data_d  = bwd_data_q;
                    bwd_ready_d = 1'b1;
                end
            end
        end
        
        // Flip-flop
        // -- Foward 
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_valid_q <= 1'b0;
            end
            else begin
                fwd_data_q  <= fwd_data_d;
                fwd_valid_q <= fwd_valid_d;
            end
        end
        // -- Backward
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ready_q <= 1'b1;
            end
            else begin
                bwd_data_q  <= bwd_data_d;
                bwd_ready_q <= bwd_ready_d;
            end
        end
    end
    else if(SBUF_TYPE == 1) begin   : OPT_BWD_TIMING    // Optimized backward timing
        
        // Internal signal
        // -- wire declaration
        // -- -- Backward
        wire                        bwd_ready_d;
        // -- -- Common
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        // -- -- FIFO
        wire    [DATA_WIDTH-1:0]    inter_fifo_data_i;
        wire    [DATA_WIDTH-1:0]    inter_fifo_data_o;
        wire                        inter_fifo_empty;
        wire                        inter_fifo_full;
        wire                        inter_fifo_almost_full;
        wire    [2:0]               inter_fifo_counter;
        wire                        inter_fifo_wr_en;
        wire                        inter_fifo_rd_en;
        // -- reg declaration
        reg     [DATA_WIDTH-1:0]    bwd_data_q;
        reg                         bwd_valid_q;
        reg                         bwd_ready_q;
        reg                         bwd_ready_prev_q;
        
        // Internal module
        fifo #(
            .DATA_WIDTH(DATA_WIDTH),
            .FIFO_DEPTH(4)
        ) fifo (
            .clk(clk),
            .data_i(inter_fifo_data_i),
            .data_o(inter_fifo_data_o),
            .rd_valid_i(inter_fifo_rd_en),
            .wr_valid_i(inter_fifo_wr_en),
            .empty_o(inter_fifo_empty),
            .full_o(inter_fifo_full),
            .almost_empty_o(),
            .almost_full_o(inter_fifo_almost_full),
            .counter(inter_fifo_counter),
            .rst_n(rst_n)
            );
        
        // Combinational logic
        // -- Output
        assign bwd_ready_o      = bwd_ready_q;
        assign bwd_ready_d      = ~(inter_fifo_counter == 2'd2) & ~inter_fifo_almost_full & ~inter_fifo_full;
        assign fwd_data_o       = (inter_fifo_empty) ? bwd_data_q : inter_fifo_data_o;
        assign fwd_valid_o      = bwd_handshake | (~inter_fifo_empty);
        // -- FIFO
        assign inter_fifo_data_i= bwd_data_q;
        assign inter_fifo_wr_en = bwd_handshake & ((~inter_fifo_empty) | (~fwd_handshake));
        assign inter_fifo_rd_en = fwd_handshake;
        // -- Common
        assign bwd_handshake    = bwd_ready_prev_q & bwd_valid_q;
        assign fwd_handshake    = fwd_ready_i & fwd_valid_o;
        
        always @(posedge clk) begin
            if(!rst_n) begin
            
            end
            else begin
                bwd_data_q <= bwd_data_i;
            end
        end
        
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_valid_q <= 1'b0;
            end
            else begin
                bwd_valid_q <= bwd_valid_i;
            end
        end
        
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ready_q      <= 1'b1;
                bwd_ready_prev_q <= 1'b1;
            end
            else begin
                bwd_ready_q      <= bwd_ready_d;
                bwd_ready_prev_q <= bwd_ready_q;
            end
        end
        
    end
    else if(SBUF_TYPE == 2) begin   : LIGHT_WEIGHT
        // Internal signal 
        // -- wire declaration
        wire                        bwd_handshake;
        wire                        fwd_handshake;
        // -- reg declaration 
        reg                         bwd_ptr;
        reg                         fwd_ptr;
        reg     [DATA_WIDTH-1:0]    buffer;
        
        // Combination logic
        assign fwd_data_o       = buffer;
        assign bwd_ready_o      = ~fwd_valid_o;
        assign fwd_valid_o      = bwd_ptr ^ fwd_ptr;
        assign bwd_handshake    = bwd_valid_i & bwd_ready_o;
        assign fwd_handshake    = fwd_ready_i & fwd_valid_o;
        
        // Flip-flop logic
        // -- Backward pointer
        always @(posedge clk) begin
            if(!rst_n) begin
                bwd_ptr <= 1'b0;
            end
            else if(bwd_handshake) begin
                bwd_ptr <= ~bwd_ptr;
            end
        end
        // -- Forward pointer
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_ptr <= 1'b0;
            end
            else if(fwd_handshake) begin
                fwd_ptr <= ~fwd_ptr;
            end
        end
        // -- Buffer
        always @(posedge clk) begin
            if(!rst_n) begin
            
            end
            else if(bwd_handshake) begin
                buffer <= bwd_data_i;
            end
        end
    end
    else if(SBUF_TYPE == 3) begin   : OPT_FWD_TIMING    // Optimized forward timing
        // Local parameter 
        localparam ACTIVE_ST        = 1'd0;
        localparam PASSIVE_ST       = 1'd1;
        // Internal signal 
        // -- wire
        wire    [DATA_WIDTH-1:0]    fwd_data_d;         /* Can use */
        wire                        fwd_data_en;        /* VIOLATED PATH -> Do not use */
        wire                        fwd_data_ien;       /* Can use */
        wire                        fwd_valid_d;        /* Can use */
        wire                        fwd_valid_en;       /* VIOLATED PATH -> Do not use */
        wire                        fwd_valid_ien;      /* Can use */
        wire                        fwd_sel;            /* Can use */
        wire    [DATA_WIDTH-1:0]    fifo_rd_data;       /* Can use */
        wire                        fifo_rd_valid;      /* Can use */
        wire                        fifo_rd_ready;      /* Can use */
        reg                         sb_state_d;         /* Can use */
        // -- reg
        reg     [DATA_WIDTH-1:0]    fwd_data_q;         /* Can use */
        reg     [DATA_WIDTH-1:0]    fwd_bckp_data_q;    /* Can use */
        reg                         fwd_bckp_valid_q;   /* Can use */
        reg                         fwd_valid_q;        /* Can use */
        reg                         fwd_ready_q;        /* Can use */
        reg                         sb_state_q;
        
        // Internal module
        sb_fifo 
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .FIFO_DEPTH(2)
        ) fifo (
            .clk        (clk),
            .data_i     (bwd_data_i),
            .data_o     (fifo_rd_data),
            .rd_valid_i (fifo_rd_valid),
            .wr_valid_i (bwd_valid_i),
            .wr_ready_o (bwd_ready_o),
            .rd_ready_o (fifo_rd_ready),
            .rst_n      (rst_n)
        );
        
        // Combination logic
        assign fwd_data_o       = fwd_data_q;
        assign fwd_valid_o      = fwd_valid_q;
        assign fwd_sel          = (sb_state_q == PASSIVE_ST) & (~fwd_ready_q);
        assign fwd_data_d       = (fwd_sel) ? fwd_bckp_data_q  : fifo_rd_data;
        assign fwd_valid_d      = (~(!fwd_valid_q & (sb_state_q == PASSIVE_ST))) & ((fwd_sel) ? fwd_bckp_valid_q : fifo_rd_ready);
        assign fwd_data_en      = fwd_data_ien | fwd_ready_i;
        assign fwd_valid_en     = fwd_valid_ien | fwd_ready_i;
        assign fwd_data_ien     = (sb_state_q == ACTIVE_ST) & fifo_rd_ready;
        assign fwd_valid_ien    = fwd_data_ien;
        assign fifo_rd_valid    = (sb_state_q == ACTIVE_ST) | ((sb_state_q == PASSIVE_ST) & fwd_ready_q & fwd_valid_q);
        always @(*) begin
            sb_state_d = sb_state_q;
            case(sb_state_q)
                ACTIVE_ST: begin
                    if(fifo_rd_ready) begin
                        sb_state_d = PASSIVE_ST;
                    end
                end
                PASSIVE_ST: begin
                    if(!fwd_valid_q) begin
                        sb_state_d = ACTIVE_ST;
                    end
                end
            endcase
        end
        // Flip-flop
        // -- Forward Data          
        always @(posedge clk) begin
            if(fwd_data_en) begin
                fwd_data_q <= fwd_data_d;
            end
        end
        // -- Forward Valid
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_valid_q <= 1'b0;
            end
            else if(fwd_valid_en) begin
                fwd_valid_q <= fwd_valid_d;
            end
        end
        // -- Forward Ready
        always @(posedge clk) begin
            fwd_ready_q <= fwd_ready_i;
        end
        // -- Backup Forward Data
        always @(posedge clk) begin
            if(fwd_ready_q) begin
                fwd_bckp_data_q <= fifo_rd_data;
            end 
        end
        // -- Backup Data Valid
        always @(posedge clk) begin
            if(!rst_n) begin
                fwd_bckp_valid_q <= 1'b0;
            end
            else if(fwd_ready_q) begin
                fwd_bckp_valid_q <= fifo_rd_ready & (~(!fwd_valid_q & (sb_state_q == PASSIVE_ST)));
            end
        end
        // -- Skid buffer state
        always @(posedge clk) begin
            if(~rst_n) begin
                sb_state_q <= 1'b0;
            end
            else begin
                sb_state_q <= sb_state_d;
            end
        end
    end
    else if(SBUF_TYPE == 4) begin   : BYPASS
        assign fwd_data_o   = bwd_data_i;
        assign fwd_valid_o  = bwd_valid_i;
        assign bwd_ready_o  = fwd_ready_i;
    end
    else if(SBUF_TYPE == 5) begin   : HALF_REGISTERED
        // Internal signal declaration
        // -- wire
        wire                    bwd_hsk;
        wire                    fwd_hsk;
        wire                    full;
        // -- reg
        reg [DATA_WIDTH-1:0]    buffer;
        reg                     fwd_vld;
        reg                     wr_ptr;
        reg                     rd_ptr;
        
        // Combination logic
        assign fwd_data_o   = buffer;
        assign fwd_valid_o  = fwd_vld;
        assign bwd_ready_o  = fwd_hsk | (~full);
        assign bwd_hsk      = bwd_valid_i & bwd_ready_o; 
        assign fwd_hsk      = fwd_valid_o & fwd_ready_i; 
        assign full         = wr_ptr^rd_ptr;
        
        // Flip-flop
        always @(posedge clk) begin
            if(bwd_hsk) begin
                buffer <= bwd_data_i;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                fwd_vld <= 1'b0;
            end
            else if(fwd_hsk | bwd_hsk) begin
                fwd_vld <= bwd_hsk;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                wr_ptr <= 1'b0;
            end
            else if(bwd_hsk) begin
                wr_ptr <= ~wr_ptr;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                rd_ptr <= 1'b0;
            end
            else if(fwd_hsk) begin
                rd_ptr <= ~rd_ptr;
            end
        end
    end
endgenerate
endmodule