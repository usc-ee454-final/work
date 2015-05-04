module MatMul_Module(clk, packed_7_9_in, mult, backprop, ack, valid, packed_7_9_out, reset, output_layer);
    
	parameter IDLE=0, FORWARD=1, SENDMSG_FORWARD=2, CALC_F_PRIME=3, BACKPROP_WAITING = 4, SENDMSG_BACK = 5, BACKPROP_CALC = 6, UPDATE_WEIGHTS = 7, WIDTH = 9, MAX_NUM=255, PK_WIDTH=7, PK_LEN=9, LEARNING_RATE = 1;
	input clk, reset, mult, backprop;
	input ack;
   	input [62:0] packed_7_9_in; //7x9
	input output_layer;

	output [62:0] packed_7_9_out;	
	output reg valid;

	
	//Internal in/out vectors (unpacked)
	wire [6:0] in_vector [8:0];
	reg signed [6:0] out_vector [8:0];

	//pack
	genvar pk_idx;
	generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1)
		begin 
			assign packed_7_9_out[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = out_vector[pk_idx][((PK_WIDTH)-1):0]; 
		end
 	endgenerate

	

	//unpack array
 	genvar unpk_idx; 
	generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) 
		begin
			assign in_vector[unpk_idx][((PK_WIDTH)-1):0] = packed_7_9_in[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; 
		end 
	endgenerate

	reg [4:0] state;

	//Vector is 7bits x input_size
	reg signed [6:0] current_vec [8:0];

	// This reg holds the weights from this layer's nodes to the next layer's nodes.
	reg signed [6:0] weight_mat [8:0][8:0];

	reg signed [6:0] activation_func [127:0];
	reg signed [6:0] activation_func_prime [127:0];

	//The calculated z_output values
	reg [6:0] f_prime [8:0];

	integer x,y;

	reg [4:0] i, j;
	
	reg signed [15:0] temp[8:0];	
	reg signed [6:0] z [8:0];	
	//DEBUG ONLY
	reg signed [13:0] inter[8:0][8:0];
	reg signed [6:0] inter_small[8:0][8:0];

	reg signed [15:0] calc_int;

	always @(posedge clk)
	begin
		if (reset)
		begin
			state <= IDLE;	
			//initialize output vectors to 0	
			valid <= 0;
			z[0] <= 0;
			z[1] <= 0;
			z[2] <= 0;
			z[3] <= 0;
			z[4] <= 0;
			z[5] <= 0;
			z[6] <= 0;
			z[7] <= 0;
			z[8] <= 0;


			for (x = 0; x < 128; x = x + 1)
			begin
				// fill in LUTs
				// TODO: sigmoid calculations
				if (x >	100) begin
					activation_func[x] = 127; //fully negative
				end
				else if (x > 40 && x < 64) begin
					activation_func[x] = 63; //fully positive
				end
				else begin	
					activation_func[x] = x;
				end

					activation_func_prime[x] = 63; //i.e. 1

			end	

			for (x = 0; x < 9; x = x + 1)
			begin
				for (y=0; y < 9; y = y + 1)
				begin
					if (x + y > 13)
					begin		
						weight_mat[x][y] = 7'b0000101;
					end
					else if (x+y > 7)
					begin		
						weight_mat[x][y] = 7'b1111110;
					end
					else 
					begin
						weight_mat[x][y] = 7'b0000001;
					end
					
				end
			end	
		end
		else
		begin
			if (state == IDLE)
			begin
				if (mult)
				begin
					state <= FORWARD;
					current_vec[0] <= in_vector[0];	
					current_vec[1] <= in_vector[1];	
					current_vec[2] <= in_vector[2];	
					current_vec[3] <= in_vector[3];	
					current_vec[4] <= in_vector[4];	
					current_vec[5] <= in_vector[5];	
					current_vec[6] <= in_vector[6];	
					current_vec[7] <= in_vector[7];	
					current_vec[8] <= in_vector[8];	
						
				end
			end

			else if (state == FORWARD)
			begin
				state <= SENDMSG_FORWARD;

				for (i = 0; i < WIDTH; i = i+1) begin

					//Compute this column of the matrix
					//For each value of the weight matrix, consider if it is positive or negative

					temp[i] = 0;
					for (j = 0; j < WIDTH; j = j + 1)
						begin
							temp[i] = temp[i] + ((weight_mat[i][j] * current_vec[j]));
							inter[i][j] = (weight_mat[i][j] * current_vec[j]);
							inter_small[i][j] = (weight_mat[i][j] * current_vec[j]) >>> 7;
						end

					temp[i] = temp[i] >>> 7;

					if (temp[i] > 63) begin
						z[i] = 63;
					end
					else if (temp[i] < -64) begin
						z[i] = -64;
					end
					// Apply activation function (we use a LUT)
					out_vector[i] = activation_func[z[i]];

				end	//endfor

			end //end if
			
			else if (state == SENDMSG_FORWARD)
			begin
				if (ack == 0)
				begin
					valid <= 1;
				end
				else //ack is true
				begin
					state <= CALC_F_PRIME;
					valid <= 0;
				end
			end
			
			// In this state we calculate f', which will be used in the backpropagation algorithm
			else if (state == CALC_F_PRIME)
			begin

				state <= BACKPROP_WAITING;		
				for (i = 0; i < WIDTH; i = i+1) begin
					f_prime[i] <= activation_func_prime[z[i]];
				end
				
			end

			else if (state == BACKPROP_WAITING)
			begin
					if (backprop == 1)	
						begin
						state <= BACKPROP_CALC;
						end
					current_vec[0] <= in_vector[0];	
					current_vec[1] <= in_vector[1];	
					current_vec[2] <= in_vector[2];	
					current_vec[3] <= in_vector[3];	
					current_vec[4] <= in_vector[4];	
					current_vec[5] <= in_vector[5];	
					current_vec[6] <= in_vector[6];	
					current_vec[7] <= in_vector[7];	
					current_vec[8] <= in_vector[8];	
					
			end

			else if (state == BACKPROP_CALC)
			begin
					if (output_layer == 1)		
					begin	
						//delta_i = -(y_i - a_i)*f'(z_i)
						for (i = 0; i < WIDTH; i = i+1) begin

							// current_vec := correct_value/y
							// out_vector := a_i

							out_vector[i] = ((out_vector[i] - current_vec[i]) * f_prime[i]) >>> 7;

						end //endfor
					end
					else //not an output layer, so the current_vec is the delta vector from the next layer
					begin
						//delta_i = (weighted_sum)*f'(z_i)
						//	  = W^T * delta
						for (i = 0; i < WIDTH; i = i+1) begin
							calc_int = 0;
							for (j=0; j < WIDTH; j = j + 1)
							begin 
								calc_int = calc_int + ((weight_mat[i][j] * current_vec[j]) >>> 7);
							end 

							calc_int = calc_int * f_prime[i] >>> 7;
							
							if (calc_int > 63)
							begin
								calc_int = 63;
							end
							if (calc_int < -64)
							begin
								calc_int = -64;
							end

							out_vector[i] = calc_int[6:0];
						end
					end
				state = UPDATE_WEIGHTS;
			end
	
			else if (state == UPDATE_WEIGHTS)
			begin
				for (i = 0; i < WIDTH; i = i+1) begin
					for (j=0; j < WIDTH; j = j + 1) begin
						// current_vec := delta from
						// next layer
						// temp := input to activation
						// func for node i	
						weight_mat[i][j] = weight_mat[i][j] - LEARNING_RATE * ((activation_func[z[j]] * current_vec[i]) >>> 7);

					end //endfor
				end //endfor

				state <= SENDMSG_BACK;
			end
	
			else if (state == SENDMSG_BACK)
			begin
				//out_vector is currently held at the correct value -- the delta vector		
				
				if (ack == 0)
				begin
					valid <= 1;
				end
				else //ack is true
				begin
					state <= IDLE;
					valid <= 0;
					out_vector[0] <= 0;
					out_vector[1] <= 0;
					out_vector[2] <= 0;
					out_vector[3] <= 0;
					out_vector[4] <= 0;
					out_vector[5] <= 0;
					out_vector[6] <= 0;
					out_vector[7] <= 0;
					out_vector[8] <= 0;
				end			
			end	

		end // end else
	end //END ALWAYS 
endmodule

