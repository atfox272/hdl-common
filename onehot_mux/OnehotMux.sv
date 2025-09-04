module OnehotMux #(
  parameter type DATA_TYPE  = logic,
  parameter int  SEL_NUM    = 4
) (
  input     DATA_TYPE   [SEL_NUM-1:0]   DataIn ,
  input     logic       [SEL_NUM-1:0]   Sel,
  output    DATA_TYPE                   DataOut
);
  // Ultilize AOI cell to be more optimized timing, but worse area 
  always_comb begin
    DataOut = '0;
    for (int i = 0; i < SEL_NUM; i++) begin
      DataOut |= {$bits(DataOut){Sel[i]}} & DataIn[i];
    end
  end
endmodule