`include "vga_adapter/vga_adapter.v"

module Game(draw_state, clk, reset);
	input clk;
	input reset;				// Set high to start, low to reset
	output [1:0] draw_state;	// 00 => Nothing, 01 => Draw left, 11 => Draw right, 10 => Draw ball
	
	reg [1:0] curr_state, next_state;
	reg [19:0] delay;
	reg [19:0] count;
	wire count_en;
	wire count_reset;
	
	localparam	START				= 3'b000,
				LOAD_1				= 3'b001,
				DRAW_L_PADDLE		= 3'b011,
				LOAD_2				= 3'b111,
				DRAW_R_PADDLE 		= 3'b101,
				LOAD_3				= 3'b100,
				DRAW_BALL			= 3'b110,
				DONE				= 3'b010;
	
	counter c(.count(count),
				.enable(count_en),
				.reset(count_reset),
				.clk(clk));
	
	// TODO: Add an n tick delay between draw states
	// n = # of pixels drawn
	always @(*) begin
		case(curr_state)
			START:			next_state = ~reset ? LOAD_1 : START;
			LOAD_1			next_state = DRAW_L_PADDLE;
			DRAW_L_PADDLE: 	next_state = (count == delay) ? LOAD_2 : DRAW_L_PADDLE;
			LOAD_2:			next_state = DRAW_R_PADDLE;
			DRAW_R_PADDLE:	next_state = (count == delay) ? LOAD_3 : DRAW_R_PADDLE;
			LOAD_3			next_state = DRAW_BALL;
			DRAW_BALL:		next_state = (count == delay) ? START : DRAW_BALL;
			default:		next_state = START;
		endcase
	end
	
	always @(*) begin
		// Defaults
		draw_state = 2'b00;
		delay = 20'd0;
		count_en = 1'b0;
		count_reset = 1'b1;
		case(curr_state)
			LOAD_1: begin	// Load the delay value and reset the counter
				delay = 20'd40;
				count_reset = 1'b0;
			end
			DRAW_L_PADDLE: begin
				delay = 20'd40;
				draw_state = 2'b01;
				count_en = 1'b1;
			end
			LOAD_2: begin	// Load the delay value and reset the counter
				delay = 20'd40;
				count_reset = 1'b0;
			end
			DRAW_R_PADDLE: begin
				delay = 20'd40;
				count_en = 1'b1;
				draw_state = 2'b11;
			end
			LOAD_3: begin	// Load the delay value and reset the counter
				delay = 20'd16;
				count_reset = 1'b0;
			end
			DRAW_BALL: begin
				delay = 20'd16;
				count_en = 1'b1;
				draw_state = 2'b10;
			end
		endcase
	end
	
	always @(posedge clk negedge reset) begin
		if(~reset) begin
			curr_state <= START;
		end
		else begin
			curr_state <= next_state;
		end
	end
	
endmodule

module counter(count, enable, reset, clk);
	input enable, reset, clk;
	output reg [19:0] count;
	
	always @(posedge clk negedge reset) begin
		if(~reset) begin
			count <= 20'd0;
		end
		else if(enable) begin
			count <= count + 1;
		end
	end
endmodule