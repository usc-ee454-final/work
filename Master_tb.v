`timescale 1ns / 1ps	

module Master_tb();
// This is the master testbench used to test and train our NNoC


parameter CLK_PERIOD = 10, NUM_TRAINING_EXAMPLES = 100, NUM_TESTS = 10;

integer test_num, player1_total, player2_total, x, y, max_i, rank_solution;
wire player1_win, player2_win;
reg clk;
reg signed [6:0] max;
reg [3:0] tried_solutions [8:0];
reg not_tried;


// ADD ROUTER MODULES HERE

//TICTACTOE

reg BtnL, BtnR, BtnU, BtnD, BtnC;
wire P1Won, P2Won, PlayerMoved;
wire [3:0] I;
reg reset_ttt;
reg restart;
wire[8:0] P1, P2;
wire[62:0] convert;

tic_tac_toe boardA (.Clk(clk), .reset(reset_ttt), .restart(restart), .BtnL(BtnL), .BtnR(BtnR), .BtnU(BtnU), .BtnD(BtnD), .BtnC(BtnC), 
			.P1Won(P1WonA), .P2Won(P2WonA), .I(Ia), .PlayerMoved(PM_a), .P1(P1), .P2(P2), .convert(convert) );
//END TICTACTOE

initial
	begin
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
				//	- inject input flit to first router(game board state -> convert)
				//	- wait for output flit on last router

				// 3. Transform output into game move (i.e. highest
				// valued, possible value)
				rank_solution = 1;
				tried_solutions = 0;
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
						if (not_tried && max <= output_vec[7*x+6:7*x])
						begin
							max = output_vec[7*(x+1):7*x];
							max_i = x;
						end
					end

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
			#CLK_PERIOD:
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

endmodule
