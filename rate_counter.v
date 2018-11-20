
module rate_counter(
	input clk,
	input resetn,
	input [39:0]delay,
	
	output d_enable
	);
	
	reg [39:0]q;
	always @ (posedge clk) begin
		if(!resetn)
			q <= delay - 1;
		else begin
			if(q == 40'b0) begin
				q <= delay - 1;
			end
			else
				q <= q - 1;
		end
	end
	
	assign d_enable = (q == 40'b0) ? 1'b1 : 1'b0;

endmodule