//-------------------------------------------------
//      Design      : Uart APB Slave TestBench 
//      Designer    : rashid.shabab@siliconova.com
//      company     : Siliconova
//
//      Version     : 1.0
//      Created     : 29 Aug, 2024
//      Last updated: 04 Sep, 2024   
//--------------------------------------------------

module tb_top();

    // Reg to drive inputs
    reg                 PCLK_i;
    reg                 PRESETn_i;
    reg  [9:0]          PADDR_i;
    reg                 PWRITE_i;
    reg  [7:0]          PWDATA_i;
    reg                 PSEL_i;
    reg                 PENABLE_i;

    wire [7:0]          PRDATA_o;
    wire                PREADY_o;
    wire                PSLVERR_o;

    // UART core interface
    wire                tx_line;
    reg                 rx_line;

    // Clock generation
    initial    PCLK_i = 0;
    always #10 PCLK_i = ~PCLK_i;

    // Instantiation of APB UART
    apb_uart_slave #(.DATA_WIDTH(8), .DEPTH(1024)) DUT (
        .PCLK_i(PCLK_i),
        .PRESETn_i(PRESETn_i),
        .PADDR_i(PADDR_i),
        .PWRITE_i(PWRITE_i),
        .PWDATA_i(PWDATA_i),
        .PSEL_i(PSEL_i),
        .PENABLE_i(PENABLE_i),
        .PRDATA_o(PRDATA_o),
        .PREADY_o(PREADY_o),
        .PSLVERR_o(PSLVERR_o),
        .rx_line(rx_line),  
        .tx_line(tx_line)
    );

    // Applying Stimulus
    initial begin
 
 //------------TRANSMISSION_TEST_1-------------------------------------------

        // 1. Reset
        PRESETn_i = 0;
        PSEL_i    = 0;
        PENABLE_i = 0;
        PWRITE_i  = 0;
        rx_line   = 1;
        //#100;
        repeat(10) @(posedge PCLK_i);
        PRESETn_i = 1;
        
 /*       // 2. Write to Control Register to Enable Send Signal
        // Control Register Offset = 8'h00
        //#20;
        PADDR_i   = 10'h00;
        PWRITE_i  = 1;
        PWDATA_i  = 8'b00010101; // Example: Baud rate = 2'b10, parity_type = 2'b10, send = 1
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PENABLE_i = 0;

        repeat(2) @(posedge PCLK_i);
  */     
       // 3. Write to TX Data Register
        // TX Data Register Offset = 8'h08
        PADDR_i   = 10'h08;
        PWRITE_i  = 1;
        PWDATA_i  = 8'h9A; // Example data to transmit
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PWRITE_i  = 0;
        PENABLE_i = 0;
        @(posedge PCLK_i);
        PSEL_i    = 0;

//-----------------------------------------------------------------------------------------
    
// 3. Write to TX Data Register
        // TX Data Register Offset = 8'h08
        PADDR_i   = 10'h08;
        PWRITE_i  = 1;
        PWDATA_i  = 8'hE2; // Example data to transmit
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PWRITE_i  = 0;
        PENABLE_i = 0;
        @(posedge PCLK_i);
        PSEL_i    = 0;

// 3. Write to TX Data Register
        // TX Data Register Offset = 8'h08
        PADDR_i   = 10'h08;
        PWRITE_i  = 1;
        PWDATA_i  = 8'h53; // Example data to transmit
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PWRITE_i  = 0;
        PENABLE_i = 0;
        @(posedge PCLK_i);
        PSEL_i    = 0;


// 2. Write to Control Register to Enable Send Signal
        // Control Register Offset = 8'h00
        //#20;
        PADDR_i   = 10'h00;
        PWRITE_i  = 1;
        PWDATA_i  = 8'b00010101; // Example: Baud rate = 2'b10, parity_type = 2'b10, send = 1
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PENABLE_i = 0;

        repeat(2) @(posedge PCLK_i);


//-----------------------------------------------------------------------------------------
       
        // 4. Wait for Transmission to Complete
        #1354166.671; // Adjust this delay based on expected transmission time
        #1354166.671; // Adjust this delay based on expected transmission time
        #1354166.671; // Adjust this delay based on expected transmission time
        
        // 5. Turn Off Send Signal
        // Control Register Offset = 8'h00
        PADDR_i   = 10'h00;
        PWRITE_i  = 1;
        PWDATA_i  = 8'b00010100; // Send = 0, other settings remain the same
        PSEL_i    = 1;
        PENABLE_i = 1;
        #20;
        PWRITE_i  = 0;
        PSEL_i    = 0;
        PENABLE_i = 0;

//----------------Tx_TEST_1_END------------------------------

//------------TRANSMISSION_TEST_2-------------------------------------------



//----------------Tx_TEST_2_END------------------------------
        
        // Delay 
        #100000;

//-----------RECEIPTION TEST-------------------------------
        // 1. Reset
        PRESETn_i = 0;
        PSEL_i    = 0;
        PENABLE_i = 0;
        PWRITE_i  = 0;
        //#100;
        repeat(10) @(posedge PCLK_i);
        PRESETn_i = 1;
        
        // 2. Write to Control Register to Enable Send Signal
        // Control Register Offset = 8'h00
        //#20;
        PADDR_i   = 10'h00;
        PWRITE_i  = 1;
        PWDATA_i  = 8'b00001100; // Example: Baud rate = 2'b10, parity_type =  2'b01, send = 0
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PENABLE_i = 0;

        repeat(2) @(posedge PCLK_i);
        PWRITE_i  = 0;
        PSEL_i    = 0;
      
        // 3. rx_line data input
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
         #104166.667 rx_line = 1'b0;
         //  Stop bit
         #104166.667 rx_line = 1'b1;
         #104166.667;
         #104166.667;


      // 4. Read from RX Data Register
        // RX Data Register Offset = 8'h10
        PADDR_i   = 10'h10;
        PWRITE_i  = 0;
        PSEL_i    = 1;
               
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
       repeat(5) @(posedge PCLK_i);
        PENABLE_i = 0;
        
        repeat(2) @(posedge PCLK_i);
        //PENABLE_i = 0;

        PSEL_i    = 0;



 //---------------------------------------------------------------------------------------      
 
 
 // 2. Write to Control Register to Enable Send Signal
        // Control Register Offset = 8'h00
        //#20;
        PADDR_i   = 10'h00;
        PWRITE_i  = 1;
        PWDATA_i  = 8'b00001110; // Example: Baud rate = 2'b10, parity_type =  2'b01, send = 0
        PSEL_i    = 1;
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
        repeat(2) @(posedge PCLK_i);
        PENABLE_i = 0;

        repeat(2) @(posedge PCLK_i);
        PWRITE_i  = 0;
        PSEL_i    = 0;


    #52083.333 rx_line = 1'b0;
    #52083.333 rx_line = 1'b1;
    #52083.333 rx_line = 1'b1;
    #52083.333 rx_line = 1'b0;
    #52083.333 rx_line = 1'b1;
    #52083.333 rx_line = 1'b0;
    #52083.333 rx_line = 1'b1;
    #52083.333 rx_line = 1'b0;
    #52083.333 rx_line = 1'b0;
    #52083.333 rx_line = 1'b1;
    //  Stop bit
    #52083.333;
    rx_line = 1'b1;
    #52083.333;

 // 4. Read from RX Data Register
        // RX Data Register Offset = 8'h10
        PADDR_i   = 10'h10;
        PWRITE_i  = 0;
        PSEL_i    = 1;
               
        @(posedge PCLK_i);
        PENABLE_i = 1;
        
       repeat(5) @(posedge PCLK_i);
        PENABLE_i = 0;
        
        repeat(2) @(posedge PCLK_i);
        //PENABLE_i = 0;

        PSEL_i    = 0;

 //---------------------------------------------------------------------------------------      

//-----------RECEIPTION_TEST_END---------------------------

// End of Simulation
        #100000;

        $finish;
    end

    // Generate Waveform
    initial begin
        $dumpvars;
        $dumpfile("apb_uart_tx_dump.vcd");
    end

    // Monitor signals
    initial begin
        $monitor($time, 
             " ns || PADDR_i = %h | PWRITE_i = %b | PWDATA_i = %h | PRDATA_o = %h | PREADY_o = %b | PSLVERR_o = %b | tx_line = %b | rx_line = %b",
             PADDR_i, PWRITE_i, PWDATA_i, PRDATA_o, PREADY_o, PSLVERR_o, tx_line,rx_line);
    end

endmodule



