`timescale 1ns / 1ps

module eroder(
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
	
	generate
		genvar i;
		reg [(WIN_SIZE+1)*WIN_SIZE-1:0] sh_reg = 0;
		for(i=0; i<WIN_SIZE+1; i=i+1) begin: block_buff
			reg line [0:H_IMG_RES-1];
			//(* KEEP = "TRUE" *) reg shift_in;
			always @(posedge clk) begin
				if(line_wr == i) begin
					block_buff[i].line[hpos] <= in_pix;
					if(hpos < WIN_SIZE/2 + 1) 
						sh_reg[WIN_SIZE*i+:WIN_SIZE] <= {in_pix, sh_reg[WIN_SIZE*i+1 +: WIN_SIZE-1]};
					//lines[H_IMG_RES*i +: H_IMG_RES] <= {in_pix, lines[H_IMG_RES*i +: (H_IMG_RES-1)]};
				end
				else begin
					if(hpos < H_IMG_RES - WIN_SIZE/2 - 1) 
						//block_buff[i].shift_in <= block_buff[i].line[hpos + WIN_SIZE/2 + 2];
						sh_reg[WIN_SIZE*i+:WIN_SIZE] <= {block_buff[i].line[hpos + WIN_SIZE/2 + 1],
																	sh_reg[WIN_SIZE*i+1 +: WIN_SIZE-1]};
					else
						//block_buff[i].shift_in <= block_buff[i].line[hpos - H_IMG_RES + WIN_SIZE/2 + 2];
						sh_reg[WIN_SIZE*i+:WIN_SIZE] <= {block_buff[i].line[hpos - H_IMG_RES + WIN_SIZE/2 + 1],
																	sh_reg[WIN_SIZE*i+1 +: WIN_SIZE-1]};
				end
			end
		end
		
		(* KEEP = "TRUE" *)
		reg [WIN_SIZE**2-1:0] rows = 0;
		for(i=0; i<WIN_SIZE; i=i+1) begin: win
			reg [ceil_log2(WIN_SIZE)-1:0] lin_sel;
			//reg [H_IMG_RES-1:0] line;
			//reg [WIN_SIZE-1:0] row;
			always @(*) begin
				if(line_wr+i < WIN_SIZE)
					win[i].lin_sel = line_wr+i+1;
				else
					win[i].lin_sel = line_wr+i-WIN_SIZE;
					
				rows[WIN_SIZE*i+:WIN_SIZE] = 0; //assuming there's at least one 1 of the struct. element off the border
				if( (hpos + WIN_SIZE/2 < H_IMG_RES - 1) && (hpos > WIN_SIZE/2) )
					if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
						rows[WIN_SIZE*i+:WIN_SIZE] = sh_reg[WIN_SIZE*win[i].lin_sel+:WIN_SIZE];
			end
			
			//assign row_result[i] = |(STRUCT_ELM[WIN_SIZE*i+:WIN_SIZE] & ~win[i].row);
		end
	endgenerate
	
	assign out_pix = ~|(STRUCT_ELM & ~rows);

endmodule
