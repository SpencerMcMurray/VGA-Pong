`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

`include "PS2MouseKeyboard/PS2_Keyboard_Controller.v"
`include "PS2MouseKeyboard/Altera_UP_PS2_Command_Out.v"
`include "PS2MouseKeyboard/Altera_UP_PS2_Data_In.v"
`include "PS2MouseKeyboard/PS2_Controller.v"

module pong
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,
		LEDR,
		HEX0,
		HEX5,
		
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		
		// Keyboard inputs
		PS2_CLK,
		PS2_DAT
	);

	input			CLOCK_50;				//	50 MHz
	input [3:0]		KEY;
	output [9:0] 	LEDR;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	output [6:0] HEX0;
	output [6:0] HEX5;
	
	inout PS2_CLK;
	inout PS2_DAT;
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [8:0] x;
	wire [7:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
	// Keyboard wires
	wire keyboard_up;
	wire keyboard_down;
	wire keyboard_w;
	wire keyboard_s;
	wire keyboard_enter;
	
	// Control wires
	wire control_move_pads;
	wire control_move_ball;
	wire control_set_up_clear_screen;
	wire control_clear_screen;
	wire control_set_up_left_pad;
	wire control_draw_left_pad;
	wire control_set_up_right_pad;
	wire control_draw_right_pad;
	wire control_set_up_ball;
	wire control_draw_ball;
	wire control_reset_delta;
	wire menu;
	
	// Movement wires
	wire [8:0] ball_x;
	wire [7:0] ball_y;
	wire [8:0] speed_x;
	wire [7:0] speed_y;
	wire ball_down;
	wire ball_right;
	wire [7:0] paddle_y;
	
	// Right AI control wires
	reg right_ai_en;
	wire right_ai_up;
	wire right_ai_down;
	wire right_ai_tog;
	
	// Left AI wires
	reg left_ai_en;
	wire left_ai_up;
	wire left_ai_down;
	wire left_ai_tog;
	
	// Score logic wires
	wire gameover;
	wire [3:0] left_score;
	wire [3:0] right_score;
	
	// Keyboard adapter
	keyboard_tracker #(.PULSE_OR_HOLD(0)) keyboard (
		.clock(CLOCK_50),
		.reset(resetn),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.up(keyboard_up),
		.down(keyboard_down),
		.w(keyboard_w),
		.a(left_ai_tog),
		.s(keyboard_s),
		.left(right_ai_tog),
		.enter(keyboard_enter));
		
	// Key A toggles if ai is enabled or not
	always @(posedge left_ai_tog, negedge resetn) begin
		if(!resetn)
			left_ai_en = 0;
		else 
			left_ai_en = !left_ai_en;
	end
		
	// Spacebar toggles if ai is enabled or not
	always @(posedge right_ai_tog, negedge resetn) begin
		if(!resetn)
			right_ai_en = 0;
		else 
			right_ai_en = !right_ai_en;
	end
	
    // Instantiate datapath
	datapath d0(
		.clk(CLOCK_50), 
		.resetn(resetn), 
		// Move depending on key presses or AI
		.move_left_up(!left_ai_en & keyboard_w) | (left_ai_en & left_ai_up),
		.move_left_down(!left_ai_en & keyboard_s) | (left_ai_en & left_ai_down),
		.move_right_up((!right_ai_en & keyboard_up) | (right_ai_en & right_ai_up)),
		.move_right_down((!right_ai_en & keyboard_down) | (right_ai_en & right_ai_down)),
		.set_up_clear_screen(control_set_up_clear_screen),
		.clear_screen(control_clear_screen),
		.move_pads(control_move_pads),
		.move_ball(control_move_ball),
		.set_up_left_pad(control_set_up_left_pad),
		.draw_left_pad(control_draw_left_pad),
		.set_up_right_pad(control_draw_right_pad),
		.draw_right_pad(control_draw_right_pad),
		.set_up_ball(control_set_up_ball),
		.draw_ball(control_draw_ball),
		.reset_delta(control_reset_delta),
		.menu(menu),
		.x(x),
		.y(y),
		.colour(colour),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.speed_x(speed_x),
		.speed_y(speed_y),
		.ball_down(ball_down),
		.ball_right(ball_right),
		.right_pad_y(paddle_y),
		.gameover(gameover),
		.left_score(left_score),
		.right_score(right_score)
		);

	
    // Instantiate FSM control
	control c0(
		.clk(CLOCK_50), 
		.resetn(resetn),
		.enter(keyboard_enter),
		.gameover(gameover),
		.menu(menu),
		.move_pads(control_move_pads),
		.move_ball(control_move_ball),
		.set_up_clear_screen(control_set_up_clear_screen),
		.clear_screen(control_clear_screen),
		.set_up_left_pad(control_set_up_left_pad),
		.draw_left_pad(control_draw_left_pad),
		.set_up_right_pad(control_set_up_right_pad),
		.draw_right_pad(control_draw_right_pad),
		.set_up_ball(control_set_up_ball),
		.draw_ball(control_draw_ball),
		.reset_delta(control_reset_delta),
		.plot(writeEn),
		.state_out(LEDR[3:0]));
	
	// Instantiate the right AI logic
	ai_player ai(
		.clk(CLOCK_50),
		.resetn(resetn),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.speed_x(speed_x),
		.speed_y(speed_y),
		.ball_down(ball_down),
		.ball_right(ball_right),
		.paddle_y(paddle_y),
		.ai_up(right_ai_up),
		.ai_down(right_ai_down)
		);
		
	// Instantiate the left AI logic
	ai_player ai(
		.clk(CLOCK_50),
		.resetn(resetn),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.speed_x(speed_x),
		.speed_y(speed_y),
		.ball_down(ball_down),
		.ball_right(ball_right),
		.paddle_y(paddle_y),
		.ai_up(left_ai_up),
		.ai_down(left_ai_down)
		);
		
	hex_decoder H0(
        .hex_digit(right_score),
        .segments(HEX0)
        );

	hex_decoder H5(
        .hex_digit(left_score),
        .segments(HEX5)
        );
    
endmodule

module control(
	input clk,
	input resetn,
	input enter, // From keyboard
	input gameover,
	
	// Output based on state
	output reg menu,
	output reg move_pads,
	output reg move_ball,
	output reg set_up_clear_screen,
	output reg clear_screen,
	output reg set_up_left_pad,
	output reg draw_left_pad,
	output reg set_up_right_pad,
	output reg draw_right_pad,
	output reg set_up_ball,
	output reg draw_ball,
	output reg reset_delta,
	output reg plot,
	
	output reg[3:0] state_out
	);
	
	localparam 	PAD_COUNTER_LENGTH 			= 6'b100000,
				BALL_COUNTER_LENGTH 				= 5'b10100,
				FRAME_COUNTER_LENGTH				= 20'b11001011011100110110,
				CLEAR_SCREEN_COUNTER_LENGTH	= 15'b100101100000000;
				
	// current_state registers and counters
	reg [5:0] draw_left_pad_counter;
	reg [5:0] draw_right_pad_counter;
	reg [4:0] draw_ball_counter;
	reg [19:0] frame_counter;
	reg [14:0] clear_screen_counter;
	reg [3:0] current_state, next_state; 
    
    localparam  S_MENU        			= 4'd0,
                S_MOVE_PADS   			= 4'd1,
                S_MOVE_BALL 			= 4'd2,
				S_SET_UP_CLEAR_SCREEN	= 4'd3,
				S_CLEAR_SCREEN			= 4'd4,
				S_SET_UP_LEFT			= 4'd5,
                S_DRAW_LEFT_PAD  		= 4'd6,
				S_SET_UP_RIGHT			= 4'd7,
				S_DRAW_RIGHT_PAD		= 4'd8,
				S_SET_UP_BALL			= 4'd9,
				S_DRAW_BALL				= 4'd10,
				S_WAIT					= 4'd11;
	
	always @(*)
	begin: state_table 
            case (current_state)
            S_MENU: next_state = enter ? S_MOVE_BALL : S_MENU;
				S_MOVE_BALL: next_state = (gameover == 1) ? S_MENU : S_MOVE_PADS; 
            S_MOVE_PADS: next_state = S_SET_UP_CLEAR_SCREEN;
				S_SET_UP_CLEAR_SCREEN: next_state = S_CLEAR_SCREEN;
				S_CLEAR_SCREEN: next_state = (clear_screen_counter == 0) ? S_SET_UP_LEFT : S_CLEAR_SCREEN;
				S_SET_UP_LEFT: next_state = S_DRAW_LEFT_PAD;
            S_DRAW_LEFT_PAD: next_state = (draw_left_pad_counter == 0) ? S_SET_UP_RIGHT: S_DRAW_LEFT_PAD;
				S_SET_UP_RIGHT: next_state = S_DRAW_RIGHT_PAD;
				S_DRAW_RIGHT_PAD: next_state = (draw_right_pad_counter == 0) ? S_SET_UP_BALL : S_DRAW_RIGHT_PAD;
				S_SET_UP_BALL: next_state = S_DRAW_BALL;
				S_DRAW_BALL: next_state = (draw_ball_counter == 0) ? S_WAIT : S_DRAW_BALL;
				S_WAIT: next_state = (frame_counter == 0) ? S_MOVE_BALL : S_WAIT;
			default:     next_state = S_MENU;
        endcase
    end // state_table
	
	always @(*)
    begin: enable_signals
        // By default make all our signals 0
        move_pads = 0;
		move_ball = 0;
		set_up_clear_screen = 0;
		clear_screen = 0;
		draw_left_pad = 0;
		draw_right_pad = 0;
		draw_ball = 0;
		reset_delta = 0;
		plot = 0;
		menu = 0;
		set_up_ball = 0;
		set_up_right_pad = 0;
		set_up_left_pad = 0;

        case (current_state)
			S_MENU: begin
				menu <= 1'b1;
				end
            S_MOVE_PADS: begin
				move_pads <= 1'b1;
				end
			S_MOVE_BALL: begin
				move_ball <= 1'b1;
				end 
			S_SET_UP_CLEAR_SCREEN: begin
				reset_delta <= 1'b1;
				set_up_clear_screen <= 1'b1;
				end
			S_CLEAR_SCREEN: begin
				clear_screen <= 1'b1;
				plot <= 1'b1;
				end
			S_DRAW_LEFT_PAD: begin
				draw_left_pad <= 1'b1;
				plot <= 1'b1;
				end
			S_DRAW_RIGHT_PAD: begin
				draw_right_pad <= 1'b1;
				plot <= 1'b1;
				end
			S_DRAW_BALL: begin
				draw_ball <= 1'b1;
				plot <= 1'b1;
				end
			S_SET_UP_LEFT: begin
				set_up_left_pad <= 1'b1;
				reset_delta <= 1'b1;
				end
			S_SET_UP_RIGHT: begin
				set_up_right_pad <= 1'b1;
				reset_delta <= 1'b1;
				end
			S_SET_UP_BALL: begin
				set_up_ball <= 1'b1;
				reset_delta <= 1'b1;
				end
			
        endcase
    end // enable_signals
	
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_MENU;
        else begin
            current_state <= next_state;
			if(current_state == S_DRAW_LEFT_PAD)
				draw_left_pad_counter <= draw_left_pad_counter - 1;
			else draw_left_pad_counter <= PAD_COUNTER_LENGTH;
			
			if(current_state == S_DRAW_RIGHT_PAD)
				draw_right_pad_counter <= draw_right_pad_counter - 1;
			else draw_right_pad_counter <= PAD_COUNTER_LENGTH;
				
			if(current_state == S_DRAW_BALL)
				draw_ball_counter <= draw_ball_counter - 1;
			else draw_ball_counter <= BALL_COUNTER_LENGTH;
				
			if(current_state == S_WAIT)
				frame_counter <= frame_counter - 1;
			else frame_counter <= FRAME_COUNTER_LENGTH;
			
			if(current_state == S_CLEAR_SCREEN)
				clear_screen_counter <= clear_screen_counter -1;
			else clear_screen_counter <= CLEAR_SCREEN_COUNTER_LENGTH;
		
		end
    end // state_FFS
	
	always @(*) begin
		state_out <= current_state;
	end
endmodule

module datapath(
	input clk,
	input resetn,
	
	// From keyboard
	input move_left_up, 
	input move_right_up,
	input move_left_down,
	input move_right_down,
	
	// Actions based on current state
	input set_up_clear_screen,
	input clear_screen,
	input move_pads,
	input move_ball,
	input set_up_left_pad,
	input draw_left_pad,
	input set_up_right_pad,
	input draw_right_pad,
	input set_up_ball,
	input draw_ball,
	input reset_delta,
	input menu,
	
	// Output to VGA
	output reg[8:0] x,
	output reg[7:0] y,
	output reg[2:0] colour,
	
	// Output to ai
	output reg [8:0] ball_x,
	output reg [7:0] ball_y,
	output reg [8:0] speed_x,
	output reg [7:0] speed_y,
	output reg ball_down,
	output reg ball_right,
	output reg [7:0] right_pad_y,
	output reg gameover,
	output reg [3:0] left_score,
	output reg [3:0] right_score
	);
	
	reg [7:0] left_pad_y;
	
	reg change_direction;
	
	reg [8:0] x_delta;
	reg [7:0] y_delta;
	
	// Generate a 13-bit random number
	wire [12:0] random;
	LFSR lfsr(.clock(clk),
		.reset(resetn),
		.rnd(random));
	
	localparam LEFT_PAD_X = 8'b00000000, 
		RIGHT_PAD_X = 8'b10011110,
		BALL_START_X = 8'b01001110,
		BALL_START_Y = 7'b0111010,
		PAD_MOVE_DELTA = 7'b0000011,
		PAD_WIDTH = 2,
		PAD_HEIGHT = 16,
		BALL_WIDTH = 4;
	
	always @(posedge clk) begin
		if(!resetn || menu) begin
			left_pad_y <= 7'b0100000;
			right_pad_y <= 7'b0100000;
			ball_x <= BALL_START_X;
			ball_y <= BALL_START_Y + $signed(random[10:8]);
			x_delta <= 0;
			y_delta <= 0;
			speed_x <= 8'b00000001;
			speed_y <= {5'b00000, random[3:2]};
			ball_right = random[0];
			ball_down = random[1];
			change_direction = 0;
			left_score <= 0;
			right_score <= 0;
			gameover <= 0;
		end
		else begin
			if(reset_delta) begin
				x_delta <= 0;
				y_delta <= 0;
			end
			if(set_up_clear_screen) begin
				x <= 0;
				y <= 0;
			end
			if(set_up_left_pad) begin
				x <= LEFT_PAD_X;
				y <= left_pad_y;
			end
			if(set_up_right_pad) begin
				x <= RIGHT_PAD_X;
				y <= right_pad_y;
			end
			if(set_up_ball) begin
				x <= ball_x;
				y <= ball_y;
			end
			if(clear_screen) begin
				if(x_delta == 159) begin
					x_delta <= 0;
					y_delta <= y_delta+1;
				end
				else
					x_delta <= x_delta + 1;
				
				x <= x_delta;
				y <= y_delta;
			end
			if(move_pads) begin
				if(move_left_up) begin
					if($signed(left_pad_y - PAD_MOVE_DELTA) > 0)
						left_pad_y <= left_pad_y - PAD_MOVE_DELTA;
					else
						left_pad_y <= 0;
				end
				if(move_right_up) begin
					if($signed(right_pad_y - PAD_MOVE_DELTA) > 0)
						right_pad_y <= right_pad_y - PAD_MOVE_DELTA;
					else 
						right_pad_y <= 0;
				end
				if(move_left_down) begin
					if(left_pad_y + PAD_MOVE_DELTA <= 120 - PAD_HEIGHT)
						left_pad_y <= left_pad_y + PAD_MOVE_DELTA;
					else
						left_pad_y <= 120 - PAD_HEIGHT;
				end
				if(move_right_down) begin
					if(right_pad_y + PAD_MOVE_DELTA <= 120 - PAD_HEIGHT)
						right_pad_y <= right_pad_y + PAD_MOVE_DELTA;
					else
						right_pad_y <= 120 - PAD_HEIGHT;
				end
			end
			if(move_ball) begin
				if(ball_down) begin
					if(ball_y + BALL_WIDTH + speed_y >= 120 - BALL_WIDTH) begin
						ball_y <= 120 - BALL_WIDTH;
						ball_down <= !ball_down;
					end
					else
						ball_y <= ball_y + speed_y;
				end
				else begin
					if($signed(ball_y - speed_y) <= 0) begin
						ball_y <= 0;
						ball_down <= !ball_down;
					end
					else
						ball_y <= ball_y - speed_y;
				end
				if(ball_right) begin
					if(ball_x + BALL_WIDTH + speed_x >= RIGHT_PAD_X) begin
						if(right_pad_y + PAD_HEIGHT >= ball_y && right_pad_y <= ball_y + BALL_WIDTH) begin
							ball_x <= RIGHT_PAD_X - BALL_WIDTH;
							ball_right <= !ball_right;
							if(right_pad_y + (PAD_HEIGHT / 4) >= ball_y) begin
								speed_y <= 7'b0000010;
							end
							else if(right_pad_y + (PAD_HEIGHT / 2) >= ball_y) begin
								speed_y <= 7'b0000001;
							end
							else if(right_pad_y + (PAD_HEIGHT * 3 / 4) >= ball_y) begin
								speed_y <= 7'b0000001;
							end
							else begin
								speed_y <= 7'b0000010;
							end
						end
						else begin
							ball_x <= BALL_START_X;
							ball_y <= BALL_START_Y + $signed(random[10:8]);
							speed_x <= 8'b00000001;
							speed_y <= {5'b00000, random[5:4]};
							ball_right <= !ball_right;
							left_score <= left_score + 1;
						end							
					end
					else
						ball_x <= ball_x + speed_x;
				end
				else begin
					if(ball_x - speed_x <= LEFT_PAD_X + PAD_WIDTH) begin
						if(left_pad_y + PAD_HEIGHT >= ball_y && left_pad_y <= ball_y + BALL_WIDTH) begin
							ball_x <= LEFT_PAD_X + PAD_WIDTH;
							ball_right <= !ball_right;
							if(left_pad_y + (PAD_HEIGHT / 4) >= ball_y) begin
								speed_y <= 7'b0000010;
							end
							else if(left_pad_y + (PAD_HEIGHT / 2) >= ball_y) begin
								speed_y <= 7'b0000001;
							end
							else if(left_pad_y + (PAD_HEIGHT * 3 / 4) >= ball_y) begin
								speed_y <= 7'b0000001;
							end
							else begin
								speed_y <= 7'b0000010;
							end
						end
						else begin
							ball_x <= BALL_START_X;
							ball_y <= BALL_START_Y + $signed(random[10:8]);
							speed_x <= 8'b00000001;
							speed_y <= {5'b00000, random[7:6]};
							ball_right <= !ball_right;
							right_score <= right_score + 1;
						end		
					end
					else
						ball_x <= ball_x - speed_x;
				end
			end
			if(left_score >= 5 || right_score >= 5) begin
				gameover <= 1;
			end
			if(draw_left_pad && x_delta <= 1) begin			
				if (y_delta >= PAD_HEIGHT - 1) begin
					y_delta <= 0;
					x_delta <= x_delta +1;
				end
				else begin
					y_delta <= y_delta +1;
				end
				
				x <= LEFT_PAD_X + x_delta;
				y <= left_pad_y + y_delta;
			end
			if(draw_right_pad && x_delta <= 1) begin
				if (y_delta >= PAD_HEIGHT - 1) begin
					y_delta <= 0;
					x_delta <= x_delta + 1;
				end
				else begin
					y_delta <= y_delta + 1;
				end
				
				x <= RIGHT_PAD_X + x_delta;
				y <= right_pad_y + y_delta;
			end
			if(draw_ball) begin
				if(x_delta >= 3) begin
					x_delta <= 0;
					y_delta <= y_delta + 1;
				end
				else begin
					x_delta <= x_delta +1;
				end
				
				x <= ball_x + x_delta;
				y <= ball_y + y_delta;
			end
		end
	end
	
	always @(posedge clk) begin
		if(clear_screen)
			colour <= 3'b000;
		else if(draw_left_pad || draw_right_pad || draw_ball || set_up_left_pad || set_up_right_pad || set_up_ball)
			colour <= 3'b111;
		else
			colour <= 3'b111;
	end
endmodule

// Random number generator
module LFSR (
    input clock,
    input reset,
    output [12:0] rnd 
    );
 
wire feedback = random[12] ^ random[3] ^ random[2] ^ random[0]; 
 
reg [12:0] random, random_next, random_done;
reg [3:0] count, count_next; // Keep track of the number of shifts
 
always @ (posedge clock or posedge reset) begin
	if (reset) begin
		random <= 13'hF; // An LFSR cannot have an all 0 state, thus reset to FF
		count <= 0;
	end
	else begin
		random <= random_next;
		count <= count_next;
	end
end
 
always @ (*) begin
	random_next = random; //default state stays the same
	count_next = count;

	random_next = {random[11:0], feedback}; //shift left the xor'd every posedge clock
	count_next = count + 1;

	if (count == 13) begin
		count = 0;
		random_done = random; //assign the random number to output after 13 shifts
	end
end

assign rnd = random_done;
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule


