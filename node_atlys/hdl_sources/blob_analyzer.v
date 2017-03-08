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
	localparam MAX_OBJ_NUM = 15;
	localparam B_BITS = ceil_log2(MAX_OBJ_NUM);
	localparam [B_BITS-1:0] MAX_OBJS = MAX_OBJ_NUM;
	
	// ---------- MODULE ----------
	`include "verilog_utils.vh"
	
	// Morphological processing ---------------------
	(* KEEP = "TRUE" *) wire eroded_fg_px;
	(* KEEP = "TRUE" *) wire proc_fg_px;
	wire [10:0] vpos_off = (vid_vpos > 2) ? vid_vpos - 3 : vid_vpos + V_IMG_RES - 3;
	wire [10:0] vpos_off2 = (vpos_off > 2) ? vpos_off - 3 : vpos_off + V_IMG_RES - 3;	

	eroder5
	opening_phase1(
		.clk(app_clk),
		.hpos(vid_hpos),
		.vpos(vid_vpos),
		.in_pix(foregnd_px),
		.out_pix(eroded_fg_px)
	);
	
	dilator5
	opening_phase2(
		.clk(app_clk),
		.hpos(vid_hpos),
		.vpos(vpos_off),
		.in_pix(eroded_fg_px),
		.out_pix(proc_fg_px)
	);
	
	// Segmentation ---------------------
	reg [B_BITS-1:0] line_0 [0:H_IMG_RES-1];
	reg [B_BITS-1:0] line_1 [0:H_IMG_RES-1];
	reg [3*B_BITS-1:0] prev_line = 0;
	reg [B_BITS-1:0] prev_pix = 0;
	reg [B_BITS-1:0] blob_count = 0;
	reg curr_line = 0;
	
	wire [MAX_OBJ_NUM-1:0] match_mask;
	wire [B_BITS-1:0] match_count;
	reg  [B_BITS-1:0] match_tag_hi;
	reg  [B_BITS-1:0] match_tag_lo;
	
	generate
		genvar i;
		for(i=1; i<=MAX_OBJ_NUM; i=i+1) begin: match_block
			assign match_mask[i-1] = (prev_line[0+:B_BITS] == i) || (prev_line[B_BITS+:B_BITS] == i)
									|| (prev_line[2*B_BITS+:B_BITS] == i) || (prev_pix == i);
			if(i > 2)
				wire [B_BITS-1:0] partial_count = match_block[i-1].partial_count + match_mask[i-1];
			else if(i == 2)
				wire [B_BITS-1:0] partial_count = match_mask[i-2] + match_mask[i-1];
		end
	endgenerate
	
	assign match_count = match_block[MAX_OBJ_NUM].partial_count;
	
	always @(*) begin
		match_tag_hi = 0;
		match_tag_lo = 0;
		//we have 2 priority encoders
		for(integer i=1; i<=MAX_OBJ_NUM; i=i+1) begin
			if(match_mask[i-1])
				matched_tag_hi = i;
		end
		for(integer i=MAX_OBJ_NUM; i>=1; i=i-1) begin
			if(match_mask[i-1])
				matched_tag_lo = i;
		end
	end
	
	always @(posedge app_clk) begin
		if(proc_fg_px) begin
			if(match_count == 0) begin //then it's a new blob
				blob_count <= (blob_count < MAX_OBJS) ? blob_count + 1 : MAX_OBJS;
				prev_pix <= blob_count + 1;
				if(curr_line)
					line_1[hpos] <= (blob_count < MAX_OBJS) ? blob_count + 1 : 0;
				else //check if last line... or first line?
					line_0[hpos] <= (blob_count < MAX_OBJS) ? blob_count + 1 : 0;;
			end
			else if(match_count == 1) begin //then it's a known blob
				prev_pix <= match_tag_lo;
				//and do stuff to get borders
				if(curr_line) 
					line_1[hpos] <= match_tag_lo;
				else
					line_0[hpos] <= match_tag_lo;				
			end
			else //then we have a blob collision
				prev_pix <= match_tag_hi;
				//and do stuff
				if(curr_line)
					line_1[hpos] <= match_tag_hi;
				else
					line_0[hpos] <= match_tag_hi;
		end
	end

	// Read buffer with video clock
	wire [18:0] wr_addr = vid_hpos + H_IMG_RES*vpos_off2;
	wire [18:0] rd_addr = vid_hpos + H_IMG_RES*vid_vpos;
	wire wr_en = (vid_hpos < H_IMG_RES) && (vpos_off < V_IMG_RES);
	wire filtered_px;
	
	dualport_RAM frame_mem (
		.clka(app_clk), // input clka
		.wea(wr_en), // input [0 : 0] wea
		.addra(wr_addr), // input [18 : 0] addra
		.dina(proc_fg_px), // input [0 : 0] dina
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
