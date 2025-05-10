// TB for Uart Core
module tb_top();

    // Reg to drive inputs
        reg        clock;
        reg        reset_n;
        reg  [1:0] baud_rate;
        reg  [1:0] parity_type;

        reg        wr_uart;
        reg        rd_uart;
        reg        send;

        reg  [7:0] wr_data;
        reg        rx_line;

        wire        tx_line;    
        wire  [7:0] rd_data;

        wire        tx_fifo_full;
        wire        tx_fifo_empty;
        wire        tx_fifo_err;
        
        wire        rx_fifo_full;
        wire        rx_fifo_empty;
        wire        rx_fifo_err;

        wire [2:0] error_flag;    

  // 50 MHz clock
  initial clock = 0;
  always #10 clock = ~clock;


    //Instantiation
    Uart_core DUT
    (
         .clock(clock),
         .reset_n(reset_n),
         .baud_rate(baud_rate),
         .parity_type(parity_type),
         .send(send),
                      
         .wr_uart(wr_uart),
         .rd_uart(rd_uart),     
                      
         .wr_data(wr_data),
         .rx_line(rx_line),
                      
         .tx_line(tx_line),    
         .rd_data(rd_data),
                      
         .tx_fifo_full(tx_fifo_full),
         .tx_fifo_empty(tx_fifo_empty),
         .tx_fifo_err(tx_fifo_err),
                      
         .rx_fifo_full(rx_fifo_full),
         .rx_fifo_empty(rx_fifo_empty),
         .rx_fifo_err(rx_fifo_err),
                      
         .error_flag(error_flag)
    );

    // Applying Stimulus
    initial begin
        reset_n =0;
        send =1;
        rx_line = 1;

//-------------------------------------------------------------------------------------------
       //-----------
       //Tx TEST
       //------------
       // Test - 1 Baud rate 2400
        @(posedge clock) ;
        
        wr_data = 8'hEE;
        reset_n = 1;
        baud_rate = 0;
        parity_type = 1;
        wr_uart = 1;
        rd_uart = 0;
        send =1;
        
        @(posedge clock) ;
        
        wr_uart =0;
        #5416666.684; //  waits for the whole frame to be sent
        send = 0;
       
       #100000;
        reset_n =0;
        
       // Test -2 Baud rate 4800
        @(posedge clock) ;
        
        wr_data = 8'b11001010;
        reset_n = 1;
        baud_rate = 1;
        parity_type = 1;
        wr_uart = 1;
        rd_uart = 0;
        send =1;
        
        @(posedge clock) ;
        
        wr_uart =0;
        #2708333.342;   //  waits for the whole frame to be sent
        send = 0;
       
       #100000;
        reset_n =0;
        
        // Test - 3 Baud rate 9600
        @(posedge clock) ;
        
        wr_data = 8'h32;
        reset_n = 1;
        baud_rate = 2;
        parity_type = 1;
        wr_uart = 1;
        rd_uart = 0;
        send =1;
        
        @(posedge clock) ;
        
        wr_uart =0;
        #1354166.671;   //  waits for the whole frame to be sent
        send = 0;
       
       #100000;
        reset_n =0;
        
        // Test - 4 Baud rate 19200
        @(posedge clock) ;
        
        reset_n =1;
        wr_data = 8'hBA;
        baud_rate = 3;
        parity_type = 0;
        wr_uart = 1;
        rd_uart = 0;
        send =1;
        #677083.329;   //  waits for the whole frame to be sent
        
        wr_uart =0;
        send = 0;

        #1000000;

// Tx TEST End
// ------------------------------------------------------------------------------
// Rx TEST
 //  Test for 9600 baud_rate
    baud_rate = 2'b10;
    //  Testing with ODD parity
    parity_type = 2'b01;
    //  Data for test, frame of 11001010110
    //  with ODD parity, 1 stop bit
    //  Sent at baud rate of 9600
    rx_line = 1'b1;
    //  Idle at first
    #104166.667 rx_line = 1'b0;
    
    #104166.667 rx_line = 1'b1;
    #104166.667 rx_line = 1'b1;
    #104166.667 rx_line = 1'b0;
    #104166.667 rx_line = 1'b1;
    #104166.667 rx_line = 1'b0;
    #104166.667 rx_line = 1'b1;
    #104166.667 rx_line = 1'b0;
    #104166.667 rx_line = 1'b0;

    #104166.667 rx_line = 1'b1;
    //  Stop bit
    #104166.667 rx_line = 1'b1;
    #104166.667;
    #104166.667;

    rd_uart = 1;
    @(posedge clock) ;

    rd_uart = 0;
    


//-------------------------------------------------------------------------------


    end

    // Stopping the simulation
    initial begin
        #16000000;
        $finish;
    end

    // generating Waveform
    initial begin
        $dumpvars;
        $dumpfile("dump.vcd");
    end

    // monitor signals
    initial begin
        $monitor($time, 
             " ns || send = %b | wr_uart = %b | wr_data = %b | baud = %b | parity_type = %b | tx_line = %b ", 
             send, wr_uart, wr_data[7:0], baud_rate[1:0], parity_type[1:0], tx_line);
    end

endmodule         
