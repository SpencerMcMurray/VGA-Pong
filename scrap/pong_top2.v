module pong_top2(
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
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5
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
	output reg [0:6] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	wire [0:6] Phw, Ahw, Dhw, Lhw, Ehw, Uhw, Rhw, Bhw, sphw;
	
	wire resetn;
	assign resetn = KEY[0];
	
	// x and y coordinates, and color to be sent to VGA
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
	//outputs from paddle FSM
	wire [7:0] paddleX; 
	wire [6:0] paddleY; 
	wire [2:0] paddleColour;
	
	//outputs from ball FSM
	wire [7:0] ballX;
	wire [6:0] ballY; 
	wire [2:0] ballColour; 
	
	wire[25:0] counter;
	
	// chooses whether the ball or paddle's coordinates and colour are being sent to VGA
	wire selectDraw; 
	
	//gameover if 1
	wire gameOver;
		
	wire resetCounter;
	
	//reset for the VGA
	wire resetn; 
	assign resetn = SW[9];
	
	wire [3:0] P, A, D, L, E, U, R, B, sp;
	
	assign P			= 4'b0000;
	assign A 		= 4'b0001;
	assign D 		= 4'b0010;
	assign L 		= 4'b0011;
	assign E 		= 4'b0100;
	assign U 		= 4'b0101;
	assign R 		= 4'b0110;
	assign B 		= 4'b0111;
	assign sp 		= 4'b1000;

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
		defparam VGA.BACKGROUND_IMAGE = "Title.mif";
			
endmodule
