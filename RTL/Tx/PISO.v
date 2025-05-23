
module PISO
(
    input wire           reset_n,            //  Active low reset.
    input wire           send,               //  An enable to start sending data.
    input wire           baud_clk,           //  Clocking signal from the BaudGen unit.
    input wire           parity_bit,         //  The parity bit from the Parity unit.
    
    input wire [7:0]     data_in,            //  The data input.
  
    output reg 	         data_tx, 	         //  Serial transmitter's data out
	
    output reg 	         active_flag,        //  high when Tx is transmitting, low when idle.
	output reg  	     done_flag 	         //  high when transmission is done, low when active.
);

    //  Encoding the states
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;
    
    //  Internal signals
    reg  [3:0]   stop_count;
    reg  [10:0]  frame_r;
    reg  [10:0]  frame_man;
    reg          next_state;
    wire         count_full;


    // Frame generation (gpt)
    always @(posedge baud_clk , negedge reset_n) begin
        if (!reset_n) begin
            frame_r <= {11{1'b1}};
        end else if (send && !next_state) begin
            frame_r <= {1'b1, parity_bit, data_in, 1'b0};  // Start bit (0) + data_in + parity_bit + stop bit (1)
        end else begin
            frame_r <= frame_r;
        end
    end


//  Frame generation
//always @(posedge baud_clk, negedge reset_n) begin
//    if (!reset_n)        frame_r <= {11{1'b1}};
//    else if (next_state) frame_r <= frame_r;
//    else                 frame_r <= {1'b1,parity_bit,data_in,1'b0};
//end


    // Counter logic
    always @(posedge baud_clk, negedge reset_n) begin
        if (!reset_n || !next_state || count_full) stop_count <= 4'd0;
        else  stop_count <= stop_count + 4'd1;
    end
    assign count_full     = (stop_count == 4'd11);
    
    //  Transmission logic FSM
    always @(posedge baud_clk, negedge reset_n) begin
        if (!reset_n) next_state   <= IDLE;
    	else
    	begin
    		if (!next_state) begin
                if (send) next_state   <= ACTIVE;
                else      next_state   <= IDLE;
            end
            else begin
                if (count_full) next_state   <= IDLE;
                else            next_state   <= ACTIVE;
            end
    	end 
    end
    
    always @(*) begin
        if (reset_n && next_state && (stop_count != 4'd0)) begin
            data_tx      = frame_man[0];
            frame_man    = frame_man >> 1;
            active_flag  = 1'b1;
            done_flag    = 1'b0;
        end
        else begin
            data_tx      = 1'b1;
            frame_man    = frame_r;
            active_flag  = 1'b0;
            done_flag    = 1'b1;
        end
    end

endmodule



