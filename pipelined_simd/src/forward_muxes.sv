module forward_muxes(
	input logic [127:0] rs1,
	input logic [127:0] rs2,
	input logic [127:0] rs3,
	input logic [127:0] rd_in,
	
	input logic [127:0] ex_mem_data_in,
	
	input logic forward_rs1,
	input logic forward_rs2,
	input logic forward_rs3,
	input logic forward_rd,
	
	output logic [127:0] muxed_rs1,
	output logic [127:0] muxed_rs2,
	output logic [127:0] muxed_rs3,
	output logic [127:0] muxed_rd_out
	);
	
	assign muxed_rs1 = forward_rs1 ? ex_mem_data_in : rs1;
	assign muxed_rs2 = forward_rs2 ? ex_mem_data_in : rs2;
	assign muxed_rs3 = forward_rs3 ? ex_mem_data_in : rs3;
	assign muxed_rd_out = forward_rd ? ex_mem_data_in : rd_in;
	
endmodule
	