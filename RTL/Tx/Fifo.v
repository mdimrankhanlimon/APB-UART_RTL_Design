
//-------------------------------------------------
//      Design      : FIFO 
//      Designer    : rashid.shabab@siliconova.com
//      company     : Siliconova
//
//      Version     : 1.1
//      Created     : 25 Apr, 2024
//      Last updated: 03 May, 2024   
//--------------------------------------------------

module Fifo 
  #( parameter DEPTH = 1024,
     parameter ADDR_WIDTH = $clog2(DEPTH)
  )
  (
    input                    clk, rst_n,        // Global signals
    input                    push, pop,         // Control signals
    output                   empty, full, err,  // Flags
    input   [7:0]            push_data_in,      // Data input
    output  [7:0]            pop_data_out       // Data output
  );

  // Internal memory array
  reg [7:0] mem [0:DEPTH-1];
  
  // Read and write pointers
  reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;

  reg [7:0] outData;
  
  // FIFO status flags
  reg empty_reg, full_reg, err_reg;
  
  // Internal write enable signal
  wire wr_en = push && !full_reg;
  
  // Internal read enable signal
  wire rd_en = pop && !empty_reg;
  
  // FIFO status logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      empty_reg <= 1'b1;
      full_reg <= 1'b0;
      err_reg <= 1'b0;
    end else begin
      if (wr_en) begin
        mem[wr_ptr] <= push_data_in;
        wr_ptr <= wr_ptr + 1'b1;
        if ((wr_ptr + 1'b1) == rd_ptr) begin
          full_reg <= 1'b1;
        end
        empty_reg <= 1'b0;
      end
      
      if (rd_en) begin
        rd_ptr <= rd_ptr + 1'b1;
        outData <= mem[rd_ptr];
        if ((rd_ptr + 1'b1) == wr_ptr) begin
          empty_reg <= 1'b1;
        end
        full_reg <= 1'b0;
      end

      if (wr_en && rd_en && (wr_ptr == rd_ptr)) begin
        err_reg <= 1'b1; // Error condition: simultaneous push and pop at full/empty
      end else begin
        err_reg <= 1'b0;
      end
    end
  end
  
  // Assigning status flags
  assign empty = empty_reg;
  assign full  = full_reg;
  assign err   = err_reg;
  
  // Data output logic
  assign pop_data_out =  outData;
  
endmodule


