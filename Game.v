module Game(done, draw_state, clk, reset);
	input clk;
	input reset;					// Set high to start, low to reset
	output reg [1:0] draw_state;	// 00 => Draw black, 01 => Draw left, 11 => Draw right, 10 => Draw ball
	output reg done;
	
	reg [1:0] curr_state, next_state;
	wire [19:0] delay;
	reg [19:0] count;
	reg [19:0] pause;
	reg count_en;
	reg count_reset;
	wire pause_clk;
	
	assign pause_clk = count == delay;
	
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
				
	counter pause1(.count(pause),
					.enable(count_en),
					.reset(count_en),
					.clk(pause_clk));
	
	// TODO: Add an n tick delay between draw states
	// n = # of pixels drawn
	always @(*) begin
		case(curr_state)
			START:			next_state = reset ? LOAD_1 : START;
			LOAD_1:			next_state = DRAW_L_PADDLE;
			DRAW_L_PADDLE: 	next_state = (count == delay) ? LOAD_2 : DRAW_L_PADDLE;
			LOAD_2:			next_state = DRAW_R_PADDLE;
			DRAW_R_PADDLE:	next_state = (count == delay) ? LOAD_3 : DRAW_R_PADDLE;
			LOAD_3:			next_state = DRAW_BALL;
			DRAW_BALL:		next_state = (pause == 10000) ? DONE : DRAW_BALL;
			DONE:			next_state = reset ? START : DONE;
			default			next_state = START;
		endcase
	end
	
	assign delay = 20'd19200;	// Number of pixels to update
	
	always @(*) begin
		// Defaults
		done = 1'b0;
		draw_state = 2'b00;
		count_en = 1'b0;
		count_reset = 1'b1;
		case(curr_state)
			LOAD_1: begin	// Load the delay value and reset the counter
				count_reset = 1'b0;
			end
			DRAW_L_PADDLE: begin
				draw_state = 2'b01;
				count_en = 1'b1;
			end
			LOAD_2: begin	// Load the delay value and reset the counter
				count_reset = 1'b0;
			end
			DRAW_R_PADDLE: begin
				count_en = 1'b1;
				draw_state = 2'b11;
			end
			LOAD_3: begin	// Load the delay value and reset the counter
				count_reset = 1'b0;
			end
			DRAW_BALL: begin
				count_en = 1'b1;
				draw_state = 2'b10;
			end
			DONE: begin
				done = 1'b1;
			end
		endcase
	end
	
	always @(posedge clk, negedge reset) begin
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
	
	always @(posedge clk, negedge reset) begin
		if(~reset) begin
			count <= 20'd0;
		end
		else if(enable) begin
			count <= count + 1;
		end
	end
endmodule