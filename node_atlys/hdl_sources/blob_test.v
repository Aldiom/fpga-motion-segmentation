`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:58:39 03/05/2017
// Design Name:   blob_analyzer
// Module Name:   C:/Users/Alexis/Documents/Tareas/Project_motion_segmentation/node_atlys/hdl_sources/blob_test.v
// Project Name:  node_atlys
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: blob_analyzer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module blob_test;

	// Inputs
	reg app_clk;
	reg app_timer_tick;
	reg mem_clk;
	reg vid_preload_line;
	reg vid_active_pix;
	reg [10:0] vid_hpos;
	reg [10:0] vid_vpos;
	reg foregnd_px;

	integer i;
	// Outputs
	wire [23:0] vid_data_out;

	// Instantiate the Unit Under Test (UUT)
	blob_analyzer uut (
		.app_clk(app_clk), 
		.app_timer_tick(app_timer_tick), 
		.mem_clk(mem_clk), 
		.vid_preload_line(vid_preload_line), 
		.vid_active_pix(vid_active_pix), 
		.vid_hpos(vid_hpos), 
		.vid_vpos(vid_vpos), 
		.vid_data_out(vid_data_out), 
		.foregnd_px(foregnd_px)
	);

	initial begin
		// Initialize Inputs
		app_clk = 0;
		app_timer_tick = 0;
		mem_clk = 0;
		vid_preload_line = 0;
		vid_active_pix = 0;
		vid_hpos = 0;
		vid_vpos = 0;
		foregnd_px = 0;
		i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
	end
	
	always begin
		#1 app_clk = ~app_clk;
	end
	
	always @(*) begin
		if((vid_hpos>11'd20 && vid_hpos<11'd201) || (vid_hpos>11'd630 && vid_hpos<11'd635)) begin
			if(vid_vpos>11'd5 && vid_vpos<11'd100)
				foregnd_px = 1'b1;
			else
				foregnd_px = 1'b0;
		end
		else
			foregnd_px = 1'b0;
	end
	
	always @(posedge app_clk) begin
		if((vid_hpos == 11'd639) || (i > 0))
			i <= (i < 150) ? i+1 : 0;
		if(i == 0)
			vid_hpos <= (vid_hpos < 11'd639) ? vid_hpos+11'd1 : 11'd0;
		if(vid_hpos == 11'd639) 
			vid_vpos <= (vid_vpos < 11'd479) ? vid_vpos+11'd1 : 11'd0;
	end
      
endmodule

