module instruction_buffer(
	input logic clk, 
	input logic rst,

	output logic [24:0] instruction
	);		 
	
	logic [5:0] pc_out;
	logic [24:0] buffer [63:0];	
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			pc_out <= 6'b000000;
		else
			pc_out <= pc_out + 1;
	end
	
	assign instruction = buffer[pc_out];
endmodule	