// Part 2 skeleton

module Pong_Top
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

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

	wire resetn;
	assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
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

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	reg opening; // if at beginning
	reg instr_occur; // if at instruction
	
	wire [9:0] scr_dx, scr_dy;
	wire [2:0] scr_col;
	
	wire screen_en;
	wire [1:0] select_screen;
	always @(*)begin
		if(select_screen == 2'd0) begin
			opening = 1'd1;
			instr_occur = 1'd0;
		end
		else if(select_screen == 2'd1)begin
			opening = 1'd0;
			instr_occur = 1'd1;
		end
		else begin
			opening = 1'd0;
			instr_occur = 1'd0;
		end
	end
	
	screen_sel s(.screen(select_screen),
					.resetn(resetn),
					.but_0(KEY[0]),
					.but_1(KEY[1]),
					.clk(CLOCK_50));
	
	scr_memory screen(.resetn(resetn),
							.clk(CLOCK_50),
							.enable(opening | instr_occur),
							.select_screen(select_screen),
							.draw_state(screen_en),
							.x(scr_dx), 
							.y(scr_dy),
							.colour(scr_col)
							);
							
	draw_mux (.scr_x(scr_dx),
				 .scr_y(scr_dy),
				 .opening(opening),
				 .instr(instr_occur),
				 .screen_en(screen_en),
				 .screen_colour(scr_col),
				 .x(x),
				 .y(y),
				 .writeEn(writeEn),
				 .colour(colour)
				 );
							
    // Instansiate datapath
	// datapath d0(...);

    // Instansiate FSM control
    // control c0(...);

endmodule

// Selects the screen to go to
// TODO: Get out of game state
// screen: 00 -> Title, 01 -> Instructions, 10 -> Game
module screen_sel(screen, resetn, but_0, but_1, clk);
	output reg [1:0] screen;	// The screen to go to
	input resetn;
	input but_0;				// Key 0
	input but_1;				// Key 1
	input clk;
	
	reg [2:0] curr_state, next_state;
	
	wire clock_1;
	
	rate_counter delay(
		.clk(clk),
		.resetn(resetn),
		.delay(40'd833333),
		
		.d_enable(clock_1)
	);
	
	// States
	localparam  TITLE 			= 3'b000,	// The title state
				INSTRUCT_WAIT 	= 3'b001,	// Going to instructions
				INSTRUCT 		= 3'b011,	// The instruction state
				TITLE_WAIT	 	= 3'b111,	// Going to the title
				GAME_WAIT 		= 3'b110,	// Going to the game
				GAME 			= 3'b100;	// The game state
				
	always @(*) begin
		case(curr_state)
			TITLE:			next_state = but_0 ? INSTRUCT_WAIT : TITLE;
			INSTRUCT_WAIT: 	next_state = but_0 ? INSTRUCT_WAIT : INSTRUCT;
			INSTRUCT: 		next_state = but_0 ? TITLE_WAIT : INSTRUCT;
			TITLE_WAIT:		next_state = but_0 ? TITLE_WAIT : TITLE;
			TITLE:			next_state = but_1 ? GAME_WAIT : TITLE;
			GAME_WAIT:		next_state = but_1 ? GAME_WAIT : GAME;
		default: 			next_state = TITLE;
		endcase
	end
	
	// State logic
	always @(*) begin
		screen <= 2'b00;	// Default Title screen
		case(curr_state)
			TITLE: begin
				screen <= 2'b00;
			end
			INSTRUCT: begin
				screen <= 2'b01;
			end
			GAME: begin
				screen <= 2'b10;
			end
		endcase
	end
	
	// Update state
	always@(posedge clock_1)
		begin: state_FFs
        if(!resetn)
            curr_state <= TITLE;
        else
            curr_state <= next_state;
		end // state_FFS
endmodule

//EXPAND this for actual game
module draw_mux(input [9:0] scr_x, 
					 input [9:0] scr_y,
					 input opening,
					 input instr,
					 input screen_colour,
					 input screen_en,
					 output reg [9:0] x, y,
					 output reg [2:0] colour,
					 output reg writeEn
					 );
	always @(*)begin
		if (opening | instr) begin
			x = scr_x;
			y = scr_y;
			colour = screen_colour;
			writeEn = screen_en;
		end
	// else game here
	end
endmodule
