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
	logic id_ex_rs1_valid;
	logic id_ex_rs2_valid;
	logic id_ex_rs3_valid;
	
	
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

	regfile regfile_inst(
		.clk(clk),
		.rst(rst),
		.rs1(if_id_instr_out[24] ? if_id_instr_out[9:5] : if_id_instr_out[4:0]),
		.rs2(if_id_instr_out[14:10]),
		.rs3(if_id_instr_out[19:15]),
		.wb_en(ex_wb_write_en_out),
		.wb_data(ex_wb_rd_out_out),
		.wb_rd(ex_wb_wr_addr_out),
		.rs1_data(rs1),
		.rs2_data(rs2),
		.rs3_data(rs3)
		);
	
	id_ex_reg id_ex_reg_inst(
		.clk(clk),
		.rst(rst),
		.id_ex_instr_in(if_id_instr_out),
		.id_ex_rs1_in(rs1),
		.id_ex_rs2_in(rs2),
		.id_ex_rs3_in(rs3),
		.id_ex_rd_in('0),
		.id_ex_instr_out(id_ex_instr_out),
		.id_ex_rs1_out(id_ex_rs1_out),
		.id_ex_rs2_out(id_ex_rs2_out),
		.id_ex_rs3_out(id_ex_rs3_out),
		.id_ex_rd_out(id_ex_rd_out)
		);
	
	forward_muxes forward_muxes_inst(
		.rs1(id_ex_rs1_out),
		.rs2(id_ex_rs2_out),
		.rs3(id_ex_rs3_out),
		.rd_in('0),
		.ex_mem_data_in(ex_wb_rd_out_out),
		.forward_rs1(forward_rs1),
		.forward_rs2(forward_rs2),
		.forward_rs3(forward_rs3),
		.forward_rd(forward_rd),
		.muxed_rs1(muxed_rs1),
		.muxed_rs2(muxed_rs2),
		.muxed_rs3(muxed_rs3),
		.muxed_rd_out(muxed_rd_out)
	);
	
	alu mips_alu_inst(
		.instr(id_ex_instr_out),
		.rs1(muxed_rs1),
		.rs2(muxed_rs2),
		.rs3(muxed_rs3),
		.rd_out(rd_out),
		.wr_addr(wr_addr),
		.write_en(write_en)
	);
	
	ex_wb_reg ex_wb_reg_inst(
		.clk(clk),
		.rst(rst),
		.ex_wb_rd_out_in(rd_out),
		.ex_wb_wr_addr_in(wr_addr),
		.ex_wb_write_en_in(write_en),
		.ex_wb_rd_out_out(ex_wb_rd_out_out),
		.ex_wb_wr_addr_out(ex_wb_wr_addr_out),
		.ex_wb_write_en_out(ex_wb_write_en_out)
	);

	assign id_ex_rs1 = id_ex_instr_out[24] ? id_ex_instr_out[9:5] : id_ex_instr_out[4:0];
	assign id_ex_rs2 = id_ex_instr_out[14:10];
	assign id_ex_rs3 = id_ex_instr_out[19:15];
	assign id_ex_rd = id_ex_instr_out[4:0];
	assign ex_wb_rd = ex_wb_wr_addr_out;
	assign ex_wb_reg_write = ex_wb_write_en_out;

	// LI reads its destination through rs1
	// R4 uses all three sources
	// R3 varies by opcode and never uses the encoded rs3
	always_comb begin
		id_ex_rs1_valid = 1'b0;
		id_ex_rs2_valid = 1'b0;
		id_ex_rs3_valid = 1'b0;

		casez (id_ex_instr_out[24:23])
			2'b0?: id_ex_rs1_valid = 1'b1;
			2'b10: begin
				id_ex_rs1_valid = 1'b1;
				id_ex_rs2_valid = 1'b1;
				id_ex_rs3_valid = 1'b1;
			end
			2'b11: begin
				case (id_ex_instr_out[18:15])
					4'b0000: ; // NOP has no source registers
					4'b0011, 4'b0110, 4'b1010, 4'b1100:
						id_ex_rs1_valid = 1'b1;
					default: begin
						id_ex_rs1_valid = 1'b1;
						id_ex_rs2_valid = 1'b1;
					end
				endcase
			end
			default: ;
		endcase
	end
	
	data_forward data_forward_inst(
		.id_ex_rs1(id_ex_rs1),
		.id_ex_rs2(id_ex_rs2),
		.id_ex_rs3(id_ex_rs3),
		.id_ex_rd(id_ex_rd),
		.ex_wb_rd(ex_wb_rd),
		.ex_wb_reg_write(ex_wb_reg_write),
		.id_ex_rs1_valid(id_ex_rs1_valid),
		.id_ex_rs2_valid(id_ex_rs2_valid),
		.id_ex_rs3_valid(id_ex_rs3_valid),
		.forward_rs1(forward_rs1),
		.forward_rs2(forward_rs2),
		.forward_rs3(forward_rs3),
		.forward_rd(forward_rd)
	);
	
	
endmodule