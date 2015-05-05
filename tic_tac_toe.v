
`timescale 1ns / 1ps
// add Player, 
module tic_tac_toe (Clk, reset, restart, BtnL, BtnR, BtnU, BtnD, BtnC, 
							P1Won, P2Won, I, PlayerMoved, P1, P2, convert);
//module tic_tac_toe (Clk, reset, u_BtnL, u_BtnR, u_BtnU, u_BtnD, u_BtnC, P1Won, P2Won, I, PlayerMoved);

//inputs
input BtnL, BtnR, BtnU, BtnD, BtnC;
//input u_BtnL, u_BtnR, u_BtnU, u_BtnD, u_BtnC;

reg Player;
input Clk;
input reset, restart;
//input this_state;

//input Player;

output reg [8:0] P1;
output reg [8:0] P2;
output reg [62:0] convert;
//reg [8:0]  P1;
//reg [8:0] P2;
reg [3:0] i;

reg[8:0] board;
reg Draw;
reg game_over;

//outputs
output P1Won, P2Won;
output [3:0] I; 
output PlayerMoved;

//wire BtnL, BtnR, BtU, BtnD, BtnC;

assign I = i; // not sure if this here is right.
//assign PlayerMoved = BtnC && !P1[i] && !P2[i];

assign P1Won = P1[0]&&P1[1]&&P1[2] || P1[2]&&P1[5]&&P1[8] || P1[8]&&P1[7]&&P1[6] || 
										  P1[6]&&P1[3]&&P1[0] || P1[3]&&P1[4]&&P1[5] || P1[1]&&P1[4]&&P1[7] || 
										  P1[0]&&P1[4]&&P1[8] || P1[6]&&P1[4]&&P1[2];
										  
assign P2Won = P2[0]&&P2[1]&&P2[2] || P2[2]&&P2[5]&&P2[8] || P2[8]&&P2[7]&&P2[6] || 
										  P2[6]&&P2[3]&&P2[0] || P2[3]&&P2[4]&&P2[5] || P2[1]&&P2[4]&&P2[7] || 
										  P2[0]&&P2[4]&&P2[8] || P2[6]&&P2[4]&&P2[2];
										  
assign Draw = !P1Won & !P2Won & board == 9'b111111111;

assign game_over = P1Won | P2Won | Draw;

//local variables

reg P_M;
reg [2:0] state;

assign PlayerMoved = P_M;

//constants used for state naming // the don't cares are replaced here with zeros
localparam
 INI        = 3'b001,
 PLAYING    = 3'b010,
 WON	    = 3'b100;

always@(posedge game_over)
begin
	
end

always@(posedge Clk)
begin
	//if(this_state)
		P_M <= BtnC && ~P1[i] && ~P2[i];
	//else P_M <= 0;
	
	//if(PlayerMoved)
		//i <= 8;
end


/*tic_tac_toe_debouncer L_d (.CLK(Clk), .RESET(reset), .PB(u_BtnL), .DPB(), .SCEN(BtnL), .MCEN(), .CCEN());
tic_tac_toe_debouncer R_d (.CLK(Clk), .RESET(reset), .PB(u_BtnR), .DPB(), .SCEN(BtnR), .MCEN(), .CCEN());
tic_tac_toe_debouncer U_d (.CLK(Clk), .RESET(reset), .PB(u_BtnU), .DPB(), .SCEN(BtnU), .MCEN(), .CCEN());
tic_tac_toe_debouncer D_d (.CLK(Clk), .RESET(reset), .PB(u_BtnD), .DPB(), .SCEN(BtnD), .MCEN(), .CCEN());
tic_tac_toe_debouncer C_d (.CLK(Clk), .RESET(reset), .PB(u_BtnC), .DPB(), .SCEN(BtnC), .MCEN(), .CCEN());
*/

reg[4:0] spot;
task convert_board;
begin
	convert = 0;
    for(spot = 0; spot < 9; spot = spot + 1)
	  begin
		if(P1[spot] == 1)
			convert = convert + (7'b1000000 << (spot * 7)); //O
		else if(P2[spot] == 1)
		  convert = convert + (7'b1111111 << (spot * 7)); //X
		else
		  convert = convert + (7'b0000000 << (spot * 7)); //BLANK
	  end
end
endtask
		      
//logic
always @ (posedge Clk, posedge reset)
	begin : State_Machine
		begin
			if (reset || restart)
				begin
					state <= INI;
					i <= 4;
					P1 <= 9'b000000000;
					P2 <= 9'b000000000;
					convert <= 0;
				end
			else //if(this_state)
				begin
					case (state)
					
						INI: begin	
						  Player <= 0;
						  i <= 8;
						  P1 <= 9'b000000000;
						  P2 <= 9'b000000000;
						  state <= PLAYING;
						  convert_board;
						end
							
					 PLAYING: begin	
							case(i)
								0: begin
									if(BtnR==1) i <= 1;
									if(BtnD==1) i <= 3;
								end

								1: begin
									if(BtnR==1) i <= 2;
									if(BtnL==1) i <= 0;
									if(BtnD==1) i <= 4;
								end

								2: begin
									if(BtnL==1) i <= 1;
									if(BtnD==1) i <= 5;
								end

								3: begin
									if(BtnR==1) i <= 4;
									if(BtnU==1) i <= 0;
									if(BtnD==1) i <= 6;
								end

								4: begin
									if(BtnR==1) i <= 5;
									if(BtnU==1) i <= 1;
									if(BtnL==1) i <= 3;
									if(BtnD==1) i <= 7;
								end

								5: begin
									if(BtnD==1) i <= 8;
									if(BtnL==1) i <= 4;
									if(BtnU==1) i <= 2;
								end

								6: begin
									if(BtnR==1) i <= 7;
									if(BtnU==1) i <= 3;
								end

								7: begin
									if(BtnR==1) i <= 8;
									if(BtnU==1) i <= 4;
									if(BtnL==1) i <= 6;
								end

								8: begin
									if(BtnL==1) i <= 7;
									if(BtnU==1) i <= 5;
								end
							endcase
							
							if(BtnC == 1)
							begin	
								if (P1[i] == 0 && P2[i] == 0)
								begin
									//i <= 8; // reset i to 8.
									board[i] <= 1;
									if (Player == 0)
									begin
										P1[i] <= 1;
									end
									else
									begin 
										P2[i] <= 1;
									end
									Player <= ~Player;
								end
							end
							
							if(P1Won || P2Won)
								state <= WON;
								
							convert_board;
						end
					endcase		    
				end
		end
		
		//if(PlayerMoved)
			//i <= 8;
	end // State_Machine

endmodule // tic_tac_toe