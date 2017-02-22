`timescale 1ns / 1ps

module sig_delay_TB;

	// Inputs
	reg clk;
	reg [1:0] i_bus;

	// Outputs
	wire [1:0] o_bus;

	// Instantiate the Unit Under Test (UUT)
	sig_delay #(
        .BUS_BITS (2),
        .DELAY    (5)
    )
    uut (
		.clk(clk), 
		.i_bus(i_bus), 
		.o_bus(o_bus)
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
		clk = 0;
		i_bus = 0;

		// Wait 100 ns for global reset to finish
		#102.7;
        
		// Add stimulus here
        i_bus = 1;
        
        #(2*PERIOD);
        i_bus = 2;
        
        #(2*PERIOD);
        i_bus = 0;

	end
      
endmodule

