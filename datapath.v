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
	
	// Output for the AI
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
	
	localparam LEFT_PAD_X 	= 8'b00000000, 
		RIGHT_PAD_X 		= 8'b10011110,
		BALL_START_X 		= 8'b01001110,
		BALL_START_Y 		= 7'b0111010,
		PAD_MOVE_DELTA 		= 7'b0000011,
		PAD_WIDTH 			= 2,
		PAD_HEIGHT 			= 16,
		BALL_WIDTH 			= 4,
		SCORE				= 3;	// TODO: Make this 9 for actual game
	
	always @(posedge clk) begin
		if(!resetn || menu) begin
			left_pad_y <= 7'b0100000;
			right_pad_y <= 7'b0100000;
			ball_x <= BALL_START_X;
			ball_y <= BALL_START_Y;
			x_delta <= 0;
			y_delta <= 0;
			speed_x <= 8'b00000001;
			speed_y <= 7'b0000001;
			ball_right = 1'b1;
			ball_down = 1'b1;
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
			
			// If we're moving the paddles, make sure we dont go outside the screen
			if(move_pads) begin
				if(move_left_up) begin
					if($signed(left_pad_y - PAD_MOVE_DELTA) > $signed(0))
						left_pad_y <= left_pad_y - PAD_MOVE_DELTA;
					else
						left_pad_y <= 0;
				end
				if(move_right_up) begin
					if($signed(right_pad_y - PAD_MOVE_DELTA) > $signed(0))
						right_pad_y <= right_pad_y - PAD_MOVE_DELTA;
					else right_pad_y <= 0;
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
			
			// If we're moving the ball, begin working with fun collisions!
			if(move_ball) begin
				// If the ball is going down, make sure it doesnt fall off the screen
				if(ball_down) begin
					if(ball_y + BALL_WIDTH + speed_y >= 120 - BALL_WIDTH) begin
						ball_y <= 120 - BALL_WIDTH;
						ball_down <= !ball_down;
					end
					else
						ball_y <= ball_y + speed_y;
				end
				// Otherwise the ball is going up, also make sure it doesnt fall off the screen
				else begin
					if($signed(ball_y - speed_y) <= $signed(0)) begin
						ball_y <= 0;
						ball_down <= !ball_down;
					end
					else
						ball_y <= ball_y - speed_y;
				end
				// If the ball is going right
				if(ball_right) begin
					// If the ball is within the scoring/paddle area see if it scores or is reflected
					if(ball_x + BALL_WIDTH + speed_x >= RIGHT_PAD_X) begin
						if(right_pad_y + PAD_HEIGHT >= ball_y && right_pad_y <= ball_y + BALL_WIDTH) begin
							ball_x <= RIGHT_PAD_X - BALL_WIDTH;
							ball_right <= !ball_right;
							// Depending on where we hit the paddle, alter the y speed of the ball
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
						// Otherwise its scored, so reset x and y positions and speeds, and update score
						else begin
							ball_x <= BALL_START_X;
							ball_y <= BALL_START_Y;
							speed_x <= 8'b00000001;
							speed_y <= 7'b0000001;
							ball_right <= !ball_right;
							left_score <= left_score + 1;
						end							
					end
					// Otherwise move the ball in the positive x direction
					else
						ball_x <= ball_x + speed_x;
				end
				// Otherwise we're going left
				else begin
					// If the ball is within the scoring/paddle area see if it scores or is reflected
					if(ball_x - speed_x <= LEFT_PAD_X + PAD_WIDTH) begin
						if(left_pad_y + PAD_HEIGHT >= ball_y && left_pad_y <= ball_y + BALL_WIDTH) begin
							ball_x <= LEFT_PAD_X + PAD_WIDTH;
							ball_right <= !ball_right;
							// Depending on where we hit the paddle, alter the y speed of the ball
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
						// Otherwise its scored, so reset x and y positions and speeds, and update score
						else begin
							ball_x <= BALL_START_X;
							ball_y <= BALL_START_Y;
							speed_x <= 8'b00000001;
							speed_y <= 7'b0000001;
							ball_right <= !ball_right;
							right_score <= right_score + 1;
						end		
					end
					// Otherwise move the ball in the negative x direction
					else
						ball_x <= ball_x - speed_x;
				end
			end
			// See if someone won
			if(left_score >= SCORE || right_score >= SCORE) begin
				gameover <= 1;
			end
			// Draw/Update the left paddle
			if(draw_left_pad) begin			
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
			// Draw/Update the right paddle
			if(draw_right_pad) begin
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
			// Draw/Update the ball
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
	
	always @(*) begin
		// Pick the colour of what we're drawing
		if(clear_screen)
			colour <= 3'b000;
		else if(draw_left_pad || draw_right_pad || draw_ball)
			colour <= 3'b111;
		else
			colour <= 3'b000;
	end
endmodule