module MatMul_Module(clk, packed_7_9_in, mult, ack, valid, packed_7_9_out, reset);
    
	parameter IDLE=0, MULT=1, SENDMSG=2, WIDTH = 9, MAX_NUM=255, PK_WIDTH=7, PK_LEN=9;
	input clk, reset, mult;
	input ack;
   	input [62:0] packed_7_9_in; //7x9

	output [62:0] packed_7_9_out;	
	output reg valid;

	
	//Internal in/out vectors (unpacked)
	wire [6:0] in_vector [8:0];
	reg [6:0] out_vector [8:0];

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

	reg [1:0] state;

	//Vector is 7bits x input_size
	reg [6:0] current_vec [8:0];
	reg [6:0] weight_mat [8:0][8:0];
	reg [15:0] temp;
	integer x,y;

	always @(posedge clk)
	begin
		if (reset)
		begin
			state <= IDLE;	
			//initialize output vectors to 0	
			valid <= 0;
			for (x = 0; x < 9; x = x + 1)
			begin
				for (y=0; y < 9; y = y + 1)
				begin
				if (x==y)
				weight_mat[x][y] = 7'b0000001;
				else
				weight_mat[x][y] = 7'b0000000;
				end
			end	
		end
		else
		begin
			if (state == IDLE)
			begin
				if (mult)
				begin
					state <= MULT;
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
			if (state == SENDMSG)
			begin
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
	
		end
	end

	reg [4:0] i;	
  	//do matrix multiply	
	always @(posedge clk)
	begin
		if (state == MULT)
			begin
			state <= SENDMSG;
			//this was pulled from stackoverflow
			for (i = 0; i < WIDTH; i = i+1) begin:gen
				//STATIC
				//temp = current_vec[0] * weight_mat[0][i];
				//temp = temp + current_vec[1]*weight_mat[1][i];
				//temp = temp + current_vec[2]*weight_mat[2][i];
				//temp = temp + current_vec[3]*weight_mat[3][i];
				//temp = temp + current_vec[4]*weight_mat[4][i];
				//temp = temp + current_vec[5]*weight_mat[5][i];
				//temp = temp + current_vec[6]*weight_mat[6][i];
				//temp = temp + current_vec[7]*weight_mat[7][i];
				//temp = temp + current_vec[8]*weight_mat[8][i];

				out_vector[i] <= current_vec[0]*weight_mat[i][0] + current_vec[1]*weight_mat[i][1] + current_vec[3]*weight_mat[i][3] + current_vec[4]*weight_mat[i][4] + current_vec[5]*weight_mat[i][5] + current_vec[6]*weight_mat[i][6] + current_vec[6]*weight_mat[i][6] + current_vec[6]*weight_mat[i][6] + current_vec[7]*weight_mat[i][7]; 

				// Clamp the values to 255 max
				//out_vector[i] = (temp > 255) ? 255 : temp ;

			end	
			end
		
		end

			
endmodule
