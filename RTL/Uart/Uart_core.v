//-------------------------------------------------
//      Design      : Uart Core 
//      Designer    : rashid.shabab@siliconova.com
//      company     : Siliconova
//
//      Version     : 1.0
//      Created     : 17 Aug, 2024
//      Last updated: 22 Aug, 2024   
//--------------------------------------------------


module Uart_core
    (
        input  wire        clock,
        input  wire        reset_n,
        
        input  wire  [1:0] baud_rate,
        input  wire  [1:0] parity_type,

        input  wire        send,

        input  wire        wr_uart,
        input  wire        rd_uart,

        input  wire  [7:0] wr_data,
        input  wire        rx_line,

        output wire        tx_line,    
        output wire  [7:0] rd_data,

        output wire        tx_fifo_full,
        output wire        tx_fifo_empty,
        output wire        tx_fifo_err,
        
        output wire        rx_fifo_full,
        output wire        rx_fifo_empty,
        output wire        rx_fifo_err,

        output wire  [2:0] error_flag    

    );

    // Interconnection 
    wire [7:0] rx_data;
    wire       rx_done;

    wire [7:0] tx_data;
    wire tx_done;
    wire not_empty;
    wire w1;
    wire pop_en;

    // Reciever Unit instantiation
    RxUnit reciever
    (
        .clock(clock),
        .reset_n(reset_n),
        .baud_rate(baud_rate),
        .parity_type(parity_type),
        .error_flag(error_flag),
        .data_out(rx_data),
        .data_rx(rx_line),
        .done_flag(rx_done)
    );

    // Reciever FIFO instantiation
    Fifo rx_fifo
    (
       .clk(clock),
       .rst_n(reset_n),
       .push(rx_done),
       .pop(rd_uart),
       .empty(rx_fifo_empty),
       .full(rx_fifo_full),
       .err(rx_fifo_err),
       .push_data_in(rx_data),
       .pop_data_out(rd_data)
    );

    // Transmitter Unit instantiation
    TxUnit transmitter
    (
        .clock(clock),
        .reset_n(reset_n),
        .baud_rate(baud_rate),
        .parity_type(parity_type),
        .send(send),
        .data_in(tx_data),
        .data_tx(tx_line),
        .done_flag(tx_done )
    );

    // Transmitter FIFO instantiation
    Fifo tx_fifo
    (
      // .clk(transmitter.baudgent.baud_clk),
       .clk(clock),
       .rst_n(reset_n),
       .push(wr_uart),
       .pop(tx_done),
       .full(tx_fifo_full),
       .empty(tx_fifo_empty),
       .err(tx_fifo_err),
       .push_data_in(wr_data),
       .pop_data_out(tx_data)
    );
   
endmodule    
