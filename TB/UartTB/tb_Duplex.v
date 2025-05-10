
`timescale 1ns/1ps
module tb_UART();

//  Regs to drive inputs
reg         reset_n;
reg         clock;
reg  [1:0]  parity_type;
reg  [1:0]  baud_rate;
reg  [7:0]  data_in;
reg         send;

//  Wires to connect the Tx and Rx
wire         data_tx;
wire         tx_done_flag;
wire         tx_active_flag;
wire  [7:0]  data_out;
wire         rx_done_flag;
wire         rx_active_flag;
wire  [2:0]  error_flag;

//  Instance of the UART_Tx module
UART_Tx tx (
    .reset_n(reset_n),
    .send(send),
    .data_in(data_in),
    .clock(clock),
    .parity_type(parity_type),
    .baud_rate(baud_rate),
    .data_tx(data_tx),
    .tx_active_flag(tx_active_flag),
    .tx_done_flag(tx_done_flag)
);

//  Instance of the UART_Rx module
UART_Rx rx (
    .reset_n(reset_n),
    .data_tx(data_tx),
    .clock(clock),
    .parity_type(parity_type),
    .baud_rate(baud_rate),
    .rx_active_flag(rx_active_flag),
    .rx_done_flag(rx_done_flag),
    .error_flag(error_flag),
    .data_out(data_out)
);

//  dump
initial
begin
    $dumpfile("UART_Test.vcd");
    $dumpvars;
end

// Monitor the outputs and inputs
initial begin
    $monitor($time, " Tx Active Flag = %b  Tx Done Flag = %b Rx Active Flag = %b  Rx Done Flag = %b Data Out = %b Error Flag = %b Reset = %b Data In = %b Parity Type = %b Baud Rate = %b ",
    tx_active_flag, tx_done_flag, rx_active_flag, rx_done_flag, data_out[7:0], error_flag[2:0], reset_n, 
    data_in[7:0], parity_type[1:0], baud_rate[1:0]);
end

//  Resetting the system
initial 
begin
    reset_n = 1'b0;
    #10 reset_n = 1'b1;
end

//  System clock 50MHz
initial 
begin
    clock = 1'b0;
    forever 
    begin
        #10 clock = ~clock;
    end
end

//  Test sequence
initial 
begin
    //  Test for 9600 baud_rate
    baud_rate = 2'b10;
    //  Testing with ODD parity
    parity_type = 2'b01;
    //  Data for test
    data_in = 8'b11001010;
    send = 1'b1;

    // Wait enough time for one frame to be transmitted and received
    #1041667;  // Wait for one frame at 9600 baud (10.41667 us)
    
    //  Test for 19200 baud_rate
    baud_rate = 2'b11;
    //  Testing with EVEN parity
    parity_type = 2'b10;
    //  Data for test
    data_in = 8'b10101010;
    send = 1'b1;

    // Wait enough time for one frame to be transmitted and received
    #520833;  // Wait for one frame at 19200 baud (5.20833 us)

    // Additional time for observing the results
    #100000;
end

//  Stop
initial begin
    #3000000 $finish;  // Simulation for 3 ms
end

endmodule
