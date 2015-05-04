`include "connect_parameters.v"

module layer(Clk, reset, recv_flit, flit_in, dest, send_flit, flit_out);

// Local constants
localparam dest_bits = $clog2(`NUM_USER_RECV_PORTS);
localparam flit_port_width = 2 /*valid and tail bits*/+ `FLIT_DATA_WIDTH + dest_bits + 2;

// I/O
input Clk, reset;
input [dest_bits-1:0] dest;
input [flit_port_width-1:0] flit_in;

output recv_flit, send_flit;
output [flit_port_width-1:0] flit_out;

reg recv_flit;

wire is_valid_in, is_valid_out;
wire [`FLIT_DATA_WIDTH-2:0] data_in;
wire [`FLIT_DATA_WIDTH-2:0] data_out;

// Internal state
reg ack;

wire msb_flit_out;

// Assigns
assign is_valid_in = flit_in[flit_port_width-1];
assign data_in = flit_in[`FLIT_DATA_WIDTH-2:0];
assign flit_out = {is_valid_out /* send valid flit */, 1'b1 /* always tail */, dest, 2'b00 /* No VC? */, 1'b1, data_out};
assign send_flit = is_valid_out;

assign msb_flit_out = flit_out[63];

// Modules
MatMul_Module mult(Clk, data_in, is_valid_in, ack, is_valid_out, data_out, reset);

// Clocked
always @(posedge Clk)
begin
	if (reset)
	begin
		recv_flit <= 1;
		ack <= 0;
	end
	else
	begin
		// Acknowledge we finished.
		ack <= is_valid_out;
	end
end

endmodule
