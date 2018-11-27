`include "Title.v"
`include "Instructions.v"

module scr_memory(
						input resetn,
						input clk,
						input enable,
						input [1:0] select_screen,
						output draw_state,
						output [9:0] x, y,
						output reg [2:0] colour
						);
						
	wire [2:0] title_c, instr_c;
	wire [14:0] address;
	
	draw_mem dm(.go(enable),
					 .resetn(resetn),
					 .clk(clk),
					 .draw_state(draw_state),
					 .address(address),
					 .x(x),
					 .y(y)
					);
	
	Title title(.address(address),
					 .clock(clk),
					 .data(),
					 .wren(1'd0),
					 .q(title_c)
					);
	
	Instructions instr(.address(address),
							 .clock(clk),
							 .data(),
							 .wren(1'd0),
							 .q(instr_c)
							);
	
	always @(posedge clk) begin
		if (!resetn)
			colour <= title_c;
		else begin
			case(select_screen)
				2'd0: colour <= title_c;
				2'd1: colour <= instr_c;
			endcase
		end
	end
endmodule

//iterates through memory
module draw_mem(input go,
					 input resetn,
					 input clk,
					 output reg draw_state,
					 output reg [14:0] address,
					 output reg [9:0] x,
					 output reg [9:0] y
					 );
	reg [14:0] address_counter;
	
	always @(posedge clk) begin
		if (!resetn) begin
			draw_state <= 1'd0;
			address_counter <= 15'd0;
		end
		else if (draw_state) begin
			if (address_counter == (15'd19200 - 15'd1)) begin
				draw_state <= 1'd0;
				address_counter <= 15'd0;
			end
			else begin
				address_counter <= address_counter + 15'd1;
			end
		end
		else if (go)
			draw_state <= 1'd1;
	end
	
	always @(*) begin
		address = address_counter;
		x = address_counter % 14'd160;
		y = address_counter / 14'd160;
	end
	
endmodule
