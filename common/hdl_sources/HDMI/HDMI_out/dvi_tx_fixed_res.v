//`default_nettype none
`timescale 1ns / 1ps

module dvi_tx_fixed_res (
        // Clocks
        p_clk_x1,
        p_clk_x2,
        p_clk_x10,
        serdesstrobe,
        // Reset
        reset,
        // Pixel coordinates
        HPos,
        VPos,
        // Video data
        red_data,
        green_data,
        blue_data,
        //
        active,
        preload_vid_line,
        h_sync,
        // HDMI physical interface
        TMDS_OUT,
        TMDS_OUTB
    );

// ---------- INCLUDES ----------
`include "verilog_utils.vh"


// ---------- PARAMETERS ----------
    // Resolution (active pixels)
    parameter H_RES_PIX = 640;
    parameter V_RES_PIX = 480;
    // Horizontal timing
    parameter H_FN_PRCH = 16; // Front porch
    parameter H_SYNC_PW = 96; // Pulse width
    parameter H_BK_PRCH = 48; // Back porch
    // Vertical timing
    parameter V_FN_PRCH = 10; // Front porch
    parameter V_SYNC_PW = 2;  // Pulse width
    parameter V_BK_PRCH = 33; // Back porch
    // Signal polarity
    parameter [0:0] H_SYNC_POL = 0;
    parameter [0:0] V_SYNC_POL = 0;
    // Data read latency
    parameter LATENCY = 0;
    // Optional parameters. Included for compatibility.
    // Default value (0) will automatically calculate the ports width. 
    parameter H_POS_BITS = 0;
    parameter V_POS_BITS = 0;


// ---------- LOCAL PARAMETERS ----------
    localparam H_POSIT_BITS = (H_POS_BITS!=0)? (H_POS_BITS) : (ceil_log2(H_RES_PIX-1));
    localparam V_POSIT_BITS = (V_POS_BITS!=0)? (V_POS_BITS) : (ceil_log2(V_RES_PIX-1));


// ---------- INPUTS AND OUTPUTS ----------
    // Clocks
    input  wire       p_clk_x1;
    input  wire       p_clk_x2;
    input  wire       p_clk_x10;
    input  wire       serdesstrobe;
    // Reset
    input  wire       reset;
    // Pixel coordinates
    output wire [H_POSIT_BITS-1:0] HPos;
	output wire [V_POSIT_BITS-1:0] VPos;
    // Video data
    input  wire [7:0] red_data;
	input  wire [7:0] green_data;
	input  wire [7:0] blue_data;
    //
    output wire       active;
    output wire       preload_vid_line;
    output wire       h_sync;
    // HDMI physical interface
    output wire [3:0] TMDS_OUT;
    output wire [3:0] TMDS_OUTB;


// ---------- MODULE ----------

    // -- Timing controller
    wire HSync, VSync, active_send;

    h_sync__v_sync__gen #(
        .H_PIXELS   (H_RES_PIX),
        .V_LINES    (V_RES_PIX),
        .H_FN_PRCH  (H_FN_PRCH),
        .H_SYNC_PW  (H_SYNC_PW),
        .H_BK_PRCH  (H_BK_PRCH),
        .V_FN_PRCH  (V_FN_PRCH),
        .V_SYNC_PW  (V_SYNC_PW),
        .V_BK_PRCH  (V_BK_PRCH),
        .H_SYNC_POL (H_SYNC_POL),
        .V_SYNC_POL (V_SYNC_POL)
    )
    video_timing_gen_1 (
        .clk         (p_clk_x1),
        .restart     (reset),
        //
        .h_sync      (HSync),
        .v_sync      (VSync),
        //
        .h_count_req          (HPos),
        .v_count_req          (VPos),
        .active_req_data      (active),
        .active_send          (active_send),
        .blanking_active_line (preload_vid_line)
	);
    
    assign h_sync = HSync;

    // -- Compensate latency
    wire HSync__lat_fix, VSync__lat_fix, active__lat_fix;
    
    sig_delay #(
        .BUS_BITS (3),
        .DELAY    (LATENCY)
    )
    latency_fix (
		.clk   (p_clk_x1), 
		.i_bus ({HSync,          VSync,          active_send}), 
		.o_bus ({HSync__lat_fix, VSync__lat_fix, active__lat_fix})
	);


    // -- Video transmissor
    dvi_encoder_top
    dvi_tx0 (
        .pclk        (p_clk_x1),
        .pclkx2      (p_clk_x2),
        .pclkx10     (p_clk_x10),
        .serdesstrobe(serdesstrobe),
        .rstin       (reset),
        .blue_din    (blue_data),
        .green_din   (green_data),
        .red_din     (red_data),
        .hsync       (HSync__lat_fix),
        .vsync       (VSync__lat_fix),
        .de          (active__lat_fix),
        .TMDS        (TMDS_OUT),
        .TMDSB       (TMDS_OUTB)
    );


endmodule
