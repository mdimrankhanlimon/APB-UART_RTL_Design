module TxUnit
(
    input wire          clock,         //  The main system's clock.
    input wire          reset_n,       //  Active low reset.
    
    input wire  [1:0]   parity_type,   //  Parity type agreed upon by the Tx and Rx units.
    input wire  [1:0]   baud_rate,     //  Baud Rate agreed upon by the Tx and Rx units.
    
    input wire          send,          //  An enable to start sending data.
    
    input wire  [7:0]   data_in,       //  The data input.

    output        data_tx,             //  Serial transmitter's data out.
    output        active_flag,         //  high when Tx is transmitting, low when idle.
    output        done_flag            //  high when transmission is done, low when active.
);

    //  Interconnections
    wire parity_bit_w;
    wire baud_clk_w;
    
    //  Baud generator unit instantiation
    BaudGenT baudgent
    (
        //  Inputs
        .reset_n(reset_n),
        .clock(clock),
        .baud_rate(baud_rate),
        
        //  Output
        .baud_clk(baud_clk_w)
    );
    
    //Parity unit instantiation 
    Parity parity
    (
        //  Inputs
        .reset_n(reset_n),
        .data_in(data_in),
        .parity_type(parity_type),
        
        //  Output
        .parity_bit(parity_bit_w)
    );
    
    //  PISO shift register unit instantiation
    PISO piso
    (
        //  Inputs
        .reset_n(reset_n),
        .send(send),
        .baud_clk(baud_clk_w),
        .data_in(data_in),
        .parity_bit(parity_bit_w),
    
        //  Outputs
        .data_tx(data_tx),
        .active_flag(active_flag),
        .done_flag(done_flag)
    );
    
endmodule
    
    
