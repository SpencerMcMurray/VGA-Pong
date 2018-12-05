`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

`include "PS2MouseKeyboard/PS2_Keyboard_Controller.v"
`include "PS2MouseKeyboard/Altera_UP_PS2_Command_Out.v"
`include "PS2MouseKeyboard/Altera_UP_PS2_Data_In.v"
`include "PS2MouseKeyboard/PS2_Controller.v"

`include "control.v"
`include "datapath.v"
`include "ai_player.v"
`include "LSFR.v"

module PONG(
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
	inout PS2_CLK;
	inout PS2_DAT;
	
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
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	// Keyboard inputs
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
	
	// Wires for drawing
	wire move_pads;
	wire move_ball;
	wire set_up_clear_screen;
	wire clear_screen;
	wire set_up_left_pad;
	wire draw_left_pad;
	wire set_up_right_pad;
	wire draw_right_pad;
	wire set_up_ball;
	wire draw_ball;
	wire reset_delta;
	
	// State for menu and gameover
	wire menu;
	wire gameover;
	
	// Wires controlling AI paddle
	reg ai_enable;
	wire ai_up;
	wire ai_down;
	wire ai_toggle;

	// Scores
	wire gameover;
	wire [3:0] left_score;
	wire [3:0] right_score;
	
	// Movement wires
	wire [8:0] ball_x;
	wire [7:0] ball_y;
	wire [8:0] speed_x;
	wire [7:0] speed_y;
	wire ball_down;
	wire ball_right;
	wire [7:0] paddle_y;
	
	// Random value
	wire [12:0] random;
	
	// Keyboard adapter
	keyboard_tracker #(.PULSE_OR_HOLD(0)) keyboard (
		.clock(CLOCK_50),
		.reset(resetn),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.up(keyboard_up),
		.down(keyboard_down),
		.w(keyboard_w),
		.s(keyboard_s),
		.space(ai_toggle),
		.enter(keyboard_enter));
		
	// Spacebar toggles if ai is enabled or not
	always @(posedge ai_toggle, negedge resetn) begin
		if(!resetn)
			ai_enable = 0;
		else 
			ai_enable = !ai_enable;
	end
	
	
	// Call the datapath
	datapath d0(
		.clk(CLOCK_50), 
		.resetn(resetn),
		.random(random), 
		.move_left_up(keyboard_w),
		.move_left_down(keyboard_s),
		.move_right_up((!ai_enable & keyboard_up) | (ai_enable & ai_up)), // Mux to choose ai or keyboard input
		.move_right_down((!ai_enable & keyboard_down) | (ai_enable & ai_down)), // Mux to choose ai or keyboard input
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
	
	// Call the controller
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
		.plot(writeEn));
	
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
		.ai_up(ai_up),
		.ai_down(ai_down)
		);
		
	LSFR lfsr(.clock(CLOCK_50),
		.reset(resetn),
		.rnd(random));
	
	// HEX displays to show scores
	hex_decoder H0(
        .hex_digit(right_score),
        .segments(HEX0)
        );
	hex_decoder H2(
        .hex_digit(left_score),
        .segments(HEX5)
        );
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