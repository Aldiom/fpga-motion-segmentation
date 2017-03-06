`timescale 1ns / 1ps

module blob_analyzer(
	// Clocks an timer ticks
	input  wire        app_clk, // Same as vid_clk
	input  wire        app_timer_tick,
	input  wire        mem_clk,
	// Video display (read video line from RAM)
	input  wire        vid_preload_line,
	input  wire        vid_active_pix,
	input  wire [10:0] vid_hpos,
	input  wire [10:0] vid_vpos,
	output reg  [23:0] vid_data_out,
	input  wire        foregnd_px
	//output wire [24:0] rows
	);

	// ---------- PARAMETERS ----------
	//none
	
	// ---------- LOCAL PARAMETERS ----------
	localparam H_IMG_RES = 640;
	localparam V_IMG_RES = 480;
	localparam WIN_SIZE  = 5;
	localparam S_MASK_RAD = 4;
	
	// ---------- MODULE ----------
	`include "verilog_utils.vh"
	
	// Morphological processing ---------------------
	(* KEEP = "TRUE" *) wire eroded_fg_px;
	(* KEEP = "TRUE" *) wire proc_fg_px;
	wire [10:0] vpos_off = (vid_vpos > 2) ? vid_vpos - 3 : vid_vpos + V_IMG_RES - 3;
	//wire [24:0] rows;
	eroder1
	opening_phase1(
		.clk(app_clk),
		.hpos(vid_hpos),
		.vpos(vid_vpos),
		.in_pix(foregnd_px),
		.out_pix(eroded_fg_px)
		//.rows (rows)
	);
	/*
	dilator
	opening_phase2(
		.clk(app_clk),
		.hpos(vid_hpos),
		.vpos(vpos_off),
		.in_pix(eroded_fg_px),
		.out_pix(proc_fg_px)
	);
	*/
	// Segmentation ---------------------
	reg [3:0] prev_line [0:H_IMG_RES-1];
	reg [3:0] curr_line [0:H_IMG_RES-1];
	
	
	
	

	// Read buffer with video clock
	wire [10:0] vpos_off2 = (vpos_off > 2) ? vpos_off - 3 : vpos_off + V_IMG_RES - 3;
	
	wire [18:0] wr_addr = H_IMG_RES*vpos_off + vid_hpos;
	wire [18:0] rd_addr = H_IMG_RES*vid_vpos + vid_hpos;
	wire wr_en = (vid_hpos < H_IMG_RES) && (vpos_off < V_IMG_RES);
	wire filtered_px;
	
	dualport_RAM frame_mem (
		.clka(app_clk), // input clka
		.wea(wr_en), // input [0 : 0] wea
		.addra(wr_addr), // input [18 : 0] addra
		.dina(eroded_fg_px), // input [0 : 0] dina
		.clkb(app_clk), // input clkb
		.addrb(rd_addr), // input [18 : 0] addrb
		.doutb(filtered_px) // output [0 : 0] doutb
	);
	
	reg [23:0] pre_buff;
	
	always @( posedge app_clk ) begin
		// Display data
		/*
		Data_OUT_RED <= (vid_hpos < H_IMG_RES) ? (line_buffer_r[vid_hpos]) : (8'd0);
		Data_OUT_GREEN <= (vid_hpos < H_IMG_RES) ? (line_buffer_g[vid_hpos]) : (8'd0);
		Data_OUT_BLUE <= (vid_hpos < H_IMG_RES) ? (line_buffer_b[vid_hpos]) : (8'd0);	
		*/
		pre_buff      <= {24{filtered_px}} ;//{ Data_OUT_RED, Data_OUT_GREEN, Data_OUT_BLUE };
		vid_data_out  <= pre_buff;
	end

endmodule
