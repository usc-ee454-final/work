`include "connect_parameters.v"

module layer(Clk, reset, cycle, recv_flit, flit_in, dest_forward, dest_backward, send_flit, flit_out);

// Local constants
localparam dest_bits = $clog2(`NUM_USER_RECV_PORTS);
localparam flit_port_width = 2 /*valid and tail bits*/+ `FLIT_DATA_WIDTH + dest_bits + 2;

// I/O
input Clk, reset;
input [31:0] cycle;
input [dest_bits-1:0] dest_forward;
input [dest_bits-1:0] dest_backward;
input [flit_port_width-1:0] flit_in;

output recv_flit, send_flit;
output [flit_port_width-1:0] flit_out;

reg recv_flit;

wire is_valid_in, is_valid_out, backprop_in;
wire [`FLIT_DATA_WIDTH-2:0] data_in;
wire [`FLIT_DATA_WIDTH-2:0] data_out;

// Internal state
reg ack, backprop_buf;

wire msb_flit_out;

wire [dest_bits-1:0] dest;

// Assigns
assign is_valid_in = flit_in[flit_port_width-1];
assign backprop_in = flit_in[`FLIT_DATA_WIDTH-1];
assign data_in = flit_in[`FLIT_DATA_WIDTH-2:0];
assign dest = backprop_buf ? dest_backward : dest_forward;
assign flit_out = {is_valid_out && ~ack/* send valid flit */, 1'b1 /* always tail */, dest, 2'b00 /* No VC? */, backprop_buf, data_out};
assign send_flit = is_valid_out;

assign msb_flit_out = flit_out[63];

// Modules
MatMul_Module mult(
   .clk(Clk)
  ,.packed_7_9_in(data_in)
  ,.mult(is_valid_in && ~backprop_in)
  ,.backprop(is_valid_in && backprop_in)
  ,.ack(ack)
  ,.valid(is_valid_out)
  ,.packed_7_9_out(data_out)
  ,.reset(reset)
  ,.output_layer(1'b0)
  );

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
    if (is_valid_in)
      $display("@%3d: data in: %x", cycle, data_in);
    if (is_valid_out && ~ack)
      $display("@%3d: data out: %x", cycle, data_out);

    // Check for start condition
    if (is_valid_in)
      backprop_buf = backprop_in;

    // Check for ending condition
    if (is_valid_out && ~ack)
      $display("@%3d: Sending flit %x to router %0d", cycle, flit_out, dest);
    ack = is_valid_out;
  end
end

endmodule
