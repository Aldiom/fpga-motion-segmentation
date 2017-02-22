`timescale 1ns / 1ps
module one_shot( sigOut, sigIn, clk );

output reg sigOut;
input sigIn;

input clk;

reg [1:0] shift = 0;

always @( posedge clk ) begin
	shift <= { shift[0], sigIn };
	if( shift == 2'b01 )
		sigOut <= 1;
	else
		sigOut <= 0;
end


endmodule
