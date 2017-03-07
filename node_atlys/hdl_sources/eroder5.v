`timescale 1ns / 1ps

module eroder5(
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
	
	reg [(WIN_SIZE+1)*WIN_SIZE-1:0] sh_reg;

	reg line0 [0:H_IMG_RES-1];
	reg shift_in0;
	always @(posedge clk) begin
		if(line_wr == 3'd0) begin
			line0[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*0+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*0+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in0 = line0[hpos + WIN_SIZE/2 + 1];
			else
				shift_in0 = line0[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*0+:WIN_SIZE] <= {shift_in0, sh_reg[WIN_SIZE*0+1+:WIN_SIZE-1]};
		end
	end
	
	reg line1 [0:H_IMG_RES-1];
	reg shift_in1;
	always @(posedge clk) begin
		if(line_wr == 3'd1) begin
			line1[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*1+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*1+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in1 = line1[hpos + WIN_SIZE/2 + 1];
			else
				shift_in1 = line1[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*1+:WIN_SIZE] <= {shift_in1, sh_reg[WIN_SIZE*1+1+:WIN_SIZE-1]};
		end
	end
	
	reg line2 [0:H_IMG_RES-1];
	reg shift_in2;
	always @(posedge clk) begin
		if(line_wr == 3'd2) begin
			line2[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1)
				sh_reg[WIN_SIZE*2+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*2+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in2 = line2[hpos + WIN_SIZE/2 + 1];
			else
				shift_in2 = line2[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*2+:WIN_SIZE] <= {shift_in2, sh_reg[WIN_SIZE*2+1+:WIN_SIZE-1]};
		end
	end
	
	reg line3 [0:H_IMG_RES-1];
	reg shift_in3;
	always @(posedge clk) begin
		if(line_wr == 3'd3) begin
			line3[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*3+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*3+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in3 = line3[hpos + WIN_SIZE/2 + 1];
			else
				shift_in3 = line3[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*3+:WIN_SIZE] <= {shift_in3, sh_reg[WIN_SIZE*3+1+:WIN_SIZE-1]};
		end
	end
	
	reg line4 [0:H_IMG_RES-1];
	reg shift_in4;
	always @(posedge clk) begin
		if(line_wr == 3'd4) begin
			line4[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*4+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*4+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in4 = line4[hpos + WIN_SIZE/2 + 1];
			else
				shift_in4 = line4[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*4+:WIN_SIZE] <= {shift_in4, sh_reg[WIN_SIZE*4+1+:WIN_SIZE-1]};
		end
	end
	
	reg line5 [0:H_IMG_RES-1];
	reg shift_in5;
	always @(posedge clk) begin
		if(line_wr == 3'd5) begin
			line5[hpos] <= in_pix;
			if(hpos < WIN_SIZE/2 + 1) 
				sh_reg[WIN_SIZE*5+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*5+1+:WIN_SIZE-1]};
			//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
		end
		else begin
			if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
				shift_in5 = line5[hpos + WIN_SIZE/2 + 1];
			else
				shift_in5 = line5[hpos - H_IMG_RES + WIN_SIZE/2 + 1];
			sh_reg[WIN_SIZE*5+:WIN_SIZE] <= {shift_in5, sh_reg[WIN_SIZE*5+1+:WIN_SIZE-1]};
		end
	end
	//--------------------------------------------
	reg [WIN_SIZE**2-1:0] rows;

	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel0;
	//reg [H_IMG_RES-1:0] line;
	//reg [WIN_SIZE-1:0] row;
	always @(*) begin
		if(line_wr+0 < WIN_SIZE)
			lin_sel0 = line_wr+0+1;
		else
			lin_sel0 = line_wr+0-WIN_SIZE;
			
		rows[WIN_SIZE*0+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
		if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
			if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
				rows[WIN_SIZE*0+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel0+:WIN_SIZE];
	end
				
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel1;
	//reg [H_IMG_RES-1:0] line;
	//reg [WIN_SIZE-1:0] row;
	always @(*) begin
		if(line_wr+1 < WIN_SIZE)
			lin_sel1 = line_wr+1+1;
		else
			lin_sel1 = line_wr+1-WIN_SIZE;
			
		rows[WIN_SIZE*1+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
		if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
			if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
				rows[WIN_SIZE*1+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel1+:WIN_SIZE];
	end
				
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel2;
	//reg [H_IMG_RES-1:0] line;
	//reg [WIN_SIZE-1:0] row;
	always @(*) begin
		if(line_wr+2 < WIN_SIZE)
			lin_sel2 = line_wr+2+1;
		else
			lin_sel2 = line_wr+2-WIN_SIZE;
			
		rows[WIN_SIZE*2+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
		if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
			if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
				rows[WIN_SIZE*2+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel2+:WIN_SIZE];
	end
				
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel3;
	//reg [H_IMG_RES-1:0] line;
	//reg [WIN_SIZE-1:0] row;
	always @(*) begin
		if(line_wr+3 < WIN_SIZE)
			lin_sel3 = line_wr+3+1;
		else
			lin_sel3 = line_wr+3-WIN_SIZE;
			
		rows[WIN_SIZE*3+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
		if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
			if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
				rows[WIN_SIZE*3+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel3+:WIN_SIZE];
	end
	
	reg [ceil_log2(WIN_SIZE)-1:0] lin_sel4;
	//reg [H_IMG_RES-1:0] line;
	//reg [WIN_SIZE-1:0] row;
	always @(*) begin
		if(line_wr+4 < WIN_SIZE)
			lin_sel4 = line_wr+4+1;
		else
			lin_sel4 = line_wr+4-WIN_SIZE;
			
		rows[WIN_SIZE*4+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
		if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
			if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
				rows[WIN_SIZE*4+:WIN_SIZE] = sh_reg[WIN_SIZE*lin_sel4+:WIN_SIZE];
	end
	
	//assign row_result[i] = |(STRUCT_ELM[WIN_SIZE*i+:WIN_SIZE] & ~win[i].row);
	
	assign out_pix = ~|(STRUCT_ELM & ~rows);

endmodule