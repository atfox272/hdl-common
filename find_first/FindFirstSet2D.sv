/*
  Find first set row from bottom to top (0 -> MAX_Y),   Y dimension
  then find first set bit in the row from LSB to MSB    X dimension     

  Input:
                    0   0   0   0   0
                    0   0   1   1   0
                    0   1   0   0   0
                    0   0   0   1   0
                    0   0   1   0   0 

  Output:
    - With OutY:    0   1   0   0   0   -> 2nd Row
    - With OutX:    0   0   1   0   0   -> 3rd Bit
    
    -> Visualize:   0   0   0   0   0
                    0   0   1   0   0
                    0   0   0   0   0
                    0   0   0   0   0
                    0   0   0   0   0

  Purpose: Used for high-speed 2D mapping in Image Resizer
*/
module FindFirstSet2D #(
  parameter DATA_X_W = 7,
  parameter DATA_Y_W = 5
) (
  input   logic  [DATA_X_W-1:0]  In     [DATA_Y_W-1:0], 
  output  logic  [DATA_X_W-1:0]  OutX,                  // First set in 2D (onhot in X dimension)
  output  logic  [DATA_Y_W-1:0]  OutY                   // First set in 2D (onhot in Y dimension)
);
  // Timing influence while scaling up: Log2(DATA_X_W * DATA_Y_W)
  genvar x;
  genvar y;
  
  typedef logic [DATA_X_W-1:0]  InXData_t;

  logic     [DATA_Y_W-1:0]  SetY;
  InXData_t [DATA_Y_W-1:0]  FirstSetXList;
  
  FindFirstSet #(
    .DATA_W (DATA_Y_W)
  ) FindFirstSetY (
    .In     (SetY),
    .Out    (OutY)
  );
  
  generate
    for (y = 0; y < DATA_Y_W; y++) begin : MapY
      assign SetY[y] = |In[y];
      
      FindFirstSet #(
        .DATA_W (DATA_X_W)
      ) FindFirstSetY (
        .In     (In[y]),
        .Out    (FirstSetXList[y])
      );
    end
  endgenerate


  OnehotMux #(
    .DATA_TYPE  (InXData_t),
    .SEL_NUM    (DATA_Y_W)
  ) MapFirstSetX (
    .DataIn     (FirstSetXList),
    .Sel        (OutY),
    .DataOut    (OutX)
  );
endmodule