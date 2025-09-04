/*
  Multiplier Sequence: 
  Generate a sequence of elements, which are increased by a input value compared with the previous element. 
  Each element is shared resource with previous element   

  Example:

    Input:    
            X
    Output:   
            X*1
            X*2
            .
            .
            X*SEQ_LEN


  Purpose: To reduce the number of Adder when generating Multiplying suquence
*/
module MulSeq #(
  parameter DATA_IN_W   = 5,
  parameter SEQ_LEN     = 32,
  parameter DATA_OUT_W  = DATA_IN_W + $clog2(SEQ_LEN)
) (
  input     logic   [DATA_IN_W-1:0]     DataIn,
  output    logic   [DATA_OUT_W-1:0]    DataOut     [SEQ_LEN-1:0]
);
  always_comb begin
    for (int i = 0; i < SEQ_LEN; i++) begin
      if(((i-1) & i) == 0) begin : MulPowerOf2  // Multiply with a power-of-2
        DataOut[i] = DataIn << $clog2(i);
      end
      else begin
        DataOut[i] = DataOut[i-1] + DataIn;     // Shared resource with the preivous element
      end
    end
  end
endmodule