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
	input  wire        foregnd_px,
	output wire        border
	);
	
	// ---------- PARAMETERS ----------
	//none
	
	// ---------- LOCAL PARAMETERS ----------
	localparam [10:0] H_IMG_RES = 640;
	localparam [10:0] V_IMG_RES = 480;
	localparam H_BITS = ceil_log2(H_IMG_RES-1);
	localparam V_BITS = ceil_log2(V_IMG_RES-1);
	localparam BOX_BS = 2*(H_BITS + V_BITS);
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
	reg saving_boxes = 0;
	reg [B_BITS-1:0] box_count = 0;
	reg [2:0] line_state = 0;
	reg seg_en = 1;
	
	wire [MAX_OBJS-1:0] match_mask;
	reg  [B_BITS-1:0] match_tag_hi;
	reg  [B_BITS-1:0] match_tag_lo;
	
	reg [MAX_OBJS-1:0] valid_mask = 0;
	reg [10:0] top [0:MAX_OBJ_NUM-1], top2 [0:MAX_OBJ_NUM-1];
	reg [10:0] bottom [0:MAX_OBJ_NUM-1], bottom2 [0:MAX_OBJ_NUM-1];
	reg [10:0] left [0:MAX_OBJ_NUM-1], left2 [0:MAX_OBJ_NUM-1];
	reg [10:0] right [0:MAX_OBJ_NUM-1], right2 [0:MAX_OBJ_NUM-1];
	reg [MAX_OBJS*2*(H_BITS+V_BITS)-1:0] boxes = 0;
	
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
		if(proc_fg_px && seg_en) begin
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
		else if(seg_en) begin
			prev_pix <= 0;
			if(curr_line)
				line_1[vid_hpos] <= 0;
			else
				line_0[vid_hpos] <= 0;			
		end
		
		// Signal logic to make the previous block work
		if(vid_hpos == H_IMG_RES - 1) begin //end of line... you have like 150 cycles until next 
			curr_line <= ~curr_line;
			if(vpos_off2 == V_IMG_RES-1) begin //end of frame
				saving_boxes <= 1;
				box_count <= 0;
			end
		end
	
		if(line_state == 3'd0) begin //normal shifting
			seg_en <= 1'b1;
			if(vid_hpos + 11'd2 <= H_IMG_RES - 1) begin
				if(curr_line)
					prev_line <= {prev_line[0+:2*B_BITS], line_0[vid_hpos+11'd2]};
				else
					prev_line <= {prev_line[0+:2*B_BITS], line_1[vid_hpos+11'd2]};
			end
			else begin
				prev_line <= {prev_line[0+:2*B_BITS], {B_BITS{1'b0}}};
				line_state <= 3'd1;
			end
		end
		else if(line_state == 3'd1) begin //preparing shift register for new line
			if(curr_line)
				prev_line <= {prev_line[0+:2*B_BITS], line_0[0]};
			else
				prev_line <= {prev_line[0+:2*B_BITS], line_1[0]};
			seg_en <= 1'b0;
			line_state <= 3'd2;
		end
		else if(line_state == 3'd2) begin //shifting data for pixel 0 (1)
			if(curr_line)
				prev_line <= {prev_line[0+:2*B_BITS], line_0[1]};
			else
				prev_line <= {prev_line[0+:2*B_BITS], line_1[1]};
			seg_en <= 1'b1;
			line_state <= 3'd3;
		end	
		else if(line_state == 3'd3)  begin //shifting data for pixel 1 (2)
			if(curr_line)
				prev_line <= {prev_line[0+:2*B_BITS], line_0[2]};
			else
				prev_line <= {prev_line[0+:2*B_BITS], line_1[2]};
			seg_en <= 1'b1;
			line_state <= 3'd4;
		end
		else if(line_state == 3'd4) begin //prepare for pixel 2 (3) but deactivate processing
			if(curr_line)
				prev_line <= {prev_line[0+:2*B_BITS], line_0[3]};
			else
				prev_line <= {prev_line[0+:2*B_BITS], line_1[3]};
			seg_en <= 1'b0;
			line_state <= 3'd5;			
		end
		else if(vid_hpos == 11'b1) begin //wait for line start
			line_state <= 3'b0;
			seg_en <= 1'b1;
		end
		
		// box data saving
		if(saving_boxes) begin
			if(blob_count > 0) begin
				if(valid_mask[box_count]) begin
					boxes[box_count*BOX_BS+:BOX_BS] <= {top[box_count][V_BITS-1:0],
														bottom[box_count][V_BITS-1:0], 
														left[box_count][H_BITS-1:0], 
														right[box_count][H_BITS-1:0]};
					blob_count <= blob_count - 1;
				end
				box_count <= box_count + 1;
			end
			else begin
				saving_boxes <= 0;
			end
		end
	end
	
	reg [MAX_OBJS-1:0] borders;
		
	always @(posedge app_clk) begin
		for(n=0; n<MAX_OBJS; n=n+1) begin
			borders[n] <= (((vid_vpos[V_BITS-1:0] == boxes[BOX_BS*(n+1)-V_BITS +: V_BITS]) || 
							(vid_vpos[V_BITS-1:0] == boxes[BOX_BS*n+2*H_BITS +: V_BITS])) && 
						   ((vid_hpos[H_BITS-1:0] >= boxes[BOX_BS*n+H_BITS +: H_BITS]) && 
							(vid_hpos[H_BITS-1:0] <= boxes[BOX_BS*n +: H_BITS]))) ||
						  (((vid_vpos[V_BITS-1:0] >= boxes[BOX_BS*(n+1)-V_BITS +: V_BITS]) && 
							(vid_vpos[V_BITS-1:0] <= boxes[BOX_BS*n+2*H_BITS +: V_BITS])) && 
						   ((vid_hpos[H_BITS-1:0] == boxes[BOX_BS*n+H_BITS +: H_BITS]) || 
							(vid_hpos[H_BITS-1:0] == boxes[BOX_BS*n +: H_BITS])));
		end
	end

	assign border = |borders;

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
		pre_buff      <= {24{filtered_px}};//{ Data_OUT_RED, Data_OUT_GREEN, Data_OUT_BLUE };
		vid_data_out  <= pre_buff;
	end

endmodule
