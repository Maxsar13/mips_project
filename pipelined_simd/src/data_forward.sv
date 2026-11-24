module data_forward(
	input logic [4:0] id_ex_rs1,
	input logic [4:0] id_ex_rs2,
	input logic [4:0] id_ex_rs3,
	input logic [4:0] id_ex_rd,
	input logic [4:0] ex_wb_rd,

	input logic ex_wb_reg_write,  
	
	output logic forward_rs1,
	output logic forward_rs2,
	output logic forward_rs3,
	output logic forward_rd
	);
	
	assign forward_rs1 = ex_wb_reg_write && (id_ex_rs1 == ex_wb_rd);
	assign forward_rs2 = ex_wb_reg_write && (id_ex_rs2 == ex_wb_rd);
	assign forward_rs3 = ex_wb_reg_write && (id_ex_rs3 == ex_wb_rd);
	assign forward_rd = ex_wb_reg_write && (id_ex_rd == ex_wb_rd);
	
endmodule
		