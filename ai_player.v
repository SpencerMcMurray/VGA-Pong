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
			if (ball_down) begin // update targeted y coordinate if ball going down
				y_target <= ball_y  + y_distance > 120 ? 240 - ball_y-y_distance : ball_y+y_distance;
			end
			else begin //if ball going up
				y_target <= $signed(ball_y - y_distance) < $signed(0) ? y_distance - ball_y: ball_y - y_distance;
			end
		end
		
		if (y_target - 4 <= paddle_y) begin // lift ai if targeted y coord is lower than the paddle's
			ai_up <= 1'b1;
		end
		else if (y_target + 8 >= paddle_y + 16) begin // lower ai if targeted y coord is higher than the paddle's
			ai_down <= 1'b1;
		end
	end
endmodule