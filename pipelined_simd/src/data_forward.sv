module data_forward(
	input logic [4:0] id_ex_rs1,
	input logic [4:0] id_ex_rs2,
	input logic [4:0] id_ex_rs3,
	input logic [4:0] id_ex_rd,
	input logic [4:0] ex_wb_rd,

	input logic ex_wb_reg_write,
	input logic id_ex_rs1_valid,
	input logic id_ex_rs2_valid,
	input logic id_ex_rs3_valid,
	
	output logic forward_rs1,
	output logic forward_rs2,
	output logic forward_rs3,
	output logic forward_rd
	);
	
	assign forward_rs1 = id_ex_rs1_valid && ex_wb_reg_write && (ex_wb_rd != '0) && (id_ex_rs1 != '0) && (id_ex_rs1 == ex_wb_rd);
	assign forward_rs2 = id_ex_rs2_valid && ex_wb_reg_write && (ex_wb_rd != '0) && (id_ex_rs2 != '0) && (id_ex_rs2 == ex_wb_rd);
	assign forward_rs3 = id_ex_rs3_valid && ex_wb_reg_write && (ex_wb_rd != '0) && (id_ex_rs3 != '0) && (id_ex_rs3 == ex_wb_rd);
	assign forward_rd = ex_wb_reg_write && (ex_wb_rd != '0) && (id_ex_rd != '0) && (id_ex_rd == ex_wb_rd);
	
endmodule
