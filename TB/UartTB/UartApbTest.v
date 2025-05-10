
`timescale 1ns/1ps

module tb_top;

    // Parameters
    parameter DEPTH = 1024;

    // Clock and reset
    reg PCLK_i;
    reg PRESETn_i;

    // APB Interface
    reg [$clog2(DEPTH)-1:0] PADDR_i;
    reg PWRITE_i;
    reg [7:0] PWDATA_i;
    reg PSEL_i;
    reg PENABLE_i;
    wire [7:0] PRDATA_o;
    wire PREADY_o;
    wire PSLVERR_o;

    // UART Signals
    reg rx_line;
    wire tx_line;

    // Instantiate DUT (Device Under Test)
    uart_top #(
        .DEPTH(DEPTH)
    ) uut (
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

    // Clock Generation
    initial begin
        PCLK_i = 0;
        forever #5 PCLK_i = ~PCLK_i;  // 10ns period clock
    end

    // Reset Sequence
    initial begin
        PRESETn_i = 0;
        #20 PRESETn_i = 1;
    end

    // Test Scenarios
    initial begin
        // Scenario 1: Write and Read from TX FIFO
        @(negedge PRESETn_i);
        @(posedge PRESETn_i);
       // wait(PRESETn_i);
        test_tx_fifo_write_read();

        // Scenario 2: Write and Read from RX FIFO
        @(posedge PCLK_i);
        test_rx_fifo_write_read();

        // Scenario 3: Write to Control Register and Read Status
        @(posedge PCLK_i);
        test_control_reg();

        // Scenario 4: Test Interrupt Register Write and Read
        @(posedge PCLK_i);
        test_interrupt_reg();

        // Scenario 5: Invalid Address Handling
        @(posedge PCLK_i);
        test_invalid_address();

        $finish;
    end

    // Test TX FIFO Write and Read
    task test_tx_fifo_write_read();
        begin
            $display("Scenario 1: Write and Read from TX FIFO");
            @(posedge PCLK_i);
            PADDR_i = 5'h0;  // TX FIFO address
            PWRITE_i = 1;
            PWDATA_i = 8'hA5;
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            PWRITE_i = 0;
            PENABLE_i = 0;

            #10;
            if (uut.uart_core_inst.tx_fifo.push_data_in !== 8'hA5) begin
                $display("Error: TX FIFO Write/Read mismatch.");
            end else begin
                $display("TX FIFO Write/Read successful.");
            end
        end
    endtask

    // Test RX FIFO Write and Read
    task test_rx_fifo_write_read();
        begin
            $display("Scenario 2: Write and Read from RX FIFO");
            rx_line = 1'b1;  // Simulate incoming data
            @(posedge PCLK_i);

            PADDR_i = 5'h4;  // RX FIFO address
            PWRITE_i = 0;
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            PENABLE_i = 0;

            #10;
            if (PRDATA_o !== 8'hFF) begin  // Expected value may vary based on simulation
                $display("Error: RX FIFO Read mismatch.");
            end else begin
                $display("RX FIFO Read successful.");
            end
        end
    endtask

    // Test Control Register Write and Read
    task test_control_reg();
        begin
            $display("Scenario 3: Write to Control Register and Read Status");
            @(posedge PCLK_i);
            PADDR_i = 5'h8;  // Control register address
            PWRITE_i = 1;
            PWDATA_i = 8'b00010110;  // Setting wr_uart, rd_uart, parity_type, baud_rate
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            PWRITE_i = 0;
            PENABLE_i = 0;

            @(posedge PCLK_i);
            PADDR_i = 5'h8;
            PWRITE_i = 0;
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            if (PRDATA_o !== 8'b00010110) begin
                $display("Error: Control Register Write/Read mismatch.");
            end else begin
                $display("Control Register Write/Read successful.");
            end
            PENABLE_i = 0;
        end
    endtask

    // Test Interrupt Register Write and Read
    task test_interrupt_reg();
        begin
            $display("Scenario 4: Test Interrupt Register Write and Read");
            @(posedge PCLK_i);
            PADDR_i = 5'h10;  // Interrupt register address
            PWRITE_i = 1;
            PWDATA_i = 8'b00000001;  // Enable interrupt
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            PWRITE_i = 0;
            PENABLE_i = 0;

            @(posedge PCLK_i);
            PADDR_i = 5'h10;
            PWRITE_i = 0;
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            if (PRDATA_o[0] !== 1'b1) begin
                $display("Error: Interrupt Register Write/Read mismatch.");
            end else begin
                $display("Interrupt Register Write/Read successful.");
            end
            PENABLE_i = 0;
        end
    endtask

    // Test Invalid Address Handling
    task test_invalid_address();
        begin
            $display("Scenario 5: Invalid Address Handling");
            @(posedge PCLK_i);
            PADDR_i = 5'h14;  // Invalid address
            PWRITE_i = 1;
            PWDATA_i = 8'hAA;
            PSEL_i = 1;
            PENABLE_i = 1;

            @(posedge PCLK_i);
            if (PSLVERR_o !== 1'b1) begin
                $display("Error: Invalid address not detected.");
            end else begin
                $display("Invalid address handling successful.");
            end
            PENABLE_i = 0;
        end
    endtask

endmodule
