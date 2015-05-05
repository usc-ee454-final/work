`timescale 1ns / 1ps	

`include "connect_parameters.v"

module Master_tb;
// This is the master testbench used to test and train our NNoC

//ROUTER CODE HERE
  parameter HalfClkPeriod = 5;
  localparam ClkPeriod = 2*HalfClkPeriod;

  // non-VC routers still reeserve 1 dummy bit for VC.
  localparam vc_bits = (`NUM_VCS > 1) ? $clog2(`NUM_VCS) : 1;
  localparam dest_bits = $clog2(`NUM_USER_RECV_PORTS);
  localparam flit_port_width = 2 /*valid and tail bits*/+ `FLIT_DATA_WIDTH + dest_bits + vc_bits;
  localparam credit_port_width = 1 + vc_bits; // 1 valid bit
  localparam test_cycles = 60;

  reg Clk;
  reg Rst_n;

  // input regs
  reg send_flit [0:`NUM_USER_SEND_PORTS-1]; // enable sending flits
  reg [flit_port_width-1:0] flit_in [0:`NUM_USER_SEND_PORTS-1]; // send port inputs

  reg send_credit [0:`NUM_USER_RECV_PORTS-1]; // enable sending credits
  reg [credit_port_width-1:0] credit_in [0:`NUM_USER_RECV_PORTS-1]; //recv port credits

  // output wires
  wire [credit_port_width-1:0] credit_out [0:`NUM_USER_SEND_PORTS-1];
  wire [flit_port_width-1:0] flit_out [0:`NUM_USER_RECV_PORTS-1];

  reg [31:0] cycle;
  integer i;

  // packet fields
  reg [dest_bits-1:0] dest;
  reg [vc_bits-1:0]   vc;
  reg [`FLIT_DATA_WIDTH-2:0] data;
  reg [`FLIT_DATA_WIDTH-2:0] hypothesis;

  // Generate Clock
  initial Clk = 0;
  always #(HalfClkPeriod) Clk = ~Clk;

  // Run simulation 
  initial begin 
    cycle = 0;
    for(i = 0; i < `NUM_USER_SEND_PORTS; i = i + 1) begin flit_in[i] = 0; send_flit[i] = 0; end
    for(i = 0; i < `NUM_USER_RECV_PORTS; i = i + 1) begin credit_in[i] = 0; send_credit[i] = 0; end
    
    $display("---- Performing Reset ----");
    Rst_n = 0; // perform reset (active low) 
    #(5*ClkPeriod+HalfClkPeriod); 
    Rst_n = 1; 
    #(HalfClkPeriod);

  end


  // Add your code to handle flow control here (sending receiving credits)
  // The code above sends data to port 1. Mult is attached to receive on port 1
  // and transmit to port 2.
  wire mult1_recv_flit, mult1_send_flit, mult2_recv_flit, mult2_send_flit;
  wire [flit_port_width-1:0] mult1_flit_in, mult2_flit_in;
  wire [flit_port_width-1:0] mult1_flit_out, mult2_flit_out;
  layer mult1(Clk, ~Rst_n, cycle, mult1_recv_flit, mult1_flit_in, 2, 0, mult1_send_flit, mult1_flit_out);
  layer mult2(Clk, ~Rst_n, cycle, mult2_recv_flit, mult2_flit_in, 3, 1, mult2_send_flit, mult2_flit_out);

  // Instantiate CONNECT network
  mkNetwork dut
  (.CLK(Clk)
   ,.RST_N(Rst_n)

   ,.send_ports_0_putFlit_flit_in(flit_in[0])
   ,.EN_send_ports_0_putFlit(send_flit[0])

   ,.EN_send_ports_0_getCredits(1'b1) // drain credits
   ,.send_ports_0_getCredits(credit_out[0])


   ,.send_ports_1_putFlit_flit_in(mult1_flit_out)
   ,.EN_send_ports_1_putFlit(mult1_send_flit)

   ,.EN_send_ports_1_getCredits(1'b1) // drain credits
   ,.send_ports_1_getCredits(credit_out[1])


   ,.send_ports_2_putFlit_flit_in(mult2_flit_out)
   ,.EN_send_ports_2_putFlit(mult2_send_flit)

   ,.EN_send_ports_2_getCredits(1'b1) // drain credits
   ,.send_ports_2_getCredits(credit_out[2])


   ,.send_ports_3_putFlit_flit_in(flit_in[3])
   ,.EN_send_ports_3_putFlit(send_flit[3])

   ,.EN_send_ports_3_getCredits(1'b1) // drain credits
   ,.send_ports_3_getCredits(credit_out[3])
   // add rest of send ports here
   //

   ,.EN_recv_ports_1_getFlit(1'b1) // drain flits
   ,.recv_ports_1_getFlit(mult1_flit_in)

   ,.recv_ports_1_putCredits_cr_in(credit_in[1])
   ,.EN_recv_ports_1_putCredits(send_credit[1])


   ,.EN_recv_ports_2_getFlit(1'b1) // drain flits
   ,.recv_ports_2_getFlit(mult2_flit_in)

   ,.recv_ports_2_putCredits_cr_in(credit_in[2])
   ,.EN_recv_ports_2_putCredits(send_credit[2])


   ,.EN_recv_ports_3_getFlit(1'b1) // drain flits
   ,.recv_ports_3_getFlit(flit_out[3])

   ,.recv_ports_3_putCredits_cr_in(credit_in[3])
   ,.EN_recv_ports_3_putCredits(send_credit[3])

   // add rest of receive ports here
   // 

   );


//Rest of Master TB

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

//TICTACTOE
reg BtnL, BtnR, BtnU, BtnD, BtnC;
wire P1Won, P2Won, PlayerMoved;
wire [3:0] I;
reg reset_ttt;
reg restart;
wire[8:0] P1, P2;
wire[62:0] convert;
integer x,z, i, correct_choice;

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
			#ClkPeriod;
			reset_ttt = 1;
			#ClkPeriod;
			reset_ttt = 0;
			
			output_vec = 63'h7FFFFFFFFFFFFFFF;

			while (~P1Won && ~P2Won)
				// while neither player has won
			begin
				#ClkPeriod;

				// 1. Let computer make a move (randomly)
				x = $unsigned($random(10)) % 9;	
						
				while (P1[x] || P2[x] ) //find an empty spot
				begin
						x = $unsigned($random(10)) % 9;	
						
				end

				$display("Computer selected a move: %d", x);

				case (x)
					0: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					1: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					2: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					3: begin
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
					end
					4: begin
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
					end
					5: begin
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
					end
					6: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end
					7: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end
					8: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end

				endcase
				// Let the game settle
				#(ClkPeriod);
				#(ClkPeriod);

				// 2. Let NN make a move
				//	- inject input flit to first router(game board state -> convert)

			   // send a single flit packet
			    send_flit[0] = 1'b1;
			    dest = 1;
			    vc = 0;
			    //Put game board as input.
			    data = convert;
			    flit_in[0] = {1'b1 /*valid*/, 1'b1 /*tail*/, dest, vc, 1'b0, data};
			    $display("@%3d: Injecting flit %x into send port %0d", cycle, flit_in[0], 0);
			    $display("@%3d: Sending flit %x to router %0d", cycle, flit_in[0], dest);

			    #(ClkPeriod);
			    // stop sending flits
			    send_flit[0] = 1'b0;
			    flit_in[0] = 'b0; // valid bit

				//	- wait for output flit on last router
							
			    while (send_flit[3] != 1'b1)
				#(ClkPeriod);

			    //Now flit is ready at end
			      send_flit[3] <= 1'b0;
			      flit_in[3] <= 'b0; // valid bit

			       hypothesis = flit_out[3][flit_port_width-2:0];

			   	#(ClkPeriod); 
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
							compare[y] = hypothesis[y + x*7];
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

				$display("Neural network played on space %d",max_i);

				case (max_i)
					0: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					1: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					2: begin
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
					end
					3: begin
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
					end
					4: begin
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
					end
					5: begin
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
					end
					6: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end
					7: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end
					8: begin
						BtnD = 1; #ClkPeriod; BtnD = 0; #ClkPeriod;
						BtnR = 1; #ClkPeriod; BtnR = 0; #ClkPeriod;
						BtnC = 1; #ClkPeriod; BtnC = 0; #ClkPeriod;
						BtnL = 1; #ClkPeriod; BtnL = 0; #ClkPeriod;
						BtnU = 1; #ClkPeriod; BtnU = 0; #ClkPeriod;
					end

				endcase

				// Let the game settle
				#(ClkPeriod);
				#(ClkPeriod);

				// 4. Train NN
				// 	- inject optimal game board state/correct move to last
				// 	router

				//TODO: Actually train using minimax
				correct_choice = $unsigned($random(10)) % 9;
				#(ClkPeriod);

				data = 63'h7FFFFFFFFFFFFFFF;
				data[7*correct_choice + 6] = 1'b0; //Make the choice strongly positive.

				//debug check
				#(ClkPeriod);

			      // send a single flit packet backprop
			      
			      send_flit[3] = 1'b1;
			      dest = 2;
			      vc = 0;
			      flit_in[3] = {1'b1 /*valid*/, 1'b1 /*tail*/, dest, vc, 1'b1, data};
			      #(ClkPeriod);

			      //Stop sending flits
			      send_flit[3] = 1'b0;
				flit_in[3] = 'b0; // valid bit
			      $display("@%3d: Sending backprop flit %x to router %0d", cycle, flit_in[3], dest);


			      $display ("Completed first training instance");
			end
		end //end for
	
		//TEST
		player1_total =0;
		player2_total =0;
		for (test_num = 0; test_num < NUM_TESTS; test_num = test_num +1)
		begin
			//Clear the board
			reset_ttt = 0;
			#ClkPeriod;
			reset_ttt = 1;
			#ClkPeriod;
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
always begin #ClkPeriod; clk = ~clk; end

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
