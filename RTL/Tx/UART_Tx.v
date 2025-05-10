
module UART_Tx (
    input  wire       reset_n, clock, send,
    input  wire [1:0] parity_type, baud_rate,
    input  wire [7:0] data_in,
    output wire       data_tx, tx_active_flag, tx_done_flag,
    output wire       fifo_full, fifo_empty, fifo_err
);
    wire [7:0] fifo_data_out;
    wire fifo_push, fifo_pop;

    // FIFO for Transmitter Data
    Fifo #(.DEPTH(4)) tx_fifo (
        .clk(clock),
        .rst_n(reset_n),
        .push(fifo_push),
        .pop(fifo_pop),
        .push_data_in(data_in),
        .pop_data_out(fifo_data_out),
        .empty(fifo_empty),
        .full(fifo_full),
        .err(fifo_err)
    );

    // Parity generation
    Parity parity_gen (
        .reset_n(reset_n),
        .data_in(fifo_data_out),
        .parity_type(parity_type),
        .parity_bit(parity_bit)
    );

    // Baud rate generator
    BaudGenT baud_gen (
        .clock(clock),
        .reset_n(reset_n),
        .baud_rate(baud_rate),
        .baud_clk(baud_clk)
    );

    // Parallel-In Serial-Out (PISO) shift register
    PISO piso (
        .reset_n(reset_n),
        .baud_clk(baud_clk),
        .data_in(fifo_data_out),
        .parity_bit(parity_bit),
        .send(fifo_pop),
        .data_tx(data_tx),
        .active_flag(active_flag),
        .done_flag(done_flag)
    );


    // Transmitter Logic
    assign fifo_push = send && !fifo_full;
    assign fifo_pop = tx_done_flag && !fifo_empty;


endmodule
