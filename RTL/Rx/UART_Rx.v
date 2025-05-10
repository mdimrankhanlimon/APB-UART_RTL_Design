
module UART_Rx (
    input  wire       reset_n, clock,
    input  wire [1:0] parity_type, baud_rate,
    input  wire       data_tx,
    output wire [7:0] data_out,
    output wire       rx_active_flag, rx_done_flag,
    output wire       fifo_full, fifo_empty, fifo_err,
    output wire [2:0] error_flag
);
    wire [7:0] fifo_data_in;
    wire fifo_push, fifo_pop;

    // FIFO for Receiver Data
    Fifo #(.DEPTH(8)) rx_fifo (
        .clk(clock),
        .rst_n(reset_n),
        .push(fifo_push),
        .pop(fifo_pop),
        .push_data_in(fifo_data_in),
        .pop_data_out(data_out),
        .empty(fifo_empty),
        .full(fifo_full),
        .err(fifo_err)
    );

    // Baud rate generator
    BaudGenR baud_gen (
        .clock(clock),
        .reset_n(reset_n),
        .baud_rate(baud_rate),
        .baud_clk(baud_clk)
    );

    // Serial-In Parallel-Out (SIPO) shift register
    SIPO sipo (
        .reset_n(reset_n),
        .baud_clk(baud_clk),
        .data_tx(data_tx),
        .active_flag(active_flag),
        .recieved_flag(recieved_flag),
        .data_parll(data_parll)
    );

    // Deframer module
    DeFrame deframe (
        .data_parll(data_parll),
        .recieved_flag(recieved_flag),
        .raw_data(deframed_data),
        .parity_bit(parity_bit),
        .start_bit(start_bit),
        .stop_bit(stop_bit),
        .done_flag(done_flag)
    );

    // Error checking module
    ErrorCheck error_check (
        .reset_n(reset_n),
        .recieved_flag(recieved_flag),
        .parity_bit(parity_bit),
        .start_bit(start_bit),
        .stop_bit(stop_bit),
        .parity_type(parity_type),
        .raw_data(deframed_data),
        .error_flag(error_flag)
    );

    // Receiver Logic
    assign fifo_push = rx_done_flag && !fifo_full;
    assign fifo_pop = !fifo_empty;  // Control logic for when to read from FIFO

endmodule
