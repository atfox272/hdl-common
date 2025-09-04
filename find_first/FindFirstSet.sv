module FindFirstSet #(
  parameter DATA_W = 4
) (
  input   logic [DATA_W-1:0]  In,
  output  logic [DATA_W-1:0]  Out
);
  // Influence on timing while scaling up: Log2(DATA_W)
  genvar i;
  generate
    for (i = 0; i < DATA_W; i = i + 1) begin : IdxMap
      if(i == 0)    assign Out[i] = In[i];
      else          assign Out[i] = In[i] & (&(~In[i-1:0]));
    end
  endgenerate
endmodule