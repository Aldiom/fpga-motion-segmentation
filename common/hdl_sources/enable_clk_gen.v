`timescale 1ns / 1ps


module enable_clk_gen (
        clk,
        out_en
    );


// ---------- INCLUDES ----------
    `include "verilog_utils.vh"


// ---------- PARAMETERS ----------
    parameter CLK_FREQ = 100000000;
    parameter EN_FREQ  = 1000;
    // Advanced configuration (not normally needed)
    parameter MAX_ERROR_PERC = 10;


// ---------- LOCAL PARAMETERS ----------   
	localparam COUNTER_LIMIT = CLK_FREQ/EN_FREQ;
    localparam COUNTER_BITS  = ceil_log2( COUNTER_LIMIT-1 );
    //
    localparam real CURR_ERROR_PERC = (100.0*(CLK_FREQ-COUNTER_LIMIT*EN_FREQ))/CLK_FREQ;


// ---------- INPUTS AND OUTPUTS ----------
    input  wire clk;
    output reg  out_en = 0;


// ---------- MODULE ----------
    // -- Validate parameters (Design Rule Check)
    initial begin
        if( CLK_FREQ/2 < EN_FREQ ) begin
            $display( "DRC ERROR: Requested freq. (%d) is not possible (max %d)", EN_FREQ, CLK_FREQ/2 );
            $finish();
        end
        if( CURR_ERROR_PERC > MAX_ERROR_PERC ) begin
            $display( "DRC ERROR: Requested error (%d%%) is not possible (current is %.2f%%)", MAX_ERROR_PERC, CURR_ERROR_PERC );
            $finish();
        end
        
    end

	reg [COUNTER_BITS-1:0] counter = 0;

	always @( posedge clk ) begin
		if( counter == COUNTER_LIMIT-1 ) begin 
			counter <= 0;
			out_en  <= 1;
		end
		else begin
			counter <= counter + 1'b1;
			out_en  <= 0;
		end
	end


endmodule
