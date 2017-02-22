`timescale 1ns / 1ps

module uart_tx (
        clk,
        PIN_TX,
        word,
        tx_start,
        busy
    );


// ---------- INCLUDES ----------
    `include "verilog_utils.vh"


// ---------- PARAMETERS ----------
    parameter IN_CLK_FR = 100000000;
    parameter BAUD_RATE = 9600;
    parameter DATA_BITS = 8;

 
// ---------- LOCAL PARAMETERS ----------
    localparam UART_INACTIVE_LINE = 1;
    localparam UART_START_BIT_VAL = 0;
    localparam UART_STOP_BIT_VAL  = 1;
    //
    localparam CTR_0_BITS = ceil_log2( DATA_BITS );


// ---------- INPUTS AND OUTPUTS ----------
    input  wire                 clk;
    output reg                  PIN_TX   = UART_INACTIVE_LINE;
    input  wire [DATA_BITS-1:0] word;
    input  wire                 tx_start;
    output reg                  busy     = 0;


// ---------- MODULE ----------

    // -- Generate transmission clock
    wire clk_en_tx;
    
    enable_clk_gen #(
        .CLK_FREQ (IN_CLK_FR),
        .EN_FREQ  (BAUD_RATE)
    )
    clk_en_tx_1 (
        .clk    (clk), 
        .out_en (clk_en_tx)
    );

    // -- Tx FSM
    reg [1:0]            state     = 0;
    reg [DATA_BITS-1:0]  word_save = 0;
    reg [CTR_0_BITS-1:0] count     = 0;
    
    always @( posedge clk ) begin

        // State 0: Atop bit & Wait for start signal
        if( state == 0 ) begin
            PIN_TX <= UART_INACTIVE_LINE;
            count  <= 0;
            if( tx_start ) begin
                word_save <= word;
                state     <= 1;
                busy      <= 1;
            end
            else
                busy   <= 0;
            
        end

        // State 1: Start bit
        if( state == 1 ) begin
            if( clk_en_tx ) begin
                PIN_TX <= UART_START_BIT_VAL;
                state  <= 2;
            end
        end

        // State 2: Data bits
        if( state == 2 ) begin
            if( clk_en_tx ) begin
                if( count != DATA_BITS ) begin
                    PIN_TX    <= word_save[0];
                    word_save <= { 1'b0, word_save[DATA_BITS-1:1] };
                    count     <= count + 1'b1;
                end
                else begin // End of transmission, put stop bit on line
                    PIN_TX <= UART_STOP_BIT_VAL;
                    busy   <= 0;
                    state  <= 0;
                end
            end
        end

    end // always

endmodule
