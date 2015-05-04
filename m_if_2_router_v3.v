/********************************************************************************
/This interface is geared  for asymmetrical Router Interface with cascade VC and Input queue equipped by Slave Pe  
//addressing the flow control and parallel version for Master featuring full-duplex operation.
/Version 3.0 featuring independent rx and TX
/
/
/
/
/
/
/
/
/
/
*///////////////////////////////////////////////////////////////////////////////////
module m_if_2_router_v3(
clk,
rst_n,
//general sending interface for master pe and mig_office
//signals between PE and IF
i_comm_send_req,
o_comm_send_ack,
i_data_valid,
i_data,
i_src,
i_dst,
i_seq_len,
i_id,
i_ack_rx,
o_req_rx,
o_data_input,
o_data_input_valid,
//signals Between IF and ROUTER
i_credit,
o_credit_valid,
o_credit,
o_data,
o_data_valid,
i_flit,
//Tag
local_id
);


parameter           VC=2; // 2 BITS
parameter           DST=1; // 5 BITS 
parameter           FLIT=64;
parameter           PAD=73-FLIT-DST-VC-2;
parameter           MSB=FLIT+DST+VC+1;
parameter           SRC_ADD=8'd1;
input 				clk;
input 				rst_n;
// SIGNALS Between IF and PE
input 				i_comm_send_req;
input 				i_data_valid;
input  [31:0]		i_data;
input  [7:0]   		i_src;
input  [7:0]   		i_dst;
input  [5:0]   		i_seq_len;
input  [5:0]   		i_id;
input        		i_ack_rx;
output       		o_req_rx;
output [63:0]		o_data_input;
output              o_data_input_valid;
//
input  [2:0]  		i_credit;
output 				o_credit_valid;
output [2:0]		o_credit;
output [FLIT+DST+VC+1:0] 		o_data;
output 				o_data_valid;
input  [FLIT+DST+VC+1:0] 		i_flit;
input  [7:0]  		local_id;

//handshaking for sending
output 				o_comm_send_ack;

localparam IDLE=5'd0;
localparam RESP=5'd1;
localparam RECV=5'd2;
localparam UPDT=5'd3;
localparam CHEK=5'd4;
localparam VALC=8'd5;
localparam SEND=8'd6;
localparam PROC=8'd7;

localparam VC_0=5'd8;
localparam CR_0=5'd9;
localparam W_0 =5'd10;

localparam VC_1=5'd11;
localparam CR_1=5'd12;
localparam W_1 =5'd13
;
localparam VC_2=5'd14;
localparam CR_2=5'd15;
localparam W_2 =5'd16;

localparam VC_3=5'd17;
localparam CR_3=5'd18;

localparam CTRL_GAP=8'hFF;
localparam CTRL_GAP_CNT=16'd200;
reg [15:0] cnt_ctrl;



reg 			 i_data_valid_r;
reg [31:0] 		 i_data_r;
reg	       		 fifo_flag_0;//indicate whether or not any one of fifos is full with geninfo
reg        		 fifo_flag_1;
wire 			 fifo_0_empty;
wire 			 fifo_1_empty;
reg        		 fifo_rd_en;  
reg  [3:0] credit_cnt[0:3];//credit_cnt
reg  [1:0] vc_allocate;
wire        rd_en_vc;
wire        o_data_vc_valid;

//---------------------SENDING STATE MACHINE------------------------------------
reg [4:0] c_state_tx;
reg [4:0] n_state_tx;
reg [2:0] c_state_rx;
reg [2:0] n_state_rx;

always @(posedge clk, negedge rst_n)  
begin                                 
if(!rst_n)                            
begin                                 
	//n_state_tx<=IDLE;                 
	c_state_tx<=IDLE;                   
	//n_state_rx<=IDLE;                 
	c_state_rx<=IDLE;                   
end                                   
else                                  
begin                                 
	c_state_tx<=n_state_tx;             
	c_state_rx<=n_state_rx;             
end                                   
end                                   
//SENDING STATE   
always @(*)                           
begin                                 
if(!rst_n)                            
n_state_tx=IDLE;    
else begin
	case(c_state_tx)
IDLE:
begin
	if(i_comm_send_req==1'b1)
	n_state_tx=RESP;                  
	else
	n_state_tx=IDLE;
end
RESP:
begin
	if(i_data_valid==1'b1)
	n_state_tx=RECV;
	else 
	n_state_tx=c_state_tx;
end
RECV:
begin
	if(i_data_valid==1'b0 && i_data_valid_r==1'b1)
	n_state_tx=UPDT;
	else
	n_state_tx=c_state_tx;
end
UPDT:
begin
	n_state_tx=CHEK;
end
CHEK:
begin
	if((fifo_flag_0 & fifo_flag_1)==1'b0)// it shows that either one of fifo is available to receive
	n_state_tx=IDLE;
	else
	n_state_tx=c_state_tx;//only if IF has empty fifo available, it would transit to IDLE state or it would wait in CHEK until the sending machine empties any one of fifos
end
default:
n_state_tx=CHEK; 
endcase 	
end

end

//1.i_data_valid_r && i_data_r
always @(posedge clk,negedge rst_n)
begin
if(!rst_n)
i_data_valid_r<=1'b0;
else
i_data_valid_r<=i_data_valid;
end
always @(posedge clk,negedge rst_n)
begin
if(!rst_n)
i_data_r<=32'b0;
else
i_data_r<=i_data;//i_data_r=i_data; //  BOMB!
end
//2.SWITCH LOGIC FOR INPUT
reg  switch_flag_r;
wire switch_flag;
wire wr_valid_0;
wire wr_valid_1;
wire [63:0] wr_data_0;
wire [63:0] wr_data_1;
// top priority is assigned to fifo_0
always @(posedge clk ,negedge rst_n)
begin
if(!rst_n)
switch_flag_r<=1'b0;
else if(c_state_tx==IDLE)
begin
 case({fifo_flag_1,fifo_flag_0})
 2'b00:switch_flag_r<=1'b0;
 2'b01:switch_flag_r<=1'b1;
 2'b10:switch_flag_r<=1'b0;
 default:switch_flag_r<=1'b0;
endcase
end
end
assign switch_flag=switch_flag_r;

assign wr_valid_0=(switch_flag==1'b0 ? i_data_valid_r : 1'b0);
assign wr_valid_1=(switch_flag==1'b1 ? i_data_valid_r : 1'b0);

//3. FIFO_FLAG CONTROL

always @(posedge clk,negedge rst_n)
begin
	if(!rst_n)
	fifo_flag_0<=1'b0;
  else if(c_state_tx==RECV && wr_valid_0==1'b1 && i_data_valid==1'b0 && switch_flag==1'b0) // when one sample is received in fifo_0
  fifo_flag_0<=1'b1;
  else if(fifo_flag_0==1'b1 && fifo_0_empty==1'b1) // when one sample is read out
  fifo_flag_0<=1'b0;
  else
  fifo_flag_0<=fifo_flag_0;
end

always @(posedge clk,negedge rst_n)
begin
	if(!rst_n)
	fifo_flag_1<=1'b0;
  else if(c_state_tx==RECV && wr_valid_1==1'b1 && i_data_valid==1'b0 && switch_flag==1'b1) // when one sample is received in fifo_0
  fifo_flag_1<=1'b1;
  else if(fifo_flag_1==1'b1 && fifo_1_empty==1'b1) // when one sample is read out
  fifo_flag_1<=1'b0;
  else
  fifo_flag_1<=fifo_flag_1;
end

//4.FLIT MOUNTING
wire [2:0] type;
reg  [7:0] src;    
reg  [7:0] dst;
reg  [5:0] id;
wire [3:0] pkt_seq;
wire [8:0] reserved;
wire [31:0] payload;
reg  [3:0] flit_cnt;
reg  [3:0] flit_cnt_r;
wire  [1:0] offset; // last byte is which one ?
assign payload=i_data_r;
assign wr_data_0={type,src,dst,pkt_seq,reserved,payload};
assign wr_data_1={type,src,dst,pkt_seq,reserved,payload};
assign offset=i_seq_len[1:0];
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
flit_cnt<=4'd0;
else if(i_data_valid==1'b1)
flit_cnt<=flit_cnt+1'b1;
else 
flit_cnt<=4'd0;
end
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
flit_cnt_r<=4'd0;
else
flit_cnt_r<=flit_cnt;
end
//4.1TYPE
//decide flit type depending on local id
//local id : 8'd12 for master, 8'd128 for mig_office, rest are slaves
assign type=( local_id==SRC_ADD ? (flit_cnt_r==4'd0 ? 3'b000 : (i_data_valid_r==1'b1 && i_data_valid==1'b0 ? 3'b010 : 3'b001) ) // master 2 slave
			: local_id==8'd128 ? (flit_cnt_r==4'd0 ? 3'b100 : (i_data_valid_r==1'b1 && i_data_valid==1'b0 ? 3'b110 : 3'b101) ) // mig_office 2 mig_office
			: 8'd011	); //Slave 2 master, fitness, single flit
//4.2SRC
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
src<=8'hff;
else if((local_id==SRC_ADD) && (i_data_valid_r==1'b0) && (i_data_valid==1'b1)) // for master 2 slave, src filed of head flit contains seq_len
src<={2'b00,i_seq_len};
//else if(local_id==8'd128 && i_data_valid_r==1'b0 && i_data_valid==1'b1)
//src<=i_seq_len;
//else if((local_id==8'd12 | local_id==8'd128) && flit_cnt==4'd1)
else if(local_id!=SRC_ADD && i_data_valid_r==1'b0 && i_data_valid==1'b1)
src<=i_src;
else if(i_data_valid==1'b1 && i_data_valid_r==1'b1)
src<=i_src;
else
src<=src;
end
//4.3 DST // modified to dst contains len_info
always @(posedge clk,negedge rst_n)
begin
if(!rst_n)
dst<=8'd0;
//else if(local_id==8'd12 && i_data_valid_r==1'b0 && i_data_valid==1'b1)
//dst<=i_seq_len;
//else if(local_id==8'd128 && i_data_valid_r==1'b0 && i_data_valid==1'b1)
//dst<=i_seq_len;
//else if((local_id==8'd12 | local_id==8'd128) && flit_cnt==4'd1)
else if(i_data_valid_r==1'b0 && i_data_valid==1'b1)
dst<=i_dst;
else
dst<=dst;
end
//4.4PKT_SEQ
assign pkt_seq=flit_cnt_r;
//4.5 ID
always @(posedge clk,negedge rst_n)
begin
if(!rst_n)
id<=6'd0;
else if(i_data_valid_r==1'b0 && i_data_valid==1'b1)
id<=i_id;
else
id<=id;
end
assign reserved=( i_data_valid_r==1'b1 && i_data_valid==1'b0 ? {1'b0,offset,id} 
				:     (flit_cnt==1'b1 && local_id==8'd128 ) ? {3'b0,i_seq_len} : {3'b0,id}); // for mig 2 mig, the lower 8 bits in head flit are seq_len

reg    o_comm_send_ack_r;
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
o_comm_send_ack_r<=1'b0;
else if(c_state_tx==IDLE && i_comm_send_req==1'b1)
o_comm_send_ack_r<=1'b1;
else if(c_state_tx==CHEK && (fifo_flag_0 & fifo_flag_1)==1'b0)//
o_comm_send_ack_r<=1'b0;
else
o_comm_send_ack_r<=o_comm_send_ack_r;
end


assign o_comm_send_ack=o_comm_send_ack_r;
	


	
	
	
//------------------------------------------General Interface to Network------------------------------------------------------------
//General VC in-queue and input-queue Design
// VC_FIFO and INPUT_FIFO are set to separate the transfer flits and input flits
// input [72:0] i_flit;
// input [7:0]  local_id;
// input        i_ack_rx;
// output       o_req_rx;
// wire         fifo_input_empty
// --------------Buffer incoming flits and switch them to either vc queue or input queue-----------------
wire [63:0] wr_data_input_fifo;
wire        wr_data_valid_input;
wire 		fifo_input_rd_en;
wire [FLIT+VC+DST+1:0] wr_data_vc_fifo;
wire        wr_data_valid_vc_0;
wire        wr_data_valid_vc_1;
wire        wr_data_valid_vc_2;	
wire        wr_data_valid_vc_3;

wire         fifo_input_empty; // empty signal for input queue
wire 		 fifo_input_full;
wire         fifo_vc_0_empty;
wire         fifo_vc_1_empty;
wire 		 fifo_vc_2_empty;
wire		 fifo_vc_3_empty;
wire [72:0]  o_data_vc;



/*
assign wr_data_valid_input=(i_flit[70:66]==local_id[4:0] ? i_flit[72] : 1'b0);
//VC channel match && Transfer Flit match
assign wr_data_valid_vc_0=(i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b00 ? i_flit[72] : 1'b0);
assign wr_data_valid_vc_1=(i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b01 ? i_flit[72] : 1'b0);
assign wr_data_valid_vc_2=(i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b10 ? i_flit[72] : 1'b0);
assign wr_data_valid_vc_3=(i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b11 ? i_flit[72] : 1'b0);
assign wr_data_vc_fifo=i_flit;
assign wr_data_input_fifo=i_flit[63:0];			
*/
// allow in all the incoming flits to VC channels
assign wr_data_valid_vc_0=(//i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b00 ? i_flit[MSB] : 1'b0);
assign wr_data_valid_vc_1=(//i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b01 ? i_flit[MSB] : 1'b0);
assign wr_data_valid_vc_2=(//i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b10 ? i_flit[MSB] : 1'b0);
assign wr_data_valid_vc_3=(//i_flit[70:66]==local_id[4:0] ? 1'b0 : 
                           i_flit[65:64]==2'b11 ? i_flit[MSB] : 1'b0);
assign wr_data_vc_fifo=i_flit;
assign wr_data_input_fifo=o_data_vc[63:0];
assign wr_data_valid_input=o_data_vc[MSB];//(o_data_vc[FLIT+VC+DST-1:FLIT+VC]==local_id[DST-1:0] ? o_data_vc[MSB] : 1'b0 );
			   
// --------------Feed back the input flits to Process Element-----------------
// REQUEST GENERATE
reg o_req_rx_r;
//reg called;
/*
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
called<=1'b0;
else if(o_req_rx_r==1'b1)
called<=1'b1;
else if(i_ack_rx==1'b1)
called<=1'b0;
else
called<=called;
end
*/

/*
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
o_req_rx_r<=1'b0;
else if (fifo_input_empty!=1'b1 && called==1'b0)
o_req_rx_r<=1'b1;
else if(i_ack_rx==1'b1 && called==1'b1)
o_req_rx_r<=1'b1;
else if(called==1'b1 | fifo_input_empty==1'b1)
o_req_rx_r<=1'b0;
else
o_req_rx_r<=o_req_rx_r;
end
*/
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
o_req_rx_r<=1'b0;
else if (fifo_input_empty!=1'b1 && i_ack_rx==1'b0)
o_req_rx_r<=1'b1;
else if(i_ack_rx==1'b1)
o_req_rx_r<=1'b0;
else if(fifo_input_empty==1'b1)
o_req_rx_r<=1'b0;
else
o_req_rx_r<=o_req_rx_r;
end

assign o_req_rx= o_req_rx_r;
// FIFO_INPUT_READ_ENABLE
assign fifo_input_rd_en=i_ack_rx;
// O_DATA_INPUT_VALID
reg o_data_input_valid_r;
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
o_data_input_valid_r<=1'b0;
else
o_data_input_valid_r<=i_ack_rx;
end
assign o_data_input_valid=o_data_input_valid_r;


//------------------------------------------General Interface to Network------------------------------------------------------------
//General VC output queue and output-queue Design

//---------------------SENDING STATE MACHINE ROUTER SIDE------------------------------------
//data sending state transfer
reg [4:0] c_state_tx_d;
reg [4:0] n_state_tx_d;
reg [4:0] c_state_tx_d_2;
reg [4:0] n_state_tx_d_2;
always @(posedge clk, negedge rst_n)  
begin                                 
if(!rst_n)                            
begin                                                
	c_state_tx_d_2<=IDLE;                                     
end                                   
else                                  
begin                                 
	c_state_tx_d_2<=n_state_tx_d_2;                      
end                                   
end   
always @(*)                           
begin                                 
if(!rst_n)                            
n_state_tx_d_2=IDLE;    
else begin
	case(c_state_tx_d_2)
IDLE:begin
	if(fifo_flag_0==1'b1 | fifo_flag_1==1'b1)
	n_state_tx_d_2=VALC;
	else
	n_state_tx_d_2=c_state_tx_d_2;
	end


VALC:begin
	if(credit_cnt[0]<=4'd2 && credit_cnt[1]<=4'd2 && credit_cnt[2]<=4'd2 && credit_cnt[3]<=4'd2) // no vc is available
	n_state_tx_d_2=IDLE;
	else
	n_state_tx_d_2=SEND;
end
	
SEND:begin
	if(fifo_flag_0==1'b1 && switch_flag==1'b1)//reading the first fifo
	begin
		if(fifo_0_empty==1'b1)
		n_state_tx_d_2=IDLE;//CTRL_GAP;
		else
		n_state_tx_d_2=c_state_tx_d_2;
	end
	else if(fifo_flag_1==1'b1 && switch_flag==1'b0)
		begin
			if(fifo_1_empty==1'b1)
			n_state_tx_d_2=IDLE;//CTRL_GAP;
			else
			
			n_state_tx_d_2=c_state_tx_d_2;
		end
end

CTRL_GAP:
begin
if(cnt_ctrl==CTRL_GAP_CNT)
n_state_tx_d_2=IDLE;
else
n_state_tx_d_2=c_state_tx_d_2;
end
default:n_state_tx_d_2=IDLE;
endcase
end
end


always @(posedge clk, negedge rst_n)  
begin                                 
if(!rst_n)                            
begin                                                
	c_state_tx_d<=IDLE;                                     
end                                   
else                                  
begin                                 
	c_state_tx_d<=n_state_tx_d;                      
end                                   
end   
always @(*)                           
begin                                 
if(!rst_n)                            
n_state_tx_d=IDLE;    
else begin
	case(c_state_tx_d)
IDLE:begin
	//if(fifo_flag_0==1'b1 | fifo_flag_1==1'b1)
	//n_state_tx_d=VALC;
//	else
	//if(fifo_flag_0==1'b0 && fifo_flag_1==1'b0 && (fifo_vc_0_empty==1'b0 | fifo_vc_1_empty==1'b0 | fifo_vc_2_empty==1'b0 | fifo_vc_3_empty==1'b0) && fifo_input_full!=1'b1) // when no master output task is pending
	if( (fifo_vc_0_empty==1'b0 | fifo_vc_1_empty==1'b0 | fifo_vc_2_empty==1'b0 | fifo_vc_3_empty==1'b0) && fifo_input_full!=1'b1) // when no master output task is pending
	n_state_tx_d=PROC;
	else 
	n_state_tx_d=c_state_tx_d;
end



PROC:begin
	if(fifo_vc_0_empty==1'b0 && credit_cnt[0]!=4'd0 && fifo_input_full!=1'b1) // vc_0 has something to transfer and 
	n_state_tx_d=VC_0;
	else if(fifo_vc_1_empty==1'b0 && credit_cnt[1]!=4'd0 && fifo_input_full!=1'b1)
	n_state_tx_d=VC_1;
	else if(fifo_vc_2_empty==1'b0 && credit_cnt[2]!=4'd0 && fifo_input_full!=1'b1)
	n_state_tx_d=VC_2;
	else if(fifo_vc_3_empty==1'b0 && credit_cnt[3]!=4'd0 && fifo_input_full!=1'b1)
	n_state_tx_d=VC_3;
	else
	n_state_tx_d=IDLE;
end
// time-multiplexed cycle by cycle
VC_0:begin
n_state_tx_d=CR_0;
end
CR_0:
n_state_tx_d=W_0;
W_0:
begin
	if(fifo_input_full==1'b1)
	n_state_tx_d=c_state_tx_d;
	
	else if(fifo_vc_1_empty==1'b0 && credit_cnt[1]!=4'd0 )
	n_state_tx_d=VC_1;
	else if(fifo_vc_2_empty==1'b0 && credit_cnt[2]!=4'd0 )
	n_state_tx_d=VC_2;
	else if(fifo_vc_3_empty==1'b0 && credit_cnt[3]!=4'd0 )
	n_state_tx_d=VC_3;
	else 
	n_state_tx_d=IDLE;
end

VC_1:begin
n_state_tx_d=CR_1;
end
CR_1:
n_state_tx_d=W_1;
W_1:
	begin
	if(fifo_input_full==1'b1)
	n_state_tx_d=c_state_tx_d;
	else if(fifo_vc_2_empty==1'b0 && credit_cnt[2]!=4'd0 )
	n_state_tx_d=VC_2;
	else if(fifo_vc_3_empty==1'b0 && credit_cnt[3]!=4'd0 )
	n_state_tx_d=VC_3;
	else
	n_state_tx_d=IDLE;
end

VC_2:begin
n_state_tx_d=CR_2;
end
CR_2:
n_state_tx_d=W_2;
W_2:
begin
    if(fifo_input_full==1'b1)
	n_state_tx_d=c_state_tx_d;
	else if(fifo_vc_3_empty==1'b0 && credit_cnt[3]!=4'd0)
	n_state_tx_d=VC_3;
	else
	n_state_tx_d=IDLE;
end

VC_3:begin
n_state_tx_d=CR_3;
end
CR_3:begin
	n_state_tx_d=IDLE;
end

default:n_state_tx_d=IDLE;
endcase
end
end


//-----------------------------FLOW CTRL-------------------------------------------------
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
cnt_ctrl<=16'd0;
else if(c_state_tx_d_2==CTRL_GAP)
cnt_ctrl<=cnt_ctrl+1'b1;
else
cnt_ctrl<=16'd0;
end

//-----------------------------VC ALLOCATION --------------------------------------------
//1.FLOW CONTROL 

//1.1 credit_cnt;
//reg [3:0] credit_cnt[0:3];//credit_cnt
/*                   
always @(posedge clk,negedge rst_n)
begin
if(!rst_n)
	begin
	credit_cnt[0]<=4'd8;
	credit_cnt[1]<=4'd8;
	credit_cnt[2]<=4'd8;
	credit_cnt[3]<=4'd8;
	end
else if(i_credit[2]==1'b1 && fifo_rd_en==1'b1 && (vc_allocate==i_credit[1:0]))// master out 
	credit_cnt[vc_allocate]<=credit_cnt[vc_allocate];
else if(i_credit[2]==1'b1 && rd_en_vc==1'b1 && (o_data_vc[65:64]==i_credit[1:0]) && o_data_vc_valid==1'b1)
	credit_cnt[vc_allocate]<=credit_cnt[vc_allocate];
		
else if(i_credit[2]==1'b1)
	begin
		case(i_credit[1:0])
		2'b00:credit_cnt[0]<=credit_cnt[0]+1'b1;
		2'b01:credit_cnt[1]<=credit_cnt[1]+1'b1;
		2'b10:credit_cnt[2]<=credit_cnt[2]+1'b1;
		2'b11:credit_cnt[3]<=credit_cnt[3]+1'b1;
		endcase
	end
else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1))
	begin
		case(vc_allocate)
		2'd0:credit_cnt[0]<=credit_cnt[0]-1'b1;
		2'd1:credit_cnt[1]<=credit_cnt[1]-1'b1; 
		2'd2:credit_cnt[2]<=credit_cnt[2]-1'b1; 
		2'd3:credit_cnt[3]<=credit_cnt[3]-1'b1; 
		endcase
	end
else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1))
	begin
		case(vc_allocate)
		2'd0:credit_cnt[0]<=credit_cnt[0]-1'b1;
		2'd1:credit_cnt[1]<=credit_cnt[1]-1'b1; 
		2'd2:credit_cnt[2]<=credit_cnt[2]-1'b1; 
		2'd3:credit_cnt[3]<=credit_cnt[3]-1'b1; 
		endcase
	end
	
	
else if((c_state_tx_d==CR_0 | c_state_tx_d==CR_1 | c_state_tx_d==CR_2 | c_state_tx_d==CR_3) && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
begin
	case(c_state_tx_d)
	8'd9 : credit_cnt[0]<=credit_cnt[0]-1'b1;
	8'd11 :credit_cnt[1]<=credit_cnt[1]-1'b1;
	8'd13 :credit_cnt[2]<=credit_cnt[2]-1'b1;
	8'd15 :credit_cnt[3]<=credit_cnt[3]-1'b1;
	default:
	begin
	credit_cnt[0]<=credit_cnt[0];
	credit_cnt[1]<=credit_cnt[1];
	credit_cnt[2]<=credit_cnt[2];
	credit_cnt[3]<=credit_cnt[3];
	end
	endcase
	end
else 
	begin
	credit_cnt[0]<=credit_cnt[0];
	credit_cnt[1]<=credit_cnt[1];
	credit_cnt[2]<=credit_cnt[2];
	credit_cnt[3]<=credit_cnt[3];
	end	
	
end
*/
wire  credit_0;
assign credit_0=(i_credit[2:0]==3'b100);

always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
credit_cnt[0]<=4'd8;
else if((i_credit[2]==1'b0) | credit_0==1'b0)//(i_credit[2]==1'b1 && i_credit[1:0]!=2'd0)) // no link to it 
begin
	if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd0)) // master output
	credit_cnt[0]<=credit_cnt[0]-1'b1;
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd0) ) // master output
	credit_cnt[0]<=credit_cnt[0]-1'b1;
	//else if(c_state_tx_d==CR_0 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[0]<=credit_cnt[0]-1'b1;
	else	
	credit_cnt[0]<=credit_cnt[0];
end
else if( credit_0==1'b1)//i_credit[2]==1'b1 && (i_credit[1:0]==2'd0)) // my credit
begin
	if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd0)) // master output
	credit_cnt[0]<=credit_cnt[0];
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd0)) // master output
	credit_cnt[0]<=credit_cnt[0];
	//else if(c_state_tx_d==CR_0 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[0]<=credit_cnt[0];
	else
	credit_cnt[0]<=credit_cnt[0]+1'b1;
end
else
credit_cnt[0]<=credit_cnt[0];
end


always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
credit_cnt[1]<=4'd8;
else if((i_credit[2]==1'b0) | (i_credit[2]==1'b1 && i_credit[1:0]!=2'd1)) // no link to it 
begin
	if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd1)) // master output
	credit_cnt[1]<=credit_cnt[1]-1'b1;
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd1) ) // master output
	credit_cnt[1]<=credit_cnt[1]-1'b1;
	//else if(c_state_tx_d==CR_1 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[1]<=credit_cnt[1]-1'b1;
	else	
	credit_cnt[1]<=credit_cnt[1];
end
else if( i_credit[2]==1'b1 && (i_credit[1:0]==2'd1)) // my credit
begin
if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd1)) // master output
	credit_cnt[1]<=credit_cnt[1];
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd1)) // master output
	credit_cnt[1]<=credit_cnt[1];
	//else if(c_state_tx_d==CR_1 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[1]<=credit_cnt[1];
	else
	credit_cnt[1]<=credit_cnt[1]+1'b1;
end
else
credit_cnt[1]<=credit_cnt[1];
end

always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
credit_cnt[2]<=4'd8;
else if((i_credit[2]==1'b0) | (i_credit[2]==1'b1 && i_credit[1:0]!=2'd2)) // no link to it 
begin
	if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd2)) // master output
	credit_cnt[2]<=credit_cnt[2]-1'b1;
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd2) ) // master output
	credit_cnt[2]<=credit_cnt[2]-1'b1;
	//else if(c_state_tx_d==CR_2 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[2]<=credit_cnt[2]-1'b1;
	else	
	credit_cnt[2]<=credit_cnt[2];
end
else if( i_credit[2]==1'b1 && (i_credit[1:0]==2'd2)) // my credit
begin
if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd2)) // master output
	credit_cnt[2]<=credit_cnt[2];
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd2)) // master output
	credit_cnt[2]<=credit_cnt[2];
	//else if(c_state_tx_d==CR_2 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[2]<=credit_cnt[2];
	else
	credit_cnt[2]<=credit_cnt[2]+1'b1;
end
else
credit_cnt[2]<=credit_cnt[2];
end

always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
credit_cnt[3]<=4'd8;
else if((i_credit[2]==1'b0) | (i_credit[2]==1'b1 && i_credit[1:0]!=2'd3)) // no link to it 
begin
	if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd3)) // master output
	credit_cnt[3]<=credit_cnt[3]-1'b1;
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd3) ) // master output
	credit_cnt[3]<=credit_cnt[3]-1'b1;
	//else if(c_state_tx_d==CR_3 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[3]<=credit_cnt[3]-1'b1;
	else	
	credit_cnt[3]<=credit_cnt[3];
end
else if( i_credit[2]==1'b1 && (i_credit[1:0]==2'd3)) // my credit
begin
if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b1 && fifo_0_empty !=1'b1) && (vc_allocate==2'd3)) // master output
	credit_cnt[3]<=credit_cnt[3];
	else if(c_state_tx_d_2==SEND &&  fifo_rd_en==1'b1 && (switch_flag==1'b0 && fifo_1_empty !=1'b1) && (vc_allocate==2'd3)) // master output
	credit_cnt[3]<=credit_cnt[3];
	//else if(c_state_tx_d==CR_3 && (o_data_vc[FLIT+VC+DST-1:FLIT+VC]!=local_id[DST-1:0]))
	//credit_cnt[3]<=credit_cnt[3];
	else
	credit_cnt[3]<=credit_cnt[3]+1'b1;
end
else
credit_cnt[3]<=credit_cnt[3];
end

//2. find the vc with max credits
wire [1:0] max_credit_vc;
wire [3:0] cmp_01;
wire [3:0] cmp_23;
wire [3:0] max_03;
//reg  [1:0] vc_allocate;

assign cmp_01=(credit_cnt[0] >= credit_cnt[1] ? credit_cnt[0] : credit_cnt[1]);
assign cmp_23=(credit_cnt[2] >= credit_cnt[3] ? credit_cnt[2] : credit_cnt[3]);
assign max_03=(cmp_01 >= cmp_23 ? cmp_01 : cmp_23);
assign max_credit_vc=( max_03== credit_cnt[0] ? 2'd0 :
                       max_03== credit_cnt[1] ? 2'd1 :
                       max_03== credit_cnt[2] ? 2'd2 : 2'd3);
    
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
vc_allocate<=2'd0;
else if(c_state_tx_d_2==VALC)
vc_allocate<=max_credit_vc;//pick the vc with highest credits
else
vc_allocate<=vc_allocate;                 
end
//-----------------------------OUTPUT QUEUE DATA ASSEMBLY --------------------------------------------

//1. rd_en // should be switched to fifo_0 or fifo_1 depending on the switch_flag;
reg fifo_rd_en_r;
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
fifo_rd_en<=1'b0;
else 
begin
if(switch_flag==1'b1) // fifo_1 is chosen as write-buffer,that means the fifo_0 is being read out
	begin
	if(fifo_0_empty!=1'b1 && credit_cnt[vc_allocate]>=4'd2 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b1;
	else if(fifo_0_empty!=1'b1 && credit_cnt[vc_allocate]==4'd1 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else if(fifo_0_empty==1'b1 && credit_cnt[vc_allocate]>=4'd2 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else if(fifo_0_empty==1'b1 && credit_cnt[vc_allocate]==4'd1 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else
	fifo_rd_en<=fifo_rd_en;
	end
else if(switch_flag==1'b0)
	begin
	if(fifo_1_empty!=1'b1 && credit_cnt[vc_allocate]>=4'd2 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b1;
	else if(fifo_1_empty!=1'b1 && credit_cnt[vc_allocate]==4'd1 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else if(fifo_1_empty==1'b1 && credit_cnt[vc_allocate]>=4'd2 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else if(fifo_1_empty==1'b1 && credit_cnt[vc_allocate]==4'd1 && c_state_tx_d_2==SEND)
	fifo_rd_en<=1'b0;
	else
	fifo_rd_en<=fifo_rd_en;
	end
	end
end
always @(posedge clk, negedge rst_n)
begin
if(!rst_n)
fifo_rd_en_r<=1'b0;
else 
fifo_rd_en_r<=fifo_rd_en;
end
//2. Define the rd part fifo signals
wire [63:0] rd_fifo_data_0;
wire [63:0] rd_fifo_data_1;
wire        rd_fifo_en_0;
wire        rd_fifo_en_1;
//3. o_data_fifo // not the o_data_vc
wire [FLIT+VC+DST+1:0] o_data_fifo;
wire        o_data_fifo_valid;
wire 		valid_bit_fifo;
wire 		is_tail_fifo;
wire [DST-1:0]	dst_fifo;
wire [1:0]  vc_fifo;
wire [63:0] rd_fifo_data;
//4.output queue data, need to be multiplexed with VC queue
assign rd_fifo_data		=(switch_flag==1'b1 ? rd_fifo_data_0 : rd_fifo_data_1);
assign rd_fifo_en_0		=(switch_flag==1'b1 ? fifo_rd_en : 1'b0);
assign rd_fifo_en_1		=(switch_flag==1'b0 ? fifo_rd_en : 1'b0);
assign valid_bit_fifo	=fifo_rd_en_r;
assign is_tail_fifo		=(c_state_tx_d_2==SEND ? switch_flag==1'b1 ? fifo_0_empty : fifo_1_empty : 1'b0);
assign dst_fifo			=rd_fifo_data[45+DST-1:45];//lower 5 bits of dst field in 5*5 mesh
assign vc_fifo			=vc_allocate;
assign o_data_fifo		={valid_bit_fifo,is_tail_fifo,dst_fifo,vc_fifo,rd_fifo_data};
assign o_data_fifo_valid=valid_bit_fifo;
//-----------------------------VC QUEUE DATA ASSEMBLY --------------------------------------------
//1.VC FIFO SIGNALS, data part
//wire [72:0] o_data_vc;//directly connected to fifo port
wire [72:0] o_data_vc_0;
wire [72:0] o_data_vc_1;
wire [72:0] o_data_vc_2;
wire [72:0] o_data_vc_3;
/*
assign      o_data_vc	   =(c_state_tx_d==CR_0 ? o_data_vc_0 : 
							 c_state_tx_d==CR_1 ? o_data_vc_1 :
							 c_state_tx_d==CR_2 ? o_data_vc_2 :
							 c_state_tx_d==CR_3 ? o_data_vc_3 : 73'd0);
							 */
assign      o_data_vc	   =(c_state_tx_d==CR_0 ? o_data_vc_0[FLIT+DST+VC+1:0] : 
							 c_state_tx_d==CR_1 ? o_data_vc_1[FLIT+DST+VC+1:0] :
							 c_state_tx_d==CR_2 ? o_data_vc_2[FLIT+DST+VC+1:0] :
							 c_state_tx_d==CR_3 ? o_data_vc_3[FLIT+DST+VC+1:0] : 73'd0);
							 
							 
//2. RD_EN 
wire        rd_en_vc_0;
wire        rd_en_vc_1;
wire        rd_en_vc_2;
wire        rd_en_vc_3;
//wire        rd_en_vc;
assign      rd_en_vc_0	   =(c_state_tx_d==VC_0 ? 1'b1 : 1'b0);
assign      rd_en_vc_1	   =(c_state_tx_d==VC_1 ? 1'b1 : 1'b0);
assign      rd_en_vc_2	   =(c_state_tx_d==VC_2 ? 1'b1 : 1'b0);
assign      rd_en_vc_3	   =(c_state_tx_d==VC_3 ? 1'b1 : 1'b0);
assign      rd_en_vc       = (rd_en_vc_0 | rd_en_vc_1 | rd_en_vc_2 | rd_en_vc_3) ;

//3. O_DATA_VALID
//wire        o_data_vc_valid;
/*
wire        o_data_vc_valid;
assign      o_data_vc_valid=(c_state_tx_d==CR_0 ? 1'b1 : 
							 c_state_tx_d==CR_1 ? 1'b1 :
							 c_state_tx_d==CR_2 ? 1'b1 :
							 c_state_tx_d==CR_3 ? 1'b1 : 1'b0);
*/
wire        o_data_vc_valid_temp;
assign      o_data_vc_valid_temp=(c_state_tx_d==CR_0 ? 1'b1 : 
							 c_state_tx_d==CR_1 ? 1'b1 :
							 c_state_tx_d==CR_2 ? 1'b1 :
							 c_state_tx_d==CR_3 ? 1'b1 : 1'b0);
// the local flits also flow into vc channel then transfered to input queue. if it is local flits, supposedly not output,or output them
assign      o_data_vc_valid=1'b0;//(o_data_vc[FLIT+VC+DST-1:FLIT+VC]==local_id[DST-1:0] ? 1'b0 : o_data_vc_valid_temp); 

//4.O_CREDIT_VALID	&& O_CREDIT						 
assign      o_credit_valid = o_data_vc_valid_temp;
assign      o_credit=		(c_state_tx_d==CR_0 ? {1'b1,2'b00} : 
							 c_state_tx_d==CR_1 ? {1'b1,2'b01} :
							 c_state_tx_d==CR_2 ? {1'b1,2'b10} :
							 c_state_tx_d==CR_3 ? {1'b1,2'b11} : {1'b0,2'b00});
//5.O_DATA && O_DATA_VALID							 
assign 		o_data		   =(c_state_tx_d_2==SEND ? o_data_fifo  : {(MSB+1){1'b0}});
assign      o_data_valid   =(c_state_tx_d_2==SEND ? o_data_fifo_valid : 1'b0);

/*FIFO SIGNALS COLLECTION
FIFO PARAMETER
VC FIFO		: NUM: 4 WIDTH:73 DEPTH:8   2Kb BLK
OUTPUT FIFO : NUM: 2 WIDTH:64 DEPTH:16  2Kb BLK for master  4 for slave
INPUT  FIFO : NUM: 1 WIDTH:64 DEPTH:32/64  2Kb/4kb BLK for slave   4 for master


---VC FIFO Write Part
wire        wr_data_vc_fifo; //shared  data in 
wire        wr_data_valid_vc_0;
wire        wr_data_valid_vc_1;
wire        wr_data_valid_vc_2;	
wire        wr_data_valid_vc_3;
---VC FIFO Read Part
wire        rd_en_vc_0;
wire        rd_en_vc_1;
wire        rd_en_vc_2;
wire        rd_en_vc_3;
wire [72:0] o_data_vc_0;
wire [72:0] o_data_vc_1;
wire [72:0] o_data_vc_2;
wire [72:0] o_data_vc_3;
--- VC FIFO FLAG
wire         fifo_vc_0_empty;
wire         fifo_vc_1_empty;
wire 		 fifo_vc_2_empty;
wire		 fifo_vc_3_empty;

---INPUT QUEUE FIFO Write Part
wire [63:0] wr_data_input_fifo;
wire        wr_data_valid_input;
---INPUT QUEUE FIFO Read Part
wire 		fifo_input_rd_en;
output 		o_data_input;
---INPUT QUEUE FIFO FLAG
wire         fifo_input_empty; // empty signal for input queue

---OUTPUT QUEUE FIFO  Write Part

wire wr_valid_0;
wire wr_valid_1;
wire [63:0] wr_data_0;
wire [63:0] wr_data_1;
---OUTPUT QUEUE FIFO  Read Part
wire [63:0] rd_fifo_data_0;
wire [64:0] rd_fifo_data_1;
wire        rd_fifo_en_0;
wire        rd_fifo_en_1;
---OUTPUT QUEUE FIFO  FLAG
wire 			 fifo_0_empty;
wire 			 fifo_1_empty;



*/

vc_fifo u_vc_0(
	.clk(clk),
	.rst(~rst_n),
	.din({{PAD{1'b0}},wr_data_vc_fifo}),
	.wr_en(wr_data_valid_vc_0),
	.rd_en(rd_en_vc_0),
	.dout(o_data_vc_0),
	.full(),
	.empty(fifo_vc_0_empty));
	
vc_fifo u_vc_1(
	.clk(clk),
	.rst(~rst_n),
	.din({{PAD{1'b0}},wr_data_vc_fifo}),
	.wr_en(wr_data_valid_vc_1),
	.rd_en(rd_en_vc_1),
	.dout(o_data_vc_1),
	.full(),
	.empty(fifo_vc_1_empty));
	
vc_fifo u_vc_2(
	.clk(clk),
	.rst(~rst_n),
	.din({{PAD{1'b0}},wr_data_vc_fifo}),
	.wr_en(wr_data_valid_vc_2),
	.rd_en(rd_en_vc_2),
	.dout(o_data_vc_2),
	.full(),
	.empty(fifo_vc_2_empty));

vc_fifo u_vc_3(
	.clk(clk),
	.rst(!rst_n),
	.din({{PAD{1'b0}},wr_data_vc_fifo}),
	.wr_en(wr_data_valid_vc_3),
	.rd_en(rd_en_vc_3),
	.dout(o_data_vc_3),
	.full(),
	.empty(fifo_vc_3_empty));

/*
vc_fifo u_vc_0(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_vc_fifo),
	.wr_en(wr_data_valid_vc_0),
	.rd_en(rd_en_vc_0),
	.dout(o_data_vc_0),
	.full(),
	.empty(fifo_vc_0_empty));
	
vc_fifo u_vc_1(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_vc_fifo),
	.wr_en(wr_data_valid_vc_1),
	.rd_en(rd_en_vc_1),
	.dout(o_data_vc_1),
	.full(),
	.empty(fifo_vc_1_empty));
	
vc_fifo u_vc_2(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_vc_fifo),
	.wr_en(wr_data_valid_vc_2),
	.rd_en(rd_en_vc_2),
	.dout(o_data_vc_2),
	.full(),
	.empty(fifo_vc_2_empty));

vc_fifo u_vc_3(
	.clk(clk),
	.rst(!rst_n),
	.din(wr_data_vc_fifo),
	.wr_en(wr_data_valid_vc_3),
	.rd_en(rd_en_vc_3),
	.dout(o_data_vc_3),
	.full(),
	.empty(fifo_vc_3_empty));
*/
input_queue_fifo u_in(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_input_fifo),
	.wr_en(wr_data_valid_input),
	.rd_en(fifo_input_rd_en),
	.dout(o_data_input),
	.full(fifo_input_full),
	.empty(fifo_input_empty)
	);

output_queue_fifo u_out_0(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_0),
	.wr_en(wr_valid_0),
	.rd_en(rd_fifo_en_0),
	.dout(rd_fifo_data_0),
	.full(),
	.empty(fifo_0_empty));
	
output_queue_fifo u_out_1(
	.clk(clk),
	.rst(~rst_n),
	.din(wr_data_1),
	.wr_en(wr_valid_1),
	.rd_en(rd_fifo_en_1),
	.dout(rd_fifo_data_1),
	.full(),
	.empty(fifo_1_empty));



endmodule
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	