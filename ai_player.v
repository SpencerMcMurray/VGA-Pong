module ai_player(input clk,
					  input resetn,	
					  input [8:0] ball_x,
					  input [7:0] ball_y,
					  input [8:0] speed_x,
					  input [7:0] speed_y,
					  input ball_down,
					  input ball_right,
					  input [7:0] paddle_y,
					  output reg ai_up,
					  output reg ai_down
					  );
	reg [8:0] y_distance;
	reg [8:0] y_target;
	always @(*) begin
		ai_up = 0;
		ai_down = 0;
		y_distance = (160-ball_x-4) * (speed_y/speed_x);
		
		if (ball_right && ball_x >= 100) begin
			// Update the target y if the ball is going down
			if (ball_down) begin
				y_target <= ball_y  + y_distance > 120 ? 240 - ball_y-y_distance : ball_y+y_distance;
			end
			// Update the target y if the ball is going up
			else begin
				y_target <= $signed(ball_y - y_distance) < 0 ? y_distance - ball_y: ball_y - y_distance;
			end
		end
		// If the target y is lower than the paddle, tell the paddle to go up
		if (y_target - 4 <= paddle_y) begin
			ai_up <= 1'b1;
		end
		// If the target y is higher than the paddle, tell the paddle to go down
		else if (y_target + 8 >= paddle_y + 16) begin
			ai_down <= 1'b1;
		end
	end
endmodule