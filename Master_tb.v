`timescale 1ns / 1ps	

module Master_tb;
// This is the master testbench used to test and train our NNoC


parameter CLK_PERIOD = 10, NUM_TRAINING_EXAMPLES = 100, NUM_TESTS = 10;

integer test_num, player1_total, player2_total,  y, max_i, rank_solution;
integer start, finish;
integer file_in, file_out, r;
wire player1_win, player2_win;
reg clk;
reg signed [6:0] max;
reg signed [6:0] compare;
reg [3:0] tried_solutions [8:0];
reg [8:0] P1_ideal;
reg [8:0] P2_ideal;
reg not_tried;

reg [62:0]output_vec;
//DEBUG
reg [96*8:1] string; 

// ADD ROUTER MODULES HERE

//TICTACTOE
reg BtnL, BtnR, BtnU, BtnD, BtnC;
wire P1Won, P2Won, PlayerMoved;
wire [3:0] I;
reg reset_ttt;
reg restart;
wire[8:0] P1, P2;
wire[62:0] convert;
reg [3:0] x;
tic_tac_toe boardA (.Clk(clk), .reset(reset_ttt), .restart(restart), .BtnL(BtnL), .BtnR(BtnR), .BtnU(BtnU), .BtnD(BtnD), .BtnC(BtnC), 
			.P1Won(P1Won), .P2Won(P2Won), .I(I), .PlayerMoved(PlayerMoved), .P1(P1), .P2(P2), .convert(convert) );
//END TICTACTOE

initial
	begin
	$display("Starting test bench (master): ");
	clk = 0;
	BtnL = 0;
	BtnC = 0;
	BtnR = 0;
	BtnU = 0;
	BtnD = 0;	

		//TRAINING
		for (test_num = 0; test_num < NUM_TRAINING_EXAMPLES; test_num = test_num + 1)
		begin
			// Clear the game board
			$display("Clearing game board - Starting training %d", test_num);

			reset_ttt = 0;
			#CLK_PERIOD;
			reset_ttt = 1;
			#CLK_PERIOD;
			reset_ttt = 0;
			
			output_vec = 63'h7FFFFFFFFFFFFFFF;

			while (~P1Won && ~P2Won)
				// while neither player has won
			begin
				#CLK_PERIOD;

				// 1. Let computer make a move (randomly)
				x = 10;
				while (x >= 9)
					x = $random(100);	
				while (P1[x] || P2[x] ) //find an empty spot
				begin
					while (x >= 9)
						x = $random(100);	
						
				end

				$display("Computer selected a move: %d", x);

				case (x)
					0: begin
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
					end
					1: begin
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
					end
					2: begin
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
					end
					3: begin
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
					end
					4: begin
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
					end
					5: begin
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
					end
					6: begin
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
					end
					7: begin
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
					end
					8: begin
						BtnD = 1; #CLK_PERIOD; BtnD = 0; #CLK_PERIOD;
						BtnR = 1; #CLK_PERIOD; BtnR = 0; #CLK_PERIOD;
						BtnC = 1; #CLK_PERIOD; BtnC = 0; #CLK_PERIOD;
						BtnL = 1; #CLK_PERIOD; BtnL = 0; #CLK_PERIOD;
						BtnU = 1; #CLK_PERIOD; BtnU = 0; #CLK_PERIOD;
					end

				endcase

				// 2. Let NN make a move
				//	- inject input flit to first router(game board state -> convert)
				//	- wait for output flit on last router
				

				// 3. Transform output into game move (i.e. highest
				// valued, possible value)
				rank_solution = 1;
				//tried_solutions = 0;
				
				while (rank_solution  <= 9)
				begin
					max = 7'b1111111; // equivalent to max negative num
					max_i = 0;
					for (x =0; x < 9; x = x + 1)
					begin
						not_tried = 1;
						//eliminate already tried solutions
						for (y = 0; y < rank_solution - 1; y = y +1)
						begin
							if (x == tried_solutions[y]) begin
								not_tried = 0;
							end
						end	

						for (y= 0; y < 7; y = y + 1) begin
							compare[y] = output_vec[y + x*7];
						end


						if (not_tried && max <= compare)
						begin
							max = compare; 
							max_i = x;
						end //end if
					end //end for

					//Now we will try max_i as the
					//rank_soltuion'd best solution
					tried_solutions[rank_solution-1] = max_i;

					if (P1[max_i] || P2[max_i]) // if there is a conflict on the board..
					begin
						rank_solution = rank_solution + 1;	
					end
					else //done
					begin
						rank_solution = 10;
					end
				end

				// 4. Train NN
				//
				//x = $random(100) % 10;	
				//while ( P1[x] || P2[x] ) //find an empty spot
				//begin
				//	x = $random(100) % 10;	  		
				//end

				x = 10;
				while (x >= 9)
					x = $random(100);	
				while (P1[x] || P2[x] ) //find an empty spot
				begin
					while (x >= 9)
						x = $random(100);	
						
				end

				$display("Learning a random move -- %d", x);

				// 	- inject optimal game board state/correct move to last
				// 	router (use max_i)
				// 	- wait for output flit on first router (done
				// 	learning on this example)
				//
			end
		end //end for
	
		//TEST
		player1_total =0;
		player2_total =0;
		for (test_num = 0; test_num < NUM_TESTS; test_num = test_num +1)
		begin
			//Clear the board
			reset_ttt = 0;
			#CLK_PERIOD;
			reset_ttt = 1;
			#CLK_PERIOD;
			reset_ttt = 0;


			while (~P1Won && ~P2Won)
				// while neither player has won
				begin
					// 1. Let computer make a move (randomly)
					x = $random(100) % 10;	
					while ( P1[x] || P2[x] ) //find an empty spot
					begin
						x = $random(100) % 10;	  		
					end

					// 2. Let NN make a move
					//	- inject input flit to first router(game board state)
					//	- wait for output flit on last router
					// 3. Transform output into game move (i.e. highest
					// valued, possible value)

				end		
			if (P1Won)
			begin
				player1_total = player1_total + 1;
			end
			else if (P2Won)
			begin
				player2_total = player2_total + 1;
			end
		end //end for
	end //end initial

//CLOCK
always begin #CLK_PERIOD; clk = ~clk; end

initial
begin

	if (0)
	begin
				file_out = 0;
				while (file_out == 0)
				begin	
					file_out = $fopen("input_to_minimax.txt", "w");
				end
			
				// seek to beginning
				r = $fseek(file_out, 0, 0);

				//P1
				for (x = 0; x < 9; x = x + 1)
				begin
					//r = $fwrite(file_out, "%d", P1[x]);

					if (P1[x] == 0)
						$display("0", file_out);
					else
						$display("1", file_out);
				end

				//r = $fwrite(file_out, ",");
				$display(",", file_out);

				//P2
				for (x = 0; x < 9; x = x + 1)
				begin
					if (P2[x] == 0)
						$display("0", file_out);
					else
						$display("1", file_out);
						//r = $fwrite(file_out, "1");
				end
				
				//Now, read
				file_in = 0;
				while (file_in == 0)
				begin
					file_in = $fopen("input_to_tb.txt", "r");
				end

				// seek to beginning
				r = $fseek(file_in, 0, 0);
				
				//Read file
				for (x=0;x<19;x = x+1)
				begin
					r = $fgetc(file_in);
					if (r == "0")
					begin
						if (x < 9)
						P1_ideal[x] = 0;
						if (x > 9)
						P2_ideal[x-10] = 0;

					end
					else if (r == "1")
					begin
						if (x < 9)
							P1_ideal[x] = 1;
						if (x > 9)
							P2_ideal[x-10] = 1;
					end
					else if (r == ",")
					begin
					end
				end
				$fclose(file_in);
				$fclose(file_out);

				$stop;
			end
end

endmodule
