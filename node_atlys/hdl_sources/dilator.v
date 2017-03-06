`timescale 1ns / 1ps

module dilator(
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
		line_wr <= (line_wr < WIN_SIZE+1) ? line_wr + 1 : 0;
	end
	
	wire [10:0] vpos_off = (vpos > WIN_SIZE/2) ? vpos - WIN_SIZE/2 - 1 : vpos + V_IMG_RES - WIN_SIZE/2 - 1;
	wire [10:0] hpos_off = hpos + WIN_SIZE/2;
	
	generate
		genvar i;

		for(i=0; i<WIN_SIZE+1; i=i+1) begin: block_buff
			reg [H_IMG_RES-1:0] pre_line = 0;
			wire [H_IMG_RES+WIN_SIZE-2:0] line = {{(WIN_SIZE/2){1'b0}}, block_buff[i].pre_line, {(WIN_SIZE/2){1'b0}}};
			always @(posedge clk)
				if(line_wr == i)
					block_buff[i].pre_line <= {in_pix, block_buff[i].pre_line[H_IMG_RES-1:1]};
		end
		
		(* KEEP = "TRUE" *) reg [WIN_SIZE**2-1:0] rows;
		for(i=0; i<WIN_SIZE; i=i+1) begin: win
			reg [H_IMG_RES+WIN_SIZE-2:0] line;
			//reg [WIN_SIZE-1:0] row;
			always @(*) begin
				if(line_wr+i < WIN_SIZE)
					win[i].line = block_buff[line_wr+i+1].line;
				else
					win[i].line = block_buff[line_wr+i-WIN_SIZE].line;
					
				if( (vpos_off + WIN_SIZE/2 < V_IMG_RES - 1) && (vpos_off > WIN_SIZE/2) )
					rows[WIN_SIZE*i+:WIN_SIZE] = win[i].line[hpos+:WIN_SIZE];
				else
					rows[WIN_SIZE*i+:WIN_SIZE] = 0;
			end
			
			//assign row_result[i] = |(STRUCT_ELM[WIN_SIZE*i+:WIN_SIZE] & win[i].row);
		end
	endgenerate
	
	assign out_pix = |(STRUCT_ELM & rows);

endmodule
