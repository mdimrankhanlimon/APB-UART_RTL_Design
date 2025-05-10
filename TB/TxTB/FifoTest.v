
//-------------------------------------------------
//      Design      : FIFO TB
//      Designer    : rashidshabab58@gmail.com
//      company     : Siliconova
//
//      Version     : 1.0
//      Created     : 25 Apr, 2023
//      Last updated: 03 May, 2023   
//--------------------------------------------------

`timescale 1ns / 1ns

`define DATABUS 8
`define DEPTH 16
`define ADDRBUS $clog2(`DEPTH)

module tb_top ();
  
  reg clk, rst_n;
  reg pop,push;
  
  wire empty,full,err;
  
  reg  [`DATABUS-1:0]push_data_in;    // write
  wire [`DATABUS-1:0]pop_data_out;   // read
  
  //-----------
  // Clock Gen
  //-----------
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  //--------------------
  // DUT instantiation
  //--------------------
  
  Fifo #(.DEPTH(`DEPTH)) DUT 
           ( 
             .clk(clk), 
             .rst_n(rst_n),
             .pop(pop),
             .push(push),
             .empty(empty),
             .full(full),
             .err(err),
             .push_data_in(push_data_in),    
             .pop_data_out(pop_data_out)   
    				
           ); 
  // Initial stimulus
  initial begin
    clk = 0;
    rst_n = 1;
    pop = 0;
    push = 0;
    push_data_in = 0;
    
    // Apply reset
    #10 rst_n = 0;
    #10 rst_n = 1;
    
    // Write 3 data to FIFO
    repeat (3) begin
      #40; 
      push = 1;
      push_data_in = $urandom%256; // Write random data
      #20;
      push = 0;
    end
    
    @(posedge clk)
      push = 0;
    	
    // Read 2 data from FIFO
    #100;
        
    repeat (2 ) begin
      #40; 
      pop = 1;
      #20;
      pop = 0;
    end
    
      @(posedge clk)
      pop = 0;
    
    // Write 3 data to FIFO
    repeat (3) begin
      #40; 
      push = 1;
      push_data_in = $urandom%256; // Write random data
      #20;
      push = 0;
    end
    
    @(posedge clk)
      push = 0;
    
    // Read 4 data from FIFO
    #100;
        
    repeat (4) begin
      #40; 
      pop = 1;
      #20;
      pop = 0;
    end
    
      @(posedge clk)
      pop = 0;
    
    #100 $finish;
  end

  
  initial begin
  $dumpfile("dump.vcd"); $dumpvars;
  end
  
  
endmodule: tb_top








