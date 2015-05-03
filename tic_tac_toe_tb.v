// test bench for the single tic tac toe game
`timescale 1ns / 1ps

module tic_tac_toe_tb();

reg sysclk;
reg BtnL, BtnR, BtnU, BtnD, BtnC;

//wire Player;
wire P1Won, P2Won, PlayerMoved;
wire [3:0] I;
reg reset;
reg restart;
wire[8:0] P1, P2;
wire[62:0] convert;

tic_tac_toe boardA (.Clk(sysclk), .reset(reset), .restart(restart), .BtnL(BtnL), .BtnR(BtnR), .BtnU(BtnU), .BtnD(BtnD), .BtnC(BtnC), 
			.P1Won(P1WonA), .P2Won(P2WonA), .I(Ia), .PlayerMoved(PM_a), .P1(P1), .P2(P2), .convert(convert) );

initial begin sysclk = 0; end
always begin #10; sysclk = ~ sysclk; end


initial begin
reset = 0;
#50;
reset = 1;
#200;
reset = 0;

BtnD = 0; BtnC = 0; BtnL = 0; BtnR = 0; BtnU = 0;
#50;
BtnC = 1; // 8 player 1
#200;
BtnC = 0;
BtnR = 1;
#200;
BtnR = 0;
#200;
BtnU = 1;
#200;
BtnU = 0;
BtnC = 1; // 2 player 2
#200;
BtnC = 0;
BtnU = 1;
#200;
BtnU = 0;
#200;
BtnC = 1; // 1 player 1 
#200;
BtnC = 0;
BtnR = 1;
#200;
BtnR = 0;
//BtnD = 1;
#200;
//BtnD = 0;
BtnC = 1; // 3 player 2
#200;
BtnC = 0;
//BtnL = 1;
//#200;
//BtnL = 0;
BtnD = 1;
#200;
BtnD = 0;
BtnC = 1; // 5 player 1 
#200;
BtnC = 0;
// player 1 wins!

#400;
//send reset signal
reset = 1;
#200;
reset = 0;


BtnD = 0; BtnC = 0; BtnL = 0; BtnR = 0; BtnU = 0;
#50;
BtnC = 1; // 8 player 1
#200;
BtnC = 0;
#200;
BtnC = 1; // try to go in 8 but hopefully can't
#200;
BtnC = 0;
#200;
BtnR = 1;
#200;
BtnR = 0;
#200;
BtnU = 1;
#200;
BtnU = 0;
BtnC = 1; // 2 player 2
#200;
BtnC = 0;
#200;
BtnU = 1; 
#200;
BtnU = 0;
#200;
BtnL = 1;
#200;
BtnL = 0;
#200;
BtnC = 1; // 0 player 1
#200;
BtnC = 0;
BtnU = 1;
#200;
BtnU = 0;
#200;
BtnC = 1; // 1 player 2 
#200;
BtnC = 0;
BtnR = 1;
#200;
BtnR = 0;
//BtnD = 1;
#200;
//BtnD = 0;
BtnC = 1; // 3 player 1
#200;
BtnC = 0;
//BtnL = 1;
//#200;
//BtnL = 0;
BtnD = 1;
#200;
BtnD = 0;
BtnC = 1; // 5 player 2 
#200;
BtnC = 0;


// player 1 wins!


end

endmodule
