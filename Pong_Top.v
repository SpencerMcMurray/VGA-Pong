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
	wire opening; // if at beginning
	wire instr_occur; // if at instruction
	wire delay_enable; //for delay counter when drawing (yet to be implemented)
	
	wire [9:0] scr_dx, scr_dy;
	wire [2:0] scr_col;
	wire screen_en;
	
	reg [1:0] select_screen;
	always @(*) begin
		if (opening)
			select_screen = 2'd0;
		else if (instr_occur)
			select_screen = 2'd1;
	end
	
	scr_memory screen(.resetn(resetn),
							.clk(CLOCK_50),
							.frame(delay_enable),
							.enable(opening | instr_occur),
							.screen_select(select_screen),
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
