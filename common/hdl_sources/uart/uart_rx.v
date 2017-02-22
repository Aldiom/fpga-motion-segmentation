`timescale 1ns / 1ps

module uart_rx (
        clk,
        PIN_RX,
        word,
        word_ready
    );    


// ---------- INCLUDES ----------
    `include "verilog_utils.vh"


// ---------- PARAMETERS ----------
    parameter IN_CLK_FR    = 100000000;
    parameter BAUD_RATE    = 9600;
    parameter DATA_BITS    = 8;
    // Advanced configuration (not normally needed)
    parameter OVERSAMPLING = 8;
    parameter SAMP_TOTAL   = 3;

 
// ---------- LOCAL PARAMETERS ----------
    localparam CTR_0_BITS    = ceil_log2( DATA_BITS-1 );
    localparam CTR_SAMP_BITS = ceil_log2( OVERSAMPLING-1 );
    //
    localparam SAMP_START    = (OVERSAMPLING/2) - (SAMP_TOTAL/2);
    localparam SAMP_END      = SAMP_START + SAMP_TOTAL;
    localparam SAMP_MAX      = SAMP_TOTAL/2;


// ---------- INPUTS AND OUTPUTS ----------
    input  wire       clk;
    input  wire       PIN_RX;
    output reg  [7:0] word       = 0;
    output reg        word_ready = 0;


// ---------- MODULE ----------

    // -- Generate receiver clock to oversample the data line
    wire clk_en_oversamp_rx;
    
    enable_clk_gen #(
        .CLK_FREQ (IN_CLK_FR),
        .EN_FREQ  (OVERSAMPLING*BAUD_RATE)
    )
    clk_en_rx_1 (
        .clk    (clk), 
        .out_en (clk_en_oversamp_rx)
    );

    // -- Synchronization and sampling submodule
    reg [0:0] waiting_sync  = 1; // in
    reg [0:0] sampling_done = 0; // out
    reg [0:0] sampled_bit   = 0; // out
    // Internal signals
    reg [0:0]               FSM_0_state  = 0;
    reg [CTR_SAMP_BITS-1:0] sampling_counter  = 0;
    reg [CTR_SAMP_BITS-1:0] data_line_counter = 0;
    //reg [0:0]               prev_PIN_RX       = 1;
    
    always @( posedge clk ) begin
        if( clk_en_oversamp_rx ) begin
            //prev_PIN_RX <= PIN_RX;
            // State 0: Sample 0 (clock synchronization, start bit, or first sample)
            if( FSM_0_state == 0 ) begin // Sample 0
                sampling_counter  <= 1;
                data_line_counter <= 0;
                if( (waiting_sync == 1) && (PIN_RX == 0) ) begin
                    FSM_0_state <= 1;
                end
                if( waiting_sync == 0 )
                    FSM_0_state <= 1;
                
                    
            end
            // State 1: Samples 1<->(OVERSAMPLING-1) (Normal sampling)
            if( FSM_0_state == 1 ) begin
                if( (sampling_counter > SAMP_START-1) && (sampling_counter < SAMP_END) ) begin
                    data_line_counter <= data_line_counter + PIN_RX;
                end
                if( sampling_counter == SAMP_END ) begin
                    sampling_done <= 1;
                    sampled_bit   <= (data_line_counter > SAMP_MAX );
                end
                
                if( sampling_counter == OVERSAMPLING-1 ) begin
                    FSM_0_state   <= 0;
                end
                else
                    sampling_counter  <= sampling_counter + 1'b1;
            end // State
        end
        else
            sampling_done <= 0;
    end
    
    // -- Control FSM
    reg [1:0]            FSM_1_state  = 0;
    reg [DATA_BITS-1:0]  word_save    = 0;
    reg [CTR_0_BITS-1:0] bits_counter = 0;
    
    always @( posedge clk ) begin
        if( sampling_done ) begin
            // State 0: Waiting start bit
            if( FSM_1_state == 0 ) begin
                bits_counter <= 0;
                if( sampled_bit == 0 ) begin // Correct start bit
                    waiting_sync <= 0;
                    FSM_1_state  <= 1;
                end
                else
                    waiting_sync <= 1;
            end
            // State 1: Receiving word
            if( FSM_1_state == 1 ) begin
                word_save <= { sampled_bit, word_save[DATA_BITS-1:1] };
                if( bits_counter == DATA_BITS-1 ) begin
                    bits_counter <= 0;
                    FSM_1_state  <= 2;
                end
                else begin
                    bits_counter <= bits_counter + 1'b1;
                end
            end
            // State 2: Receiving stop bit
            if( FSM_1_state == 2 ) begin
                waiting_sync <= 1;
                FSM_1_state  <= 0;
                if( sampled_bit == 1 ) begin // Correct stop bit
                    word       <= word_save;
                    word_ready <= 1;
                end 
            end
        end
        else
            word_ready <= 0;
    end

endmodule
