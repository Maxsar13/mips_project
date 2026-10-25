module alu(
	input logic [24:0] instr,
	input logic [127:0] rs1,
	input logic [127:0] rs2,
	input logic [127:0] rs3,
	input logic [127:0] rd_in,
	
	output logic [127:0] rd_out,
	output logic [4:0] wr_addr,
	output logic write_en
	); 
	
	//Used for load immediate instruction
	logic [6:0] shift_imm; 
	logic [127:0] imm_load;	
	
	//Used for multi-add instructions  
	logic [63:0] mask_multi;//Mask if needed
	logic [127:0] multi_one;
	logic [127:0] multi_two;
	logic signed [127:0] product;
	logic signed [64:0] sum;
	
	//Used for register instructions
	logic [31:0] broadcast;
	
	logic [15:0] op;
	logic [16:0] saturated_op;
	
	logic [31:0] rotate; 
	logic [31:0] latch;
	
	
	
	always_comb begin
		// Defaults apply on every evaluation; instruction cases override them.
		rd_out = 128'd0;
		wr_addr = instr[4:0];
		write_en = 1'b0;
		shift_imm = '0;
		imm_load = '0;
		mask_multi = '0;
		multi_one = '0;
		multi_two = '0;
		product = '0;
		sum = '0;
		broadcast = 32'hFFFFFFFF;
		op = '0;
		saturated_op = '0;
		rotate = '0;
		latch = '0;

		casez(instr[24:23]) //supports 'b0?
			2'b0?: begin	 //Load Immediate instruction
				write_en = 1'b1;
				shift_imm = {instr[23:21], 4'b0000};   //Shift used to replace section of rd
				imm_load = 128'hFFFF << shift_imm; //Shift mask to replaced section
				rd_out = (rd_in & ~imm_load) | (128'(instr[20:5]) << shift_imm);   //Using mask to replace bits
				wr_addr = instr[4:0]; 	  //Setting write address to rd
			end
			2'b10: begin
				write_en = 1'b1;
				//Multi Intstruction
				mask_multi = instr[22] ? (instr[20] ? 64'hFFFFFFFF_00000000 : 64'h00000000_FFFFFFFF) : (instr[20] ? 64'h00000000_FFFF0000 : 64'h00000000_0000FFFF);
				for(int i = 0; i < 4; i++) begin //For loop as theres always 4 segments we multiply
					if(instr[22]) begin			//For long multiplications										
						if(i % 2 == 0) begin
							multi_one = ((rs3 >> {i, 5'b00000}) & mask_multi) >> (instr[20] ? 32 : 0);
							multi_two = ((rs2 >> {i, 5'b00000}) & mask_multi) >> (instr[20] ? 32 : 0);
							product = $signed(multi_one[31:0]) * $signed(multi_two[31:0]); 
							sum = instr[21] ? $signed(rs1[i * 32 +: 64]) - product : $signed(rs1[i * 32+:64]) + product;
							rd_out[i*32+:64] = (sum[64] != sum[63]) ? (sum[64] ? 64'h80000000_00000000 : 64'h7FFFFFFF_FFFFFFFF) : sum[63:0];
						end
					end
					else begin
						multi_one = ((rs3 >> {i, 5'b00000}) & mask_multi) >> (instr[20] ? 16 : 0);
						multi_two = ((rs2 >> {i, 5'b00000}) & mask_multi) >> (instr[20] ? 16 : 0);
						product = $signed(multi_one[15:0]) * $signed(multi_two[15:0]); 
						sum = instr[21] ? $signed(rs1[i * 32 +: 32]) - product : $signed(rs1[i * 32+:32]) + product;
						rd_out[i*32+:32] = (sum[32] != sum[31]) ? (sum[32] ? 32'h8000_0000 : 32'h7FFF_FFFF) : sum[31:0];	
					end				
				end
			end
				
				
			2'b11: begin //R3 instructions
				write_en = 1'b1; //NOP and the default case disable writing.
				
				case(instr[18:15])
					4'b0000: begin	//NOP instruction
						write_en = 1'b0;
						end
					4'b0001: begin //Absolute difference of bytes
						for(int i = 0; i < 128; i = i + 8) begin
							rd_out[i+:8] = (rs1[i+:8] >= rs2[i+:8]) ? (rs1[i+:8] - rs2[i+:8]) : (rs2[i+:8] - rs1[i+:8]);
						end	
						write_en = 1'b1;
					end
					4'b0010: begin //Add word unsigned
						rd_out = {rs1[127:96] + rs2[127:96], rs1[95:64] + rs2[95:64], rs1[63:32] + rs2[63:32], rs1[31:0] + rs2[31:0]};
						write_en = 1'b1;
					end
					4'b0011: begin //count 1s in word
						int count;
						for(int i = 0; i < 128; i = i + 32)
							begin
								count = 0;
								for (int j = 0; j <32; j++)
									count += int'(rs1[i+j]);
								rd_out[i+:32] = count;
							end	
						write_en = 1'b1;
					end
					4'b0100: begin	//Add Halfword saturated 
						for(int i = 0; i < 128; i = i + 16)
							begin
								saturated_op = $signed(rs2[i+:16]) + $signed(rs1[i+:16]);
								saturated_op = (saturated_op[16] != saturated_op[15]) ? (saturated_op[16] ? 16'h8000 : 16'h7FFF) : saturated_op;
								rd_out[i+:16] = saturated_op[15:0];
							end	
						write_en = 1'b1;
					end
					4'b0101: begin //bitwise AND instruction 
						rd_out = rs2 & rs1;
					end
					4'b0110: begin //broadcast word
						broadcast = rs1[31:0];
						for(int i = 0; i < 4; i++) begin 
							rd_out = rd_out | (128'(broadcast) << {i, 5'b00000});
						end
						write_en = 1'b1;
					end
					4'b0111: begin //max signed word
						rd_out[31:0] = ($signed(rs1[31:0]) > ($signed(rs2[31:0]))) ? rs1[31:0] : rs2[31:0]; 
						rd_out[63:32] = ($signed(rs1[63:32]) > ($signed(rs2[63:32]))) ? rs1[63:32] : rs2[63:32]; 
						rd_out[95:64] = ($signed(rs1[95:64]) > ($signed(rs2[95:64]))) ? rs1[95:64] : rs2[95:64]; 
						rd_out[127:96] = ($signed(rs1[127:96]) > ($signed(rs2[127:96]))) ? rs1[127:96] : rs2[127:96]; 
						write_en = 1'b1;
					end
					4'b1000: begin //min signed word
						rd_out[31:0] = ($signed(rs1[31:0]) < ($signed(rs2[31:0]))) ? rs1[31:0] : rs2[31:0]; 
						rd_out[63:32] = ($signed(rs1[63:32]) < ($signed(rs2[63:32]))) ? rs1[63:32] : rs2[63:32]; 
						rd_out[95:64] = ($signed(rs1[95:64]) < ($signed(rs2[95:64]))) ? rs1[95:64] : rs2[95:64]; 
						rd_out[127:96] = ($signed(rs1[127:96]) < ($signed(rs2[127:96]))) ? rs1[127:96] : rs2[127:96]; 
						write_en = 1'b1;
					end
					4'b1001: begin	//Multiply low unsigned
						for(int i = 0; i < 128; i = i + 32)
							begin
								rd_out[i+:32] = 32'(rs1[i+:16] * rs2[i+:16]);
							end
						write_en = 1'b1;
					end
					4'b1010: begin //multiply low by constant unsigned
						for(int i = 0; i < 128; i = i + 32)
							begin
								rd_out[i+:32] = 32'(rs1[i+:16] * instr[14:10]);
							end
						write_en = 1'b1;							   
					end
					4'b1011: begin // bitwise OR Instruction
						rd_out = rs2 | rs1;
						write_en = 1'b1;
					end
					4'b1100: begin //Count leading zeroes in words 
						for(int i = 0; i < 128; i = i + 32)
							begin
								int count;
								count = 0;
								while ((count < 32) && (rs1[i + 31 - count] != 1'b1)) begin
									count++;
								end
								rd_out[i+:32] = count;
							end						   
						write_en = 1'b1;						
					end
					4'b1101: begin //Rotate bits in word
						for(int i = 0; i < 128; i = i + 32)
							begin
								latch = rs1[i +: 32];
								latch = (latch << (32 - instr[14:10]));
								rd_out[i +: 32] = latch | (rs1[i+:32] >> instr[14:10]);	
							end
					end
					4'b1110: begin //Subtract from word unsigned
						rd_out = {rs2[127:96] - rs1[127:96], rs2[95:64] - rs1[95:64], rs2[63:32] - rs1[63:32], rs2[31:0] - rs1[31:0]};
						write_en = 1'b1;
					end
					4'b1111: begin //subtract from halfword saturated
						for(int i = 0; i < 128; i = i + 16)
							begin
								saturated_op = $signed(rs2[i+:16]) - $signed(rs1[i+:16]);
								saturated_op = (saturated_op[16] != saturated_op[15]) ? (saturated_op[16] ? 16'h8000 : 16'h7FFF) : saturated_op;
								rd_out[i+:16] = saturated_op[15:0];
							end	
						write_en = 1'b1;
					end	
					default: begin
						rd_out = 128'd0; 
						write_en = 1'b0;
					end
				endcase		
			end
			default: begin
				rd_out = 128'd0;
				write_en = 1'b0;
			end
		endcase
	end			
endmodule
