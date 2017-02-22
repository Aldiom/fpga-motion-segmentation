`timescale 1ns / 1ps





module h_sync__v_sync__gen__TB;

	// Inputs
	reg restart;
	reg clk;

	// Outputs
	wire [9:0] h_count_req;
	wire [8:0] v_count_req;
	wire active_req_data;
	wire active_send;
	wire blanking_active_line;
	wire h_sync;
	wire v_sync;

	// Instantiate the Unit Under Test (UUT)
	h_sync__v_sync__gen #(
        .H_PIXELS   (640),
        .V_LINES    (480),
        //
        .H_FN_PRCH  (16),
        .H_SYNC_PW  (96),
        .H_BK_PRCH  (48),
        //
        .V_FN_PRCH  (10),
        .V_SYNC_PW  (2),
        .V_BK_PRCH  (33),
        //
        .H_SYNC_POL (0),
        .V_SYNC_POL (0)
    )
    uut (
		.h_count_req(h_count_req), 
		.v_count_req(v_count_req), 
		.active_req_data(active_req_data), 
		.active_send(active_send), 
		.blanking_active_line(blanking_active_line), 
		.h_sync(h_sync), 
		.v_sync(v_sync), 
		.restart(restart), 
		.clk(clk)
	);
    
    
    // DEBUG
    one_shot
    one_shot_1 (
        .sigOut (h_sync_os),
        .sigIn  (h_sync),
        .clk    (clk)
    );
    
    
    


// ------------ Clock --------------
    parameter PERIOD = 4;
    always begin
      clk             = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
    end


	initial begin
		// Initialize Inputs
		restart = 1;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        restart = 0;

	end
      
endmodule

