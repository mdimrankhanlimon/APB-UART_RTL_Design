//-------------------------------------------------
//      Design      : Uart Top 
//      Designer    : rashid.shabab@siliconova.com
//      company     : Siliconova
//
//      Version     : 1.0
//      Created     : 20 Aug, 2024
//      Last updated: 22 Aug, 2024   
//--------------------------------------------------


module apb_uart_slave #(
    parameter DATA_WIDTH = 8,  // 8-bit data width
    parameter DEPTH = 1024
)(
    // APB signal interface
    input   wire                       PCLK_i,
    input   wire                       PRESETn_i,
    input   wire [($clog2(DEPTH))-1:0] PADDR_i,
    input   wire                       PWRITE_i,
    input   wire [DATA_WIDTH-1:0]      PWDATA_i,
    input   wire [(DATA_WIDTH/8)-1:0]  PSTRB_i,
    input   wire                       PSEL_i,
    input   wire                       PENABLE_i,
    output  reg  [DATA_WIDTH-1:0]      PRDATA_o,
    output  reg                        PREADY_o,
    output  reg                        PSLVERR_o,

    // UART signals
    output reg  [1:0] baud_rate,
    output reg  [1:0] parity_type,
    output reg        wr_uart,
    output reg        rd_uart,
    output reg  [7:0] wr_data,
    input  wire [7:0] rd_data,
    input  wire       tx_fifo_full,
    input  wire       tx_fifo_empty,
    input  wire       tx_fifo_err,
    input  wire       rx_fifo_full,
    input  wire       rx_fifo_empty,
    input  wire       rx_fifo_err,
    input  wire [2:0] error_flag,
    output reg        interrupt_en
);

    // Register addresses
    localparam TX_FIFO_ADDR   = 5'h0;
    localparam RX_FIFO_ADDR   = 5'h4;
    localparam CTRL_ADDR      = 5'h8;
    localparam STATUS_ADDR    = 5'hC;
    localparam INTERRUPT_ADDR = 5'h10;

    reg [1:0] nextstate;
    reg [1:0] prstate;
    
    parameter [1:0] IDLE   = 2'b00;
    parameter [1:0]	SETUP  = 2'b01;
    parameter [1:0] ACCESS = 2'b10;
    
    always @(posedge PCLK_i or negedge PRESETn_i) begin
        if (!PRESETn_i) begin
            prstate <= IDLE;     
        end else begin
            prstate <= nextstate;    
        end
    end

    always @(*) begin
        case (prstate)
            IDLE: begin
                PRDATA_o  = 8'd0;
                PSLVERR_o = 1'b0;
                PREADY_o  = 1'b0;
                nextstate = PSEL_i ? SETUP : IDLE;
            end
            
            SETUP: begin
                PREADY_o  = 1'b0;
                PRDATA_o  = 8'd0;
                PSLVERR_o = 1'b0;
                nextstate = PENABLE_i ? ACCESS : SETUP;
            end
    
            ACCESS: begin
                PREADY_o  = 1'b1;
                PSLVERR_o = 1'b0;
                case (PADDR_i[4:0]) // Address decoding for registers
                    TX_FIFO_ADDR: begin
                        if (PWRITE_i) begin
                            wr_data <= PWDATA_i;
                            wr_uart <= 1'b1;
                        end else begin
                            PRDATA_o <= 8'd0; // Write-only register
                        end
                    end
                    RX_FIFO_ADDR: begin
                        if (!PWRITE_i) begin
                            PRDATA_o <= rd_data;
                            rd_uart  <= 1'b1;
                        end else begin
                            PRDATA_o <= 8'd0; // Read-only register
                        end
                    end
                    CTRL_ADDR: begin
                        if (PWRITE_i) begin
                            wr_uart <= PWDATA_i[4];
                            rd_uart <= PWDATA_i[5];
                            parity_type <= PWDATA_i[3:2];
                            baud_rate <= PWDATA_i[1:0];
                        end else begin
                            PRDATA_o <= {2'b00, rd_uart, wr_uart, parity_type, baud_rate};
                        end
                    end
                    STATUS_ADDR: begin
                        if (!PWRITE_i) begin
                            PRDATA_o <= {2'b00, tx_fifo_err, tx_fifo_full, tx_fifo_empty,rx_fifo_err, rx_fifo_full, rx_fifo_empty};
                        end else begin
                            PRDATA_o <= 8'd0; // Read-only register
                        end
                    end
                    INTERRUPT_ADDR: begin
                        if (PWRITE_i) begin
                            interrupt_en <= PWDATA_i[0];
                        end else begin
                            PRDATA_o <= {error_flag, 1'b0, interrupt_en};
                        end
                    end
                    default: begin
                        PRDATA_o  <= 8'd0;
                        PSLVERR_o <= 1'b1;  // Invalid address
                    end
                endcase
                nextstate = PSEL_i ? SETUP : IDLE;
            end
        endcase
    end

    // Ensure proper ready signal handling
    always @(posedge PCLK_i) begin
        if (prstate == ACCESS) begin
            PREADY_o <= 1'b1;
        end else begin
            PREADY_o <= 1'b0;
        end
    end
endmodule

module uart_top #(
    parameter DEPTH = 1024  // Depth of the dual port RAM
)(
    input  wire                  PCLK_i,
    input  wire                  PRESETn_i,

    // APB Interface
    input  wire [$clog2(DEPTH)-1:0] PADDR_i,  // Address width based on DEPTH
    input  wire                  PWRITE_i,
    input  wire [7:0]            PWDATA_i,    // 8-bit data width
    input  wire                  PSEL_i,
    input  wire                  PENABLE_i,
    output wire [7:0]            PRDATA_o,    // 8-bit data width
    output wire                  PREADY_o,
    output wire                  PSLVERR_o,

    // UART Signals
    input  wire                  rx_line,
    output wire                  tx_line
);

    // Internal signals
    wire [7:0] rd_data;
    wire [7:0] wr_data;
    wire [1:0] baud_rate;
    wire [1:0] parity_type;
    wire [2:0] error_flag;
    wire       tx_fifo_full;
    wire       rx_fifo_empty;
    wire       interrupt_en;

    // Instantiate the dual port RAM as the register block
    dual_port_ram #(
        .DEPTH(DEPTH)
    ) reg_ram (
        .clk(PCLK_i),
        .resetn(PRESETn_i),
        .write_a(PWRITE_i & PENABLE_i & PSEL_i),
        .addr_a(PADDR_i),
        .datain_a(PWDATA_i),
        .read_b(~PWRITE_i & PSEL_i),
        .addr_b(PADDR_i),
        .dataout_b(PRDATA_o)
    );

    // Instantiate the APB Slave for UART
    apb_uart_slave #(
        .DATA_WIDTH(8),  // 8-bit data width
        .DEPTH(DEPTH)
    ) apb_uart_inst (
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
        
        .baud_rate(baud_rate),
        .parity_type(parity_type),
        .wr_uart(wr_uart),
        .rd_uart(rd_uart),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .tx_fifo_full(tx_fifo_full),
        .rx_fifo_empty(rx_fifo_empty),
        .error_flag(error_flag),
        .interrupt_en(interrupt_en)
    );

    // Instantiate the UART Core
    Uart_core uart_core_inst (
        .clock(PCLK_i),
        .reset_n(PRESETn_i),
        .baud_rate(baud_rate),
        .parity_type(parity_type),
        .wr_uart(wr_uart),
        .rd_uart(rd_uart),
        .wr_data(wr_data),
        .rx_line(rx_line),
        .tx_line(tx_line),
        .rd_data(rd_data),
        .tx_fifo_full(tx_fifo_full),
        .rx_fifo_empty(rx_fifo_empty),
        .error_flag(error_flag)
    );

endmodule
