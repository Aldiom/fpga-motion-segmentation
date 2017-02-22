`timescale 1ns / 1ps

module Hpos_Vpos_VidEn_gen_TB;

	// Inputs
	reg vid_clk;
	reg reset;
	reg Hsync;
	reg Vsync;
	reg Active_pix;
	reg [23:0] pixel_in;

	// Outputs
	wire [9:0]  Hpos;
	wire [8:0]  Vpos;
	wire        VidEn;
	wire [23:0] pixel_out;
	wire        line_ready;
	wire        frame_ready;

	// Instantiate the Unit Under Test (UUT)
	Hpos_Vpos_VidEn_gen #(
        .H_RES_PIX       (640),
        .V_RES_PIX       (480),
        .BITS_PER_PIXEL  (24),
        .LINE_READY_COMP (600)
    )
    uut (
		.vid_clk     (vid_clk), 
		.reset       (reset), 
		.Hsync       (Hsync), 
		.Vsync       (Vsync), 
		.Active_pix  (Active_pix), 
		.pixel_in    (pixel_in), 
		.Hpos        (Hpos), 
		.Vpos        (Vpos), 
		.VidEn       (VidEn), 
		.pixel_out   (pixel_out), 
		.line_ready  (line_ready), 
		.frame_ready (frame_ready)
	);


// ------------ Clock --------------
    parameter PERIOD = 4;
    always begin
      vid_clk             = 1'b0;
      #(PERIOD/2) vid_clk = 1'b1;
      #(PERIOD/2);
    end

// ------------ Tasks --------------
    task GenVsync();
    begin
        Vsync = 1;
        #(100*PERIOD);
        Vsync = 0;
    end
    endtask
    //
    task GenHsync();
    begin
        Hsync = 1;
        #(5*PERIOD);
        Hsync = 0;
    end
    endtask
    task GenFrontBackPorch();
    begin
        #(10*PERIOD);
    end
    endtask


// ------------ Tests --------------
	initial begin
		// Initialize Inputs
		reset      = 0;
		Hsync      = 0;
		Vsync      = 0;
		Active_pix = 0;
		pixel_in   = 0;

		// Wait 100 ns for global reset to finish
		#101;
        
		// Add stimulus here
        GenVsync();
        GenFrontBackPorch();
        GenFrontBackPorch();
        // Line 0
        //GenHsync();
        //GenFrontBackPorch();
        Active_pix = 1;
        pixel_in  = 24'hFFEE00; // pixel 0
        #(PERIOD);
        pixel_in  = 24'hAABBCC; // pixel 1
        #(PERIOD);
        pixel_in  = 24'hDDEEFF; // pixel 2
        #(PERIOD);
        #(650*PERIOD);
        Active_pix = 0;
        GenFrontBackPorch();
        // Line 1
        GenHsync();
        GenFrontBackPorch();
        Active_pix = 1;
        pixel_in  = 24'hABCDEF; // pixel 0
        #(PERIOD);
        #(650*PERIOD);
        Active_pix = 0;
        GenFrontBackPorch();
        //
        uut.Vpos   = 478;
        #(20*PERIOD);
        // Line 479
        GenHsync();
        GenFrontBackPorch();
        Active_pix = 1;
        pixel_in  = 24'h012345; // pixel 0
        #(PERIOD);
        #(650*PERIOD);
        Active_pix = 0;
        GenFrontBackPorch();
        // (Off-screen line)
        GenHsync();
        GenFrontBackPorch();
        Active_pix = 1;
        pixel_in  = 24'hABCDEF; // pixel 0
        #(PERIOD);
        #(650*PERIOD);
        Active_pix = 0;
        GenFrontBackPorch();

	end
      
endmodule

