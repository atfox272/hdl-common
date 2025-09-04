module OnehotMux2D #(
  parameter type DATA_TYPE  = logic,
  parameter int  SEL_X_NUM  = 32,
  parameter int  SEL_Y_NUM  = 16
) (
  input     DATA_TYPE   [SEL_Y_NUM-1:0] [SEL_X_NUM-1:0] DataIn, 
  input     logic       [SEL_X_NUM-1:0]                 SelX, 
  input     logic       [SEL_Y_NUM-1:0]                 SelY,
  output    DATA_TYPE                                   DataOut
);
  typedef DATA_TYPE [SEL_X_NUM-1:0] Row_t;
  
  DATA_TYPE [SEL_X_NUM-1:0] SelRow;   // Selected Row 
  
  OnehotMux #(
    .DATA_TYPE  (Row_t),
    .SEL_NUM    (SEL_Y_NUM)
  ) RowSel (
    .DataIn     (DataIn),
    .Sel        (SelY),
    .DataOut    (SelRow)
  );

  OnehotMux #(
    .DATA_TYPE  (DATA_TYPE),
    .SEL_NUM    (SEL_X_NUM)
  ) DataSel (
    .DataIn     (SelRow),
    .Sel        (SelX),
    .DataOut    (DataOut)
  );
endmodule