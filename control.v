module control(
	input clk,
	input resetn,
	input enter,	// From keyboard
	input gameover,
	
	// Output based on state
	output reg menu,
	output reg move_pads,
	output reg move_ball,
	output reg set_up_clear_screen,
	output reg clear_screen,
	output reg load_left_pad,
	output reg draw_left_pad,
	output reg load_right_pad,
	output reg draw_right_pad,
	output reg load_ball,
	output reg draw_ball,
	output reg reset_delta,
	output reg plot
	);
	
	// Number of clock ticks we need to do each operation
	localparam 	PAD_COUNTER_LENGTH 			= 6'b100000,
				BALL_COUNTER_LENGTH 		= 5'b10100,
				FRAME_COUNTER_LENGTH		= 20'b11001011011100110101,
				CLEAR_SCREEN_COUNTER_LENGTH	= 15'b100101100000000;
				
	// State registers and counters
	reg [5:0] draw_left_pad_counter;
	reg [5:0] draw_right_pad_counter;
	reg [4:0] draw_ball_counter;
	reg [19:0] frame_counter;
	reg [14:0] clear_screen_counter;
	reg [3:0] current_state, next_state; 
    
	// States
    localparam  S_MENU        			= 4'd0,
                S_MOVE_PADS   			= 4'd1,
                S_MOVE_BALL 			= 4'd2,
				S_LOAD_CLEAR_SCREEN		= 4'd3,
				S_CLEAR_SCREEN			= 4'd4,
				S_LOAD_LEFT				= 4'd5,
                S_DRAW_LEFT_PAD  		= 4'd6,
				S_LOAD_RIGHT			= 4'd7,
				S_DRAW_RIGHT_PAD		= 4'd8,
				S_LOAD_BALL				= 4'd9,
				S_DRAW_BALL				= 4'd10,
				S_WAIT					= 4'd11;
	
	// State table
	always @(*)
	begin: state_table 
            case (current_state)
                S_MENU: next_state = enter ? S_MOVE_BALL : S_MENU;
				S_MOVE_BALL: next_state = (gameover == 1) ? S_MENU : S_MOVE_PADS; 
                S_MOVE_PADS: next_state = S_LOAD_CLEAR_SCREEN;
				S_LOAD_CLEAR_SCREEN: next_state = S_CLEAR_SCREEN;
				S_CLEAR_SCREEN: next_state = (clear_screen_counter == 0) ? S_LOAD_LEFT : S_CLEAR_SCREEN;
				S_LOAD_LEFT: next_state = S_DRAW_LEFT_PAD;
                S_DRAW_LEFT_PAD: next_state = (draw_left_pad_counter == 0) ? S_LOAD_RIGHT: S_DRAW_LEFT_PAD;
				S_LOAD_RIGHT: next_state = S_DRAW_RIGHT_PAD;
				S_DRAW_RIGHT_PAD: next_state = (draw_right_pad_counter == 0) ? S_LOAD_BALL : S_DRAW_RIGHT_PAD;
				S_LOAD_BALL: next_state = S_DRAW_BALL;
				S_DRAW_BALL: next_state = (draw_ball_counter == 0) ? S_WAIT : S_DRAW_BALL;
				S_WAIT: next_state = (frame_counter == 0) ? S_MOVE_BALL : S_WAIT;
			default:     next_state = S_MENU;
        endcase
    end
	
	// State logic
	always @(*)
    begin: enable_signals
        // By default make all our signals 0
        move_pads	 		= 1'b0;
		move_ball 			= 1'b0;
		load_clear_screen 	= 1'b0;
		clear_screen 		= 1'b0;
		draw_left_pad 		= 1'b0;
		draw_right_pad 		= 1'b0;
		draw_ball 			= 1'b0;
		reset_delta 		= 1'b0;
		plot 				= 1'b0;
		menu				= 1'b0;

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
			S_LOAD_CLEAR_SCREEN: begin
				reset_delta <= 1'b1;
				load_clear_screen <= 1'b1;
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
			S_LOAD_LEFT: begin
				load_left_pad <= 1'b1;
				reset_delta <= 1'b1;
				end
			S_LOAD_RIGHT: begin
				load_right_pad <= 1'b1;
				reset_delta <= 1'b1;
				end
			S_LOAD_BALL: begin
				load_ball <= 1'b1;
				reset_delta <= 1'b1;
				end
			
        endcase
    end
	
	// Update current state, and update each counter on the clock edge
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
    end
endmodule