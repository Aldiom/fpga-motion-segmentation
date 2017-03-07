`timescale 1ns / 1ps

module dilator5(
	input  wire        clk, 
	input  wire [10:0] hpos,
	input  wire [10:0] vpos,
	input  wire        in_pix,
	output wire        out_pix
	);

	`include "verilog_utils.vh"
	
	// ---------- PARAMETERS ----------
	parameter H_IMG_RES = 640;
	parameter V_IMG_RES = 480;
	parameter WIN_SIZE = 5; //must be odd
	parameter [WIN_SIZE**2-1:0] STRUCT_ELM = {5'b01110,
											  5'b11111,
											  5'b11111,
											  5'b11111,
											  5'b01110};

	// ---------- MODULE ----------
	reg [ceil_log2(WIN_SIZE)-1:0] line_wr = 0;
	
	always @(posedge clk) begin
		// Save a few lines of input image in buffer
		if(hpos == H_IMG_RES-1)
			line_wr <= (line_wr < WIN_SIZE) ? line_wr + 1 : 0;
	end
	
	wire [10:0] vpos_off = (vpos > WIN_SIZE/2) ? vpos - WIN_SIZE/2 - 1 : vpos + V_IMG_RES - WIN_SIZE/2 - 1;
	reg [(WIN_SIZE+1)*WIN_SIZE-1:0] sh_reg = 0;
	
	reg line0 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd0) begin
			line0[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*0+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*0+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*0+:WIN_SIZE] <= {line0[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*0+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*0+:WIN_SIZE] <= {line0[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*0+1 +: WIN_SIZE-1]};
		end
	end
	
	reg line1 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd1) begin
			line1[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*1+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*1+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*1+:WIN_SIZE] <= {line1[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*1+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*1+:WIN_SIZE] <= {line1[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*1+1 +: WIN_SIZE-1]};
		end
	end

	reg line2 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd2) begin
			line2[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*2+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*2+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*2+:WIN_SIZE] <= {line2[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*2+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*2+:WIN_SIZE] <= {line2[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*2+1 +: WIN_SIZE-1]};
		end
	end
	
	reg line3 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd3) begin
			line3[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*3+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*3+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*3+:WIN_SIZE] <= {line3[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*3+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*3+:WIN_SIZE] <= {line3[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*3+1 +: WIN_SIZE-1]};
		end
	end

	reg line4 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd4) begin
			line4[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*4+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*4+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*4+:WIN_SIZE] <= {line4[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*4+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*4+:WIN_SIZE] <= {line4[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*4+1 +: WIN_SIZE-1]};
		end
	end

	reg line5 [0:H_IMG_RES-1];
	always @(posedge clk) begin
		if(line_wr == 3'd5) begin
			line5[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*5+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*5+1 +: WIN_SIZE-1]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				sh_reg[WIN_SIZE*5+:WIN_SIZE] <= {line5[hpos + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*5+1 +: WIN_SIZE-1]};
			else
				sh_reg[WIN_SIZE*5+:WIN_SIZE] <= {line5[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
															sh_reg[WIN_SIZE*5+1 +: WIN_SIZE-1]};
		end
	end
	
	(* KEEP = "TRUE" *)
	reg [WIN_SIZE**2-1:0] rows = 0;
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel0;
	reg [WIN_SIZE-1:0] bmask0; //border mask
	always @(*) begin
		if(line_wr+0 < WIN_SIZE)
			lin_sel0 = line_wr+0+1;
		else
			lin_sel0 = line_wr+0-WIN_SIZE;
			
		bmask0 = {WIN_SIZE{1'b0}};
		if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) ) begin
			if( hpos + WIN_SIZE/2 >= H_IMG_RES - 1 )
				bmask0 = {WIN_SIZE{1'b1}} << (hpos + WIN_SIZE/2 - H_IMG_RES + 1);
			else if( hpos <= WIN_SIZE/2 )
				bmask0 = {WIN_SIZE{1'b1}} >> (WIN_SIZE/2 - hpos);
			else
				bmask0 = {WIN_SIZE{1'b1}};
		end
		rows[WIN_SIZE*0+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel0+:WIN_SIZE] & bmask0;
	end
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel1;
	reg [WIN_SIZE-1:0] bmask1; //border mask
	always @(*) begin
		if(line_wr+1 < WIN_SIZE)
			lin_sel1 = line_wr+1+1;
		else
			lin_sel1 = line_wr+1-WIN_SIZE;
			
		bmask1 = {WIN_SIZE{1'b0}};
		if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) ) begin
			if( hpos + WIN_SIZE/2 >= H_IMG_RES - 1 )
				bmask1 = {WIN_SIZE{1'b1}} << (hpos + WIN_SIZE/2 - H_IMG_RES + 1);
			else if( hpos <= WIN_SIZE/2 )
				bmask1 = {WIN_SIZE{1'b1}} >> (WIN_SIZE/2 - hpos);
			else
				bmask1 = {WIN_SIZE{1'b1}};
		end
		rows[WIN_SIZE*1+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel1+:WIN_SIZE] & bmask1;
	end
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel2;
	reg [WIN_SIZE-1:0] bmask2; //border mask
	always @(*) begin
		if(line_wr+2 < WIN_SIZE)
			lin_sel2 = line_wr+2+1;
		else
			lin_sel2 = line_wr+2-WIN_SIZE;
			
		bmask2 = {WIN_SIZE{1'b0}};
		if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) ) begin
			if( hpos + WIN_SIZE/2 >= H_IMG_RES - 1 )
				bmask2 = {WIN_SIZE{1'b1}} << (hpos + WIN_SIZE/2 - H_IMG_RES + 1);
			else if( hpos <= WIN_SIZE/2 )
				bmask2 = {WIN_SIZE{1'b1}} >> (WIN_SIZE/2 - hpos);
			else
				bmask2 = {WIN_SIZE{1'b1}};
		end
		rows[WIN_SIZE*2+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel2+:WIN_SIZE] & bmask2;
	end
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel3;
	reg [WIN_SIZE-1:0] bmask3; //border mask
	always @(*) begin
		if(line_wr+3 < WIN_SIZE)
			lin_sel3 = line_wr+3+1;
		else
			lin_sel3 = line_wr+3-WIN_SIZE;
			
		bmask3 = {WIN_SIZE{1'b0}};
		if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) ) begin
			if( hpos + WIN_SIZE/2 >= H_IMG_RES - 1 )
				bmask3 = {WIN_SIZE{1'b1}} << (hpos + WIN_SIZE/2 - H_IMG_RES + 1);
			else if( hpos <= WIN_SIZE/2 )
				bmask3 = {WIN_SIZE{1'b1}} >> (WIN_SIZE/2 - hpos);
			else
				bmask3 = {WIN_SIZE{1'b1}};
		end
		rows[WIN_SIZE*3+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel3+:WIN_SIZE] & bmask3;
	end
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel4;
	reg [WIN_SIZE-1:0] bmask4; //border mask
	always @(*) begin
		if(line_wr+4 < WIN_SIZE)
			lin_sel4 = line_wr+4+1;
		else
			lin_sel4 = line_wr+4-WIN_SIZE;
			
		bmask4 = {WIN_SIZE{1'b0}};
		if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) ) begin
			if( hpos + WIN_SIZE/2 >= H_IMG_RES - 1 )
				bmask4 = {WIN_SIZE{1'b1}} << (hpos + WIN_SIZE/2 - H_IMG_RES + 1);
			else if( hpos <= WIN_SIZE/2 )
				bmask4 = {WIN_SIZE{1'b1}} >> (WIN_SIZE/2 - hpos);
			else
				bmask4 = {WIN_SIZE{1'b1}};
		end
		rows[WIN_SIZE*4+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel4+:WIN_SIZE] & bmask4;
	end
	
	assign out_pix = |(STRUCT_ELM & rows);

endmodule
