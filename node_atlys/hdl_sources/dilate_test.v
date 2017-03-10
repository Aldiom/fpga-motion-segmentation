`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:16:45 03/05/2017
// Design Name:   dilator
// Module Name:   C:/Users/Alexis/Documents/Tareas/Project_motion_segmentation/node_atlys/dilate_test.v
// Project Name:  node_atlys
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dilator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dilate_test;

	// Inputs
	reg clk;
	reg [10:0] hpos;
	reg [10:0] vpos;
	reg in_pix;

	// Outputs
	wire out_pix;

	// Instantiate the Unit Under Test (UUT)
	dilator uut (
		.clk(clk), 
		.hpos(hpos), 
		.vpos(vpos), 
		.in_pix(in_pix), 
		.out_pix(out_pix)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		hpos = 0;
		vpos = 0;
		in_pix = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
	always begin
		#1 clk = ~clk;
	end
	
	always @(*) begin
		if((hpos>11'd20 && hpos<11'd201) || (hpos>11'd205 && hpos<11'd250)) begin
			if(vpos>11'd5 && vpos<11'd100)
				in_pix = 1'b1;
			else
				in_pix = 1'b0;
		end
		else
			in_pix = 1'b0;
	end
	
	always @(posedge clk) begin
		hpos <= (hpos < 11'd639) ? hpos+11'd1 : 11'd0;
		if(hpos == 11'd639) 
			vpos <= (vpos < 11'd479) ? vpos+11'd1 : 11'd0;
	end
	
endmodule

