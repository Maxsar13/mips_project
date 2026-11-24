module cpu_top(
	input logic clk,
	input logic rst
	);
	
	//Instruction buffer signals
	logic [24:0] instruction;
	
	//if/id signals
	logic [24:0] if_id_instr_out;
	
	//reg file signals
	
	//id/ex signals
	logic [24:0] id_ex_instr_in;
	logic [127:0] id_ex_rs1_in;
	logic [127:0] id_ex_rs2_in;
	logic [127:0] id_ex_rs3_in;
	logic [127:0] id_ex_rd_in;
	
	logic [24:0] id_ex_instr_out;
	logic [127:0] id_ex_rs1_out;
	logic [127:0] id_ex_rs2_out;
	logic [127:0] id_ex_rs3_out;
	logic [127:0] id_ex_rd_out;
	
	//Forwarding mux signals
	logic [127:0] rs1;
	logic [127:0] rs2;
	logic [127:0] rs3;
	logic [127:0] rd_in;
	
	logic [127:0] ex_mem_data_in;
	
	logic forward_rs1;
	logic forward_rs2;
	logic forward_rs3;
	logic forward_rd;
	
	logic [127:0] muxed_rs1;
	logic [127:0] muxed_rs2;
	logic [127:0] muxed_rs3;
	logic [127:0] muxed_rd_out;
	
	//ALU signals
	logic [24:0] instr;
	
	logic [127:0] rd_out;
	logic [4:0] wr_addr;
	logic write_en;
	
	//EX_WB signals		
	logic [127:0] ex_wb_rd_out_in;
	logic [4:0] ex_wb_wr_addr_in;
	logic ex_wb_write_en_in;
	
	logic [127:0] ex_wb_rd_out_out;
	logic [4:0] ex_wb_wr_addr_out;
	logic ex_wb_write_en_out; 
	
	//Data Forward Signals 
	logic [4:0] id_ex_rs1;
	logic [4:0] id_ex_rs2;
	logic [4:0] id_ex_rs3;
	logic [4:0] id_ex_rd;
	logic [4:0] ex_wb_rd;

	logic ex_wb_reg_write;  
	
	
	instruction_buffer instruction_buffer_inst(
		.clk(clk),
		.rst(rst),
		.instruction(instruction)
		);
	
	if_id_reg if_id_reg_inst(
		.clk(clk),
		.rst(rst),
		.if_id_instr_in(instruction),
		.if_id_instr_out(if_id_instr_out)
		);
	
	//regfile instantiation
	
	id_ex_reg id_ex_reg_inst(
		.clk(clk),
		.rst(rst),
		.id_ex_instr_in(if_id_instr_out),
		.id_ex_rs1_in(),
		.id_ex_rs2_in(),
		.id_ex_rs3_in(),
		.id_ex_rd_in(),
		.id_ex_instr_out(),
		.id_ex_rs1_out(),
		.id_ex_rs2_out(),
		.id_ex_rs3_out(),
		.id_ex_rd_out()
		);
	
	forward_muxes forward_muxes_inst(
		.rs1(),
		.rs2(),
		.rs3(),
		.rd_in(),
		.ex_mem_data_in(),
		.forward_rs1(),
		.forward_rs2(),
		.forward_rs3(),
		.forward_rd(),
		.muxed_rs1(),
		.muxed_rs2(),
		.muxed_rs3(),
		.muxed_rd_out(),	
	);
	
	mips_alu mips_alu_inst(
		.instr(),
		.rs1(),
		.rs2(),
		.rs3(),
		.rd_in(),
		.rd_out(),
		.wr_addr(),
		.write_en()
	);
	
	ex_wb_reg ex_wb_reg_inst(
		.clk(clk),
		.rst(rst),
		.ex_wb_rd_out_in(),
		.ex_wb_wr_addr_in(),
		.ex_wb_write_en_in(),
		.ex_wb_rd_out_out(),
		.ex_wb_wr_addr_out(),
		.ex_wb_write_en_out()
	);
	
	data_forward data_forward_inst(
		.id_ex_rs1(),
		.id_ex_rs2(),
		.id_ex_rs3(),
		.id_ex_rd(),
		.ex_wb_rd(),
		.ex_wb_reg_write(),
		.forward_rs1(),
		.forward_rs2(),
		.forward_rs3(),
		.forward_rd()	
	);
	
	
endmodule	