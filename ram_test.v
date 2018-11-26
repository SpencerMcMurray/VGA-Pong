//`include "Title.v"
//`include "Instructions.v"
module ram_test
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
	wire [9:0] x;
	wire [9:0] y;
	wire writeEn;
	wire enable,ld_x,ld_y,ld_col;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(screen_en),
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
		
		scr_memory(resetn, clk, 1, 00, write_en, x, y, colour);
		

endmodule


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
