module resetsync(
	output reg oRstSync,
	input iClk, iRst);
	
	reg R1;
	always @(posedge iClk or negedge iRst)
		if(!iRst) begin
			R1 <= 0;
			oRstSync <= 0;
		end
		else begin
			R1 <= 1;
			oRstSync <= R1;
		end
		
endmodule