module game_top(CLOCK_50, KEY, SW, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N); //blank pixel
	input wire CLOCK_50;
	input wire [3:0] KEY;
	input [9:0] SW;
	output wire [7:0] VGA_R, VGA_G, VGA_B;
	output wire VGA_HS, VGA_VS, VGA_CLK; //horizontal and vertical sync, pixel clock
	output wire VGA_BLANK_N, VGA_SYNC_N;
	 
	wire resetn = KEY[0];
	//switches to control paddle movement
	wire SW_left = SW[1];
	wire SW_right = SW[0];

	wire [9:0] P_X, B_X;
	wire [8:0] B_Y;
	wire [17:0] Bricks;
	wire Enable;
	wire ball_outBound;
	
	wire signed [5:0] B_Vx, B_Vy;
	
	Clock_60Hz c(resetn, CLOCK_50, Enable);

	game_logic (CLOCK_50, resetn, Enable, SW_left, SW_right, P_X, B_X, B_Y, Bricks, ball_outBound);
	
	VGA_paint(CLOCK_50, resetn, Enable, ball_outBound, P_X, B_X, B_Y, Bricks, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N);

endmodule


module game_logic (Clock, Reset, Enable, left, right, P_X, B_X, B_Y, Bricks, ball_outBound);
    input Clock, Reset, Enable, left, right;
    output [9:0] P_X, B_X;
    output [8:0] B_Y;
	 output [17:0] Bricks;
    output ball_outBound;

    wire signed[6:0] B_Vx, B_Vy;
	 wire if_paddle_collision;
	 
	 ball_position b(Clock, Reset, Enable, P_X, B_X, B_Y, B_Vx, B_Vy, ball_outBound, Bricks, if_paddle_collision);
    paddle_position p(Clock, Reset, Enable, left, right, P_X);

endmodule


module ball_position (Clock, Reset, Enable, P_X, B_X, B_Y, B_Vx, B_Vy, ball_outBound, bricks, if_paddle_collision);
    input Clock, Enable, Reset;
    input [9:0] P_X;

    output [9:0] B_X;
    output [8:0] B_Y;
    output signed [6:0] B_Vx, B_Vy;
    output ball_outBound;

    reg signed [10:0] X, x;
    reg signed [9:0] Y, y;
    reg signed [6:0] Vx, Vy, vx, vy;
    reg ball_OB, ball_ob;
    wire [17:0] brick_ifCollision;
    wire [1:0] collision_count;
    reg [3:0] Brick_num;
    reg [17:0] Bricks;
    output reg [17:0] bricks;

	 output if_paddle_collision;
    wire [2:0] v_collision_bp, h_collision_bp, v_collision_bb, h_collision_bb;

    parameter side_length = 11'd10;
    parameter brick_n = 18;
	 	 
	initial begin 
		 x <= 10'd320;
       y <= 400;
		 bricks <= 18'b111111111111111111;
	end

    ball_paddle_collision bp(x[9:0], y[8:0], P_X, if_paddle_collision, v_collision_bp, h_collision_bp);
    ball_brick_collision bb (x[9:0], y[8:0], bricks, collision_count, brick_ifCollision, v_collision_bb, h_collision_bb);
	 integer k;

    always@(*)
    begin
        X = x + vx;

        Y = y + vy;
		  
		  Vx = vx;
		  Vy = vy;
		  ball_OB = ball_ob;

		 if (bricks <= 18'b0)
		 begin
			X = x;
			Y = y;
		 end

        if(X < 0)
        begin
            X = 11'd0;
            Vx = -vx;
        end
        else if(X + side_length >= 11'd640)
        begin
            X = 11'd640 - side_length;
            Vx = -vx;
        end

        if(Y < 0)
        begin
            Y = 10'd0;
            Vy = -vy;
        end
        else if(Y + side_length >= 10'd480)
        begin
            ball_OB = 1'b1;
            Y = 10'd480 - side_length;
            Vy = 7'b0;
            Vx = 7'b0;
        end

		  if (if_paddle_collision == 1)
			begin
				Vy = -2;
        end

        if (collision_count != 0)
        begin
            if(v_collision_bb > h_collision_bb)
            begin
                Vx = -vx;
            end
            else
            begin
                Vy = -vy;
            end
        end

        for (k = 0; k < brick_n; k=k+1)
        begin
            if (brick_ifCollision[k])
                Bricks[k] = 0;
            else
                Bricks[k] = bricks[k];
        end
        

    end 

    always@(posedge Clock)
        if(!Reset)
        begin
            x <= 10'd320;
            y <= 400;
            vx <= 2;
            vy <= 2;
            ball_ob <= 1'b0;
            bricks <= 18'b111111111111111111;
        end
        else if (Enable)
        begin
            x <= X;
            y <= Y;
            vx <= Vx;
            vy <= Vy;
            ball_ob <= ball_OB;
            bricks <= Bricks;
        end

    assign B_X = x[9:0];
    assign B_Y = y[8:0];
    assign B_Vx = vx;
    assign B_Vy = vy;
    assign ball_outBound = ball_OB;

endmodule


module paddle_position(Clock, Reset, Enable, left, right, P_X);
    input Clock, Reset, Enable, left, right;
    output [9:0] P_X;

    parameter oneMove = 3'd5;
    parameter width = 11'd100, height = 1'd1;

    reg signed [10:0] X, x;
	 
	initial begin 
		x = 11'd320 - (width/2);

	end
	 

    always@(*)
    begin
        if (left)
            X = x - oneMove;
        else if(right)
            X = x + oneMove;
        else
            X = x;

        if (X < 0)
            X = 11'b0;
        else if (X + width >= 11'd640)
            X = 11'd640 - width;
        
    end

    always@(posedge Clock)
    begin
        if(!Reset)
        begin
            x <= 11'd320 - (width/2);
        end
        else if (Enable)
        begin
            x <= X;
        end
    end

    assign P_X = x[9:0];

endmodule


module ball_paddle_collision(B_X, B_Y, P_X, if_paddle_collision, v_collision, h_collision);
    input [9:0] B_X, P_X;
    input [8:0] B_Y;

    output if_paddle_collision;
    reg if_v_collision, if_h_collision;
    output reg [2:0] v_collision, h_collision;

    parameter P_Y = 440 ;
    parameter P_width = 100, P_height = 12;
    parameter B_width = 10, B_height = 10;

    always@(*)
    begin
        if_h_collision = 1'b0;
        if_v_collision = 1'b0;

        if (B_X >= P_X && B_X <= P_X + P_width)
        begin
            if_h_collision = 1'b1;
            if (B_X + B_width > P_X + P_width)
                h_collision = P_X + P_width - B_X;
            else
                h_collision = B_width;
        end
        else if(P_X >= B_X && P_X <= B_X + B_width)
        begin
            if_h_collision = 1'b1;
            h_collision = B_X + B_width - P_X;
        end

        if (B_Y >= P_Y && B_Y <= P_Y + P_height)
        begin
            if_v_collision = 1'b1;
            v_collision = P_Y + P_height - B_Y;
        end
        else if(P_Y >= B_Y && P_Y <= B_Y + B_height)
        begin
            if_v_collision = 1'b1;
             if (B_Y + B_height > P_Y + P_height)
                v_collision = P_height;
            else
                v_collision = B_Y + B_height - P_Y;
        end
    end


    assign if_paddle_collision = (if_h_collision & if_v_collision);

endmodule


module ball_brick_collision(B_X, B_Y, Bricks, collision_count, brick_ifCollision, v_collision, h_collision);
    input [9:0] B_X;
    input [8:0] B_Y;
    input [17:0] Bricks;
    output reg [17:0] brick_ifCollision;

    output reg [1:0] collision_count;
    output reg [2:0] v_collision, h_collision;

    parameter Bricks_X = 0, Bricks_Y = 0;
    parameter Bricks_R = 630, Bricks_B = 165;
    parameter Bricks_h = 3, Bricks_w = 6;
    parameter Bricks_width = 105, Bricks_height = 55;
    parameter B_width = 10, B_height = 10;

    reg [9:0] brick_x;
    reg [8:0] brick_y;

    reg [4:0] nTL, nTR, nBL, nBR;

    always@(*)
    begin
	 
		  collision_count = 0;
        v_collision = 0;
        h_collision = 0;
        brick_ifCollision = 0;
        if (B_X >= Bricks_X & B_X < Bricks_R & B_Y >= Bricks_Y & B_Y < Bricks_B)
        begin
            nTL = ((B_X - Bricks_X)/Bricks_width) + (Bricks_w * ((B_Y - Bricks_Y)/Bricks_height));
            nTR = (B_X + B_width - Bricks_X)/Bricks_width + (Bricks_w * ((B_Y - Bricks_Y)/Bricks_height));
            nBL = (B_X - Bricks_X)/Bricks_width + (Bricks_w * ((B_Y + B_height - Bricks_Y)/Bricks_height));
            nBR = (B_X + B_width - Bricks_X)/Bricks_width + (Bricks_w  * ((B_Y + B_height - Bricks_Y)/Bricks_height));

            if (Bricks[nTL])
            begin
                brick_ifCollision[nTL] = 1;
                collision_count = collision_count + 1;
                brick_x = Bricks_X + Bricks_width * (nTL % Bricks_w);
                brick_y = Bricks_Y + Bricks_height * (nTL / Bricks_w);
				 
					 h_collision = h_collision + brick_x + Bricks_width - B_X;
					 v_collision = v_collision + brick_y + Bricks_height - B_Y;

            end
				else if (Bricks[nTR] & !brick_ifCollision[nTR])
				begin
					h_collision = h_collision + B_X - brick_x;
					v_collision = v_collision + brick_y + Bricks_height - B_Y;
				end
				
				else if (Bricks[nBL] & !brick_ifCollision[nBL])
				begin
					h_collision = h_collision + brick_x + Bricks_width - B_X;
					v_collision = v_collision + B_Y - brick_y;
				end
				
				else if (Bricks[nBR] & !brick_ifCollision[nBR])
				begin
					h_collision = h_collision + B_X - brick_x;
					v_collision = v_collision + B_Y - brick_y;
				end
        end
    end
endmodule


module VGA_paint(Clock, resetn, Enable, ball_outBound, P_X, B_X, B_Y, Bricks, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N);
	
	input Clock, resetn, Enable;
	input ball_outBound;
	input [9:0] P_X, B_X;
	input [8:0] B_Y;
   input [17:0] Bricks;
	output wire [7:0] VGA_R, VGA_G, VGA_B;
	output wire VGA_HS, VGA_VS, VGA_CLK; //horizontal and vertical sync, pixel clock
	output wire VGA_BLANK_N, VGA_SYNC_N;
	 
	//paddle
	parameter P_Y = 440;
	parameter P_WIDTH = 100;
	parameter P_HEIGHT = 12;
	parameter HEIGHT = 480;
	parameter WIDTH = 640;
	 
	//ball
	parameter B_WIDTH = 10;
	parameter B_HEIGHT = 10;
	
	reg [9:0] x; // 10 bits for 640 columns
	reg [8:0] y; // 9 bits for 480 rows
	reg [8:0] color; // 9-bit color
	reg write;
	reg start;
	
	//YOU LOST display
	
	// Y
	wire Y2 = (x >= 160 && x < 170 && y >= 220 && y < 240) ||  // left arm
              (x >= 190 && x < 200 && y >= 220 && y < 240) || // right arm
              (x >= 175 && x < 185 && y >= 240 && y < 260);   // tail

	// O (Outer part of O and hole for the center)
	wire O2 = (x >= 210 && x < 240 && y >= 220 && y < 260) &&
              !((x >= 218 && x < 232) && (y >= 228 && y < 252));

	// U (Left side, right side, and bottom of U)
	wire U2 = (x >= 250 && x < 260 && y >= 220 && y < 260) ||
              (x >= 280 && x < 290 && y >= 220 && y < 260) ||
              (x >= 260 && x < 280 && y >= 250 && y < 260);

	// L (Vertical line + bottom of L)
	wire L1 = (x >= 300 && x < 310 && y >= 220 && y < 260) ||
              (x >= 300 && x < 340 && y >= 250 && y < 260);

	// O (Second O in "LOST", same as first O but without hole in center)
	wire O3 = (x >= 350 && x < 380 && y >= 220 && y < 260) &&
              !((x >= 358 && x < 372) && (y >= 228 && y < 252));

	// S (Top, middle, and bottom parts of S)
	wire S1 = (x >= 390 && x < 430 && y >= 220 && y < 228) || 
              (x >= 390 && x < 430 && y >= 234 && y < 242) ||
              (x >= 390 && x < 430 && y >= 252 && y < 260) ||
				  (x >= 390 && x < 400 && y >= 220 && y < 234) ||
				  (x >= 420 && x < 430 && y >= 242 && y < 260);

	// T (Top horizontal bar and vertical bar of "T")
	wire T1 = (x >= 440 && x < 480 && y >= 220 && y < 228) ||
              (x >= 455 && x < 465 && y >= 220 && y < 260);

	// Combine all letters for "YOU LOST!" display
	wire youlost_display = Y2 || O2 || U2 || L1 || O3 || S1 || T1;
	
	
	//you win! display
	wire all_bricks_cleared = (Bricks == 18'b000000000000000000);
	
	// Y
	wire Y1 = (x >= 185 && x < 195 && y >= 220 && y < 240) ||  // left arm
				  (x >= 215 && x < 225 && y >= 220 && y < 240) || // right arm
				  (x >= 200 && x < 210 && y >= 240 && y < 260);   // tail

	// O
	wire O1 = (x >= 235 && x < 265 && y >= 220 && y < 260) &&
				  !((x >= 243 && x < 257) && (y >= 228 && y < 252));

	// U
	wire U1 = (x >= 275 && x < 285 && y >= 220 && y < 260) ||
				  (x >= 305 && x < 315 && y >= 220 && y < 260) ||
				  (x >= 285 && x < 305 && y >= 250 && y < 260);

	// W
	wire W1 = (x >= 325 && x < 335 && y >= 220 && y < 260) ||
				  (x >= 355 && x < 365 && y >= 220 && y < 260) ||
				  (x >= 340 && x < 350 && y >= 250 && y < 260);

	// I
	wire I1 = (x >= 375 && x < 385 && y >= 220 && y < 260);

	// N
	wire N1 = (x >= 395 && x < 405 && y >= 220 && y < 260) ||
				  (x >= 415 && x < 425 && y >= 240 && y < 250) ||
				  (x >= 425 && x < 435 && y >= 220 && y < 260) ||
				  (x >= 405 && x < 415 && y >= 230 && y < 240);

	//!
	wire EX1 = (x >= 445 && x < 455 && y >= 220 && y < 250) ||
					(x >= 445 && x < 455 && y >= 255 && y < 260);

	// combine all letters
	wire youwin_display = Y1 || O1 || U1 || W1 || I1 || N1 || EX1;
	
	// brick
	reg [4:0] brick_index;
	
	parameter Brick_Row = 3, Brick_Col = 6;
	parameter Brick_H = 55, Brick_W = 105;

	 
	initial begin 
		x = 0;
		y = 0;

	end
	 
	always @(posedge Clock)
		begin
			if (!resetn)
			begin
				x <= 0;
				y <= 0;
				start <= 1;
				write <= 1;
				brick_index = 0;
			end
			else if (Enable)
			begin
				start <= 1;
				write <= 1;
				brick_index = 0;
			end
			else if (start)
			begin
				if (ball_outBound) //heighest priority, only display this
				begin
					if(youlost_display)
					begin
						color <= 9'b111_000_111;	// magenta "YOU LOST!"
					end
					
					else
					begin
						color <= 9'b111_111_111; //white screen
					end	
				end
				
				else if (all_bricks_cleared) 
				begin
					if(youwin_display)
					begin
						color <= 9'b111_000_111; // magenta "YOU WIN!"
					end
					
					else
					begin
						color <= 9'b111_111_111; //white screen
					end	
				end
				
				else
				begin
					if (x >= P_X & x < P_X + P_WIDTH & y >= P_Y & y < P_Y + P_HEIGHT) //paddle
						color <= 9'b000_111_111;
					else if (x >= B_X & x < B_X + B_WIDTH & y >= B_Y & y < B_Y + B_HEIGHT) //ball
						color <= 9'b000_000_000;
					else if (y >= 0 & y < 165 & x >= 0 & x < 630) //brick
                begin
                    brick_index = (x/Brick_W) + (Brick_Col * (y/Brick_H));
						  //brick_index = 0;
                    if (brick_index < 18 & Bricks[brick_index])
						  begin
                        if (brick_index == 0 | brick_index == 7 | brick_index == 14 )
                            color <= 9'b111_110_011; //yellow
									 
								else if (brick_index == 1 | brick_index == 8 | brick_index == 15 )
									color <= 9'b010_100_111; //blue
									
								else if (brick_index == 2 | brick_index == 9 | brick_index == 16 )
									color <= 9'b111_010_010; //pinkish red
									
								else if (brick_index == 5 | brick_index == 6 | brick_index == 13 )
									color <= 9'b011_000_111; //purple
									
								else if (brick_index == 4 | brick_index == 11 | brick_index == 12 )
									color <= 9'b111_101_100; //pink
									
                        else
									 color <= 9'b000_101_101; //green
						  end
                    else
						  begin
                        color <= 9'b111_111_111;
							end
						
                end
					else
						color <= 9'b111_111_111; //white screen
				end
				
				
				x <= x + 1;
				if(x == WIDTH - 1)
				begin
					x <= 0;
					y <= y + 1;
				end
				if (y == HEIGHT - 1)
				begin
					y <= 0;
					start <= 0;
					write <= 0;
				end
			end
		end
		
	vga_adapter VGA(resetn, Clock, color, x, y, write, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	defparam VGA.BACKGROUND_IMAGE = "none"; //overwrites the rainbow

endmodule


module Clock_60Hz(Reset, Clock, Enable_60hz);
	input Reset;
	input Clock;
	output reg Enable_60hz;
	
	reg [19:0] digit;
	
	always@(posedge Clock)
	begin 
		if (!Reset)
		begin
			digit <= 20'd0;
			Enable_60hz <= 1'b0;
		end
		else if(digit == 20'd833333)
		begin
			digit <= 20'd0;
			Enable_60hz <= 1'b1;
		end
		else
		begin
			digit <= digit + 1;
			Enable_60hz <= 1'b0;
		end
	end
	
endmodule
