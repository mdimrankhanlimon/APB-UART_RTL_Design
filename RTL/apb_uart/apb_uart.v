//-------------------------------------------------
//      Design      : Uart APB Slave 
//      Designer    : rashid.shabab@siliconova.com
//      company     : Siliconova
//
//      Version     : 1.0
//      Created     : 25 Aug, 2024
//      Last updated: 20 Sep, 2024   
//--------------------------------------------------


module apb_uart_slave #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024
)(
    // APB signal interface
    input  wire                  PCLK_i,
    input  wire                  PRESETn_i,
    input  wire [$clog2(DEPTH)-1:0] PADDR_i,
    input  wire                  PWRITE_i,
    input  wire [DATA_WIDTH-1:0] PWDATA_i,
    input  wire                  PSEL_i,
    input  wire                  PENABLE_i,
    output reg [DATA_WIDTH-1:0]  PRDATA_o,
    output reg                   PREADY_o,
    output reg                   PSLVERR_o,

    // UART Signals
    input  wire                  rx_line,
    output wire                  tx_line
);

    // Register offsets
    localparam CONTROL_REG_OFFSET  = 8'h00;
    localparam TX_DATA_REG_OFFSET  = 8'h08;
    localparam RX_DATA_REG_OFFSET  = 8'h10;
    localparam ERROR_REG_OFFSET    = 8'h18;
    localparam STATUS_REG_OFFSET   = 8'h20;

    // APB States
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    // Internal registers
    reg [DATA_WIDTH-1:0] control_reg;
    reg [DATA_WIDTH-1:0] tx_data_reg;
    reg [DATA_WIDTH-1:0] rx_data_reg;
    reg [DATA_WIDTH-1:0] error_reg;
    reg [DATA_WIDTH-1:0] status_reg;

    // Internal wires for UART core outputs
    wire [DATA_WIDTH-1:0] uart_rx_data;
    wire [2:0] uart_error_flags;

    // UART core interface signals
    reg wr_uart;
    reg rd_uart;
    reg [DATA_WIDTH-1:0] wr_data;
    reg send;
    wire [1:0] baud_rate;
    wire [1:0] parity_type;

    assign baud_rate = control_reg[2:1];
    assign parity_type = control_reg[4:3];
    assign send = control_reg[0];

    // UART Core Instantiation
    Uart_core uart_core (
        .clock(PCLK_i),
        .reset_n(PRESETn_i),
        .baud_rate(baud_rate),
        .parity_type(parity_type),
        .send(send),
        .wr_uart(wr_uart),
        .rd_uart(rd_uart),
        .wr_data(tx_data_reg),
        .rx_line(rx_line),
        .tx_line(tx_line),
        .rd_data(uart_rx_data),
        .tx_fifo_full(status_reg[1]),   
        .tx_fifo_empty(status_reg[0]),
        .tx_fifo_err(status_reg[2]),
        .rx_fifo_full(status_reg[4]),
        .rx_fifo_empty(status_reg[3]),
        .rx_fifo_err(status_reg[5]),
        .error_flag(uart_error_flags)
    );

    // Internal signals
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] count;
    reg flop;
    reg flop2;
    wire temp_err;

    // Count logic for delay detection
    always @(posedge PCLK_i) begin
        if (PSEL_i & ~PENABLE_i & PREADY_o) begin
            count <= count + 1;
        end else begin
            count <= 0;
        end
    end

    // Flop logic for error detection
    always @(posedge PCLK_i) begin
        flop <= temp_err;
        flop2 <= flop;
    end

    assign temp_err = (count >= 2'd2);
    assign wr_uart = PWRITE_i & PSEL_i & PENABLE_i & PREADY_o & (PADDR_i == TX_DATA_REG_OFFSET);
    assign rd_uart = ~PWRITE_i & PSEL_i & PENABLE_i & PREADY_o & (PADDR_i == RX_DATA_REG_OFFSET);
    assign status_reg[7:6] = 2'b00;

    // Update registers on PCLK_i
    always @(posedge PCLK_i , negedge PRESETn_i) begin
        if (!PRESETn_i) begin
            state       <= IDLE;
            PRDATA_o    <= 0;
            PREADY_o    <= 0;
            PSLVERR_o   <= 0;
            control_reg <= 0;
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            error_reg   <= 0;
            count       <= 0;
            flop        <= 0;
            flop2       <= 0;
        end else begin
            state <= next_state;
            // Update rx_data_reg, error_reg, status_reg based on UART core outputs
            if (rd_uart && !status_reg[3]) begin
                rx_data_reg <= uart_rx_data;  // Update rx_data_reg
            end
            if (uart_error_flags !=0) begin
                error_reg <=  {5'b00000, uart_error_flags};  // Update error_reg
            end
        end
    end

    // APB FSM
    always @(*) begin
        case (state)
            IDLE: begin
                PREADY_o = 0;
                PRDATA_o = 0;
                PSLVERR_o = 0;
                if (PSEL_i) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end
            end

            SETUP: begin
                PREADY_o = 0;
                PRDATA_o = 0;
                PSLVERR_o = 0;
                if (PENABLE_i) begin
                    next_state = ACCESS;
                end else begin
                    next_state = SETUP;
                end
            end

            ACCESS: begin
                PREADY_o = 1;
                PSLVERR_o = ((PADDR_i != CONTROL_REG_OFFSET &&
                             PADDR_i != TX_DATA_REG_OFFSET &&
                             PADDR_i != RX_DATA_REG_OFFSET &&
                             PADDR_i != ERROR_REG_OFFSET &&
                             PADDR_i != STATUS_REG_OFFSET)) || 
                             (|error_reg[2:0]);
               if (!PWRITE_i) begin 
                    case (PADDR_i)
                        CONTROL_REG_OFFSET: PRDATA_o = control_reg;
                        TX_DATA_REG_OFFSET: PRDATA_o = tx_data_reg;
                        RX_DATA_REG_OFFSET: PRDATA_o = rx_data_reg;
                        ERROR_REG_OFFSET:   PRDATA_o = error_reg;
                        STATUS_REG_OFFSET:  PRDATA_o = status_reg;
                    endcase
                end

                if (PWRITE_i) begin
                    case (PADDR_i)
                        CONTROL_REG_OFFSET: control_reg = PWDATA_i;
                        TX_DATA_REG_OFFSET: tx_data_reg = PWDATA_i;
                    endcase
                end
                next_state = PSEL_i ? SETUP : IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule




