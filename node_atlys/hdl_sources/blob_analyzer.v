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
	);

	// ---------- PARAMETERS ----------
	//none
	
	// ---------- LOCAL PARAMETERS ----------
	localparam [10:0] H_IMG_RES = 640;
	localparam [10:0] V_IMG_RES = 480;
	localparam WIN_SIZE  = 5;
	localparam MAX_OBJ_NUM = 15;
	localparam B_BITS = ceil_log2(MAX_OBJ_NUM);
	localparam [B_BITS-1:0] MAX_OBJS = MAX_OBJ_NUM;
	
	// ---------- MODULE ----------
	`include "verilog_utils.vh"
	
	// Morphological processing ---------------------
	wire eroded_fg_px;
	wire proc_fg_px;
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
	reg  [B_BITS-1:0] match_tag_hi;
	reg  [B_BITS-1:0] match_tag_lo;
	
	reg [MAX_OBJ_NUM-1:0] valid_mask = 0;
	reg [10:0] top [0:MAX_OBJ_NUM-1], top2 [0:MAX_OBJ_NUM-1];
	reg [10:0] bottom [0:MAX_OBJ_NUM-1], bottom2 [0:MAX_OBJ_NUM-1];
	reg [10:0] left [0:MAX_OBJ_NUM-1], left2 [0:MAX_OBJ_NUM-1];
	reg [10:0] right [0:MAX_OBJ_NUM-1], right2 [0:MAX_OBJ_NUM-1];
	
	generate
		genvar i;
		for(i=1; i<=MAX_OBJ_NUM; i=i+1) begin: match_block
			assign match_mask[i-1] = (prev_line[0+:B_BITS] == i) || (prev_line[B_BITS+:B_BITS] == i)
									|| (prev_line[2*B_BITS+:B_BITS] == i) || (prev_pix == i);
		end
	endgenerate
	
	integer n;
	always @(*) begin
		match_tag_hi = 0;
		match_tag_lo = 0;
		//we have 2 priority encoders
		for(n=1; n<=MAX_OBJ_NUM; n=n+1) begin
			if(match_mask[n-1])
				match_tag_hi = n;
		end
		for(n=MAX_OBJ_NUM; n>=1; n=n-1) begin
			if(match_mask[n-1])
				match_tag_lo = n;
		end
	end
	
	always @(posedge app_clk) begin
		
		// the actual segmentation of blobs
		if(proc_fg_px) begin
			if(~|match_mask) begin //then it's a new blob
				blob_count <= (blob_count < MAX_OBJS) ? blob_count + 1 : MAX_OBJS;
				prev_pix <= (blob_count < MAX_OBJS) ? blob_count + 1 : 0;
				if(blob_count < MAX_OBJS) begin
				// note the arrays are duplicated, this is to make simultaneous reads in diff addresses
					{top[blob_count], top2[blob_count]} <= {2{vpos_off2}}; 
					{bottom[blob_count], bottom2[blob_count]} <= {2{vpos_off2}};
					{left[blob_count], left2[blob_count]} <= {2{vid_hpos}};
					{right[blob_count], right2[blob_count]} <= {2{vid_hpos}};
					valid_mask[blob_count] <= 1'b1;
				end
				if(blob_count < MAX_OBJS) begin
					if(curr_line) 
						line_1[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? blob_count + 1 : 0;
					else
						line_0[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? blob_count + 1 : 0;
				end
				else begin
					if(curr_line) 
						line_1[vid_hpos] <= 0;
					else
						line_0[vid_hpos] <= 0;
				end
			end
			else if(match_tag_hi == match_tag_lo) begin //then it's a known blob
				prev_pix <= match_tag_lo;
				//and do stuff to get borders
				if(bottom[match_tag_lo-1] < vpos_off2)
					{bottom[match_tag_lo-1], bottom2[match_tag_lo-1]} <= {2{vpos_off2}};
				if(left[match_tag_lo-1] > vid_hpos)
					{left[match_tag_lo-1], left2[match_tag_lo-1]} <= {2{vid_hpos}};
				if(right[match_tag_lo-1] < vid_hpos)
					{right[match_tag_lo-1], right2[match_tag_lo-1]} <= {2{vid_hpos}};
				//and write line buffer
				if(curr_line) 
					line_1[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? match_tag_lo : 0;
				else
					line_0[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? match_tag_lo : 0;			
			end
			else begin //then we have a blob collision
				prev_pix <= match_tag_lo;
				//and do stuff
				if(top[match_tag_lo-1] > top2[match_tag_hi-1])
					{top[match_tag_lo-1], top2[match_tag_lo-1]} <= {2{top2[match_tag_hi-1]}};
				if((bottom[match_tag_lo-1] < vpos_off2) || (bottom[match_tag_lo-1] < bottom2[match_tag_hi-1]))
				begin
					if(vpos_off2 < bottom[match_tag_hi-1])
						{bottom[match_tag_lo-1], bottom2[match_tag_lo-1]} <= {2{vpos_off2}};
					else
						{bottom[match_tag_lo-1], bottom2[match_tag_lo-1]} <= {2{bottom2[match_tag_hi-1]}};
				end
				if((left[match_tag_lo-1] > vid_hpos) || (left[match_tag_lo-1] > left[match_tag_hi-1]))
				begin
					if(vid_hpos > left[match_tag_hi-1])
						{left[match_tag_lo-1], left2[match_tag_lo-1]} <= {2{vid_hpos}};
					else
						{left[match_tag_lo-1], left2[match_tag_lo-1]} <= {2{left2[match_tag_hi-1]}};
				end
				if((right[match_tag_lo-1] < vid_hpos) || (right[match_tag_lo-1] < right[match_tag_hi-1]))
				begin
					if(vid_hpos < right[match_tag_hi-1])
						{right[match_tag_lo-1], right2[match_tag_lo-1]} <= {2{vid_hpos}};
					else
						{right[match_tag_lo-1], right2[match_tag_lo-1]} <= {2{right2[match_tag_hi-1]}};
				end
				valid_mask[match_tag_hi-1] <= 1'b0;
				//and write line buffer
				if(curr_line)
					line_1[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? match_tag_lo : 0;
				else
					line_0[vid_hpos] <= (vpos_off2 < V_IMG_RES-1) ? match_tag_lo : 0;
			end
		end
		else begin
			prev_pix <= 0;
			if(curr_line)
				line_1[vid_hpos] <= 0;
			else
				line_0[vid_hpos] <= 0;			
		end
		
		// Signal logic to make the previous block work
		if(vid_hpos == H_IMG_RES-1) begin //end of line... you have like 150 cycles until next 
			curr_line <= ~curr_line;
			if(vpos_off2 == V_IMG_RES-1) begin //end of frame
				valid_mask <= 0;
				blob_count <= 0;
				//and do something to save values
			end
		end
		
		// update the prev_line shift register 
		if(vid_hpos + 11'd2 <= H_IMG_RES - 1) begin
			if(curr_line)
				prev_line <= {prev_line[0+:2*B_BITS], line_0[vid_hpos+11'd2]};
			else
				prev_line <= {prev_line[0+:2*B_BITS], line_1[vid_hpos+11'd2]};
		end
		else
			prev_line <= {prev_line[0+:2*B_BITS], {B_BITS{1'b0}}};
	end
	
	//add state machine to write this... or think something better
	dualport_RAM box_mem (
		.clka(mem_clk), // input clka
		.wea(wr_en), // input [0 : 0] wea
		.addra(wr_addr), // input [18 : 0] addra
		.dina(proc_fg_px), // input [0 : 0] dina
		.clkb(app_clk), // input clkb
		.addrb(rd_addr), // input [18 : 0] addrb
		.doutb(filtered_px) // output [0 : 0] doutb
	);

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
	); //...Dragonborn
	
	reg [23:0] pre_buff;
	//FUS RO DAH!!
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
