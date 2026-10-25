`timescale 1ns/1ps

// self-checking tb for the alu functions

module mips_alu_tb;
    logic [24:0] instr;
    logic [127:0] rs1, rs2, rs3, rd_in;
    wire [127:0] rd_out;
    wire [4:0] wr_addr;
    wire write_en;

    // reported check and failure counts
    integer checks = 0;
    integer failures = 0;

    //instance
    alu dut (
        .instr(instr), .rs1(rs1), .rs2(rs2), .rs3(rs3), .rd_in(rd_in),
        .rd_out(rd_out), .wr_addr(wr_addr), .write_en(write_en)
    );

    // R3 breakdown
    // 11 | unused_opcode[3:0] | opcode[3:0] | rs2/imm | rs1 | rd.
    function automatic logic [24:0] r3_instr(
        input logic [3:0] opcode,
        input logic [4:0] imm,
        input logic [4:0] rd
    );
        r3_instr = {2'b11, 4'b0, opcode, imm, 5'd2, rd};
    endfunction

    function automatic logic [127:0] random_vector();
        random_vector = {$urandom, $urandom, $urandom, $urandom};
    endfunction

    // golden model generation
    function automatic logic [127:0] r3_expected(
        input logic [3:0] opcode,
        input logic [127:0] a, b,
        input logic [4:0] imm
    );
        logic [127:0] result;
        logic [31:0] aw, bw;
        logic signed [63:0] arithmetic;
        integer count, amount;
        bit found;

        result = '0;

        case (opcode)
            4'b0000: result = '0; // NOP data is ignored by the checker.
            4'b0001: begin // Absolute difference of unsigned bytes
                for (int i = 0; i < 128; i += 8)
                    result[i +: 8] = (a[i +: 8] >= b[i +: 8])
                        ? a[i +: 8] - b[i +: 8]
                        : b[i +: 8] - a[i +: 8];
            end
            4'b0100, 4'b1111: begin // 0100: signed saturated halfword add; 1111: subtract (rs2 - rs1)
                for (int i = 0; i < 128; i += 16) begin
                    arithmetic = $signed(a[i +: 16]);
                    if (opcode == 4'b0100)
                        arithmetic = arithmetic + $signed(b[i +: 16]);
                    else
                        arithmetic = $signed(b[i +: 16]) - arithmetic;
                    if (arithmetic > 32767)
                        result[i +: 16] = 16'h7fff;
                    else if (arithmetic < -32768)
                        result[i +: 16] = 16'h8000;
                    else
                        result[i +: 16] = arithmetic[15:0];
                end
            end
            4'b0101: result = a & b; // Bitwise AND
            4'b0110: result = {4{a[31:0]}}; // Broadcast low word
            4'b1011: result = a | b; // Bitwise OR
            default: begin // operations with 32-bit words
                for (int i = 0; i < 128; i += 32) begin
                    aw = a[i +: 32];
                    bw = b[i +: 32];
                    case (opcode)
                        4'b0010: result[i +: 32] = aw + bw; // Add word unsigned
                        4'b0011: begin // Count set bits in word
                            count = 0;
                            for (int j = 0; j < 32; j++)
                                count += int'(aw[j]);
                            result[i +: 32] = count;
                        end
                        4'b0111: result[i +: 32] = ($signed(aw) > $signed(bw)) ? aw : bw; // Maximum signed word
                        4'b1000: result[i +: 32] = ($signed(aw) < $signed(bw)) ? aw : bw; // Minimum signed word
                        4'b1001: result[i +: 32] = 32'(aw[15:0]) * 32'(bw[15:0]); // Multiply low unsigned halfwords
                        4'b1010: result[i +: 32] = 32'(aw[15:0]) * 32'(imm); // Multiply low unsigned halfword by immediate
                        4'b1100: begin // Count leading zeroes in word
                            count = 0;
                            found = 0;
                            for (int j = 31; j >= 0; j--) begin
                                if (aw[j]) found = 1;
                                if (!found) count++;
                            end
                            result[i +: 32] = count;
                        end
                        4'b1101: begin // Rotate word right
                            amount = imm;
                            result[i +: 32] = (amount == 0) ? aw
                                : (aw >> amount) | (aw << (32 - amount));
                        end
                        4'b1110: result[i +: 32] = bw - aw; // Subtract from word unsigned (b - a)
                        default: result[i +: 32] = 'x; // Unknown opcode
                    endcase
                end
            end
        endcase
        return result;
    endfunction

    // mode[2]: 32x32 -> 64 (otherwise 16x16 -> 32).
    // mode[1]: subtract product; mode[0]: upper operand halves.
    function automatic logic [127:0] r4_expected(
        input logic [2:0] mode,
        input logic [127:0] accumulator, a, b
    );
        logic [127:0] result;
        logic signed [63:0] operand_a, operand_b, product_ref;
        logic signed [64:0] total, product_ext, maximum, minimum;
        integer width_bits, operand_bits, offset_bits;
        width_bits = mode[2] ? 64 : 32;
        operand_bits = width_bits / 2;
        offset_bits = mode[0] ? operand_bits : 0;
        if (mode[2]) begin
            maximum = {1'b0, 64'h7fff_ffff_ffff_ffff};
            minimum = {1'b1, 64'h8000_0000_0000_0000};
        end else begin
            maximum = 65'sd2147483647;
            minimum = -65'sd2147483648;
        end
        result = '0;
        for (int i = 0; i < 128; i += width_bits) begin
            if (mode[2]) begin
                operand_a = $signed(a[i + offset_bits +: 32]);
                operand_b = $signed(b[i + offset_bits +: 32]);
                total = $signed(accumulator[i +: 64]);
            end else begin
                operand_a = $signed(a[i + offset_bits +: 16]);
                operand_b = $signed(b[i + offset_bits +: 16]);
                total = $signed(accumulator[i +: 32]);
            end
            product_ref = operand_a * operand_b;
            product_ext = {product_ref[63], product_ref};
            total = mode[1] ? total - product_ext : total + product_ext;
            if (total > maximum) total = maximum;
            if (total < minimum) total = minimum;
            if (mode[2]) result[i +: 64] = total[63:0];
            else         result[i +: 32] = total[31:0];
        end
        return result;
    endfunction

    task automatic check_result(
        input string label_text,
        input logic [127:0] expected,
        input bit expected_write
    );
        // No clock: let the combinational ALU settle after changing inputs.
        #1;
        checks++;
        if ((write_en !== expected_write) ||
            (expected_write && ((rd_out !== expected) ||
                                (wr_addr !== instr[4:0])))) begin
            failures++;
            $display("FAIL %s instr=%h", label_text, instr);
            $display("  rs1=%h rs2=%h rs3=%h rd_in=%h", rs1, rs2, rs3, rd_in);
            $display("  expected data=%h addr=%0d en=%b", expected, instr[4:0], expected_write);
            $display("  actual   data=%h addr=%0d en=%b", rd_out, wr_addr, write_en);
        end
    endtask

    task automatic check_r3(
        input logic [3:0] opcode,
        input logic [127:0] a, b,
        input logic [4:0] imm,
        input string label_text
    );
        instr = r3_instr(opcode, imm, 5'd19);
        rs1 = a;
        rs2 = b;
        if (opcode == 4'b1101) rs2[14:10] = imm;
        rs3 = '0;
        rd_in = '1;
        check_result(label_text, r3_expected(opcode, rs1, rs2, imm), opcode != 0);
    endtask

    task automatic check_r4(
        input logic [2:0] mode,
        input logic [127:0] accumulator, a, b,
        input string label_text
    );
        instr = {2'b10, mode, 5'd3, 5'd2, 5'd1, 5'd27};
        rs1 = accumulator;
        rs2 = a;
        rs3 = b;
        rd_in = '0;
        check_result(label_text, r4_expected(mode, accumulator, a, b), 1);
    endtask

    initial begin : stimulus
        logic [127:0] expected;
        logic [127:0] accumulator, a, b;
        instr = '0;
        rs1 = '0;
        rs2 = '0;
        rs3 = '0;
        rd_in = '0;
        // Enable waveform output with simulator argument +dump.
        if ($test$plusargs("dump")) begin
            $dumpfile("mips_alu_tb.vcd");
            $dumpvars(0, mips_alu_tb);
        end

        // Every imm lane and rd, preserving all other bits.
        for (int lane = 0; lane < 8; lane++) begin
            for (int rd = 0; rd < 32; rd++) begin
                rd_in = random_vector();
                instr = {1'b0, 3'(lane), 16'ha55a, 5'(rd)};
                expected = rd_in;
                expected[lane * 16 +: 16] = 16'ha55a;
                check_result($sformatf("LI lane=%0d rd=%0d", lane, rd), expected, 1);
            end
        end

        for (int opcode = 0; opcode < 16; opcode++) begin
            check_r3(4'(opcode), '0, '0, 0, $sformatf("R3 %04b zero", 4'(opcode)));
            check_r3(4'(opcode), '1, '1, 31, $sformatf("R3 %04b ones", 4'(opcode)));
            check_r3(4'(opcode),
                128'h80000000_7fffffff_00000001_ffffffff,
                128'h7fffffff_80000000_ffffffff_00000001,
                1, $sformatf("R3 %04b signed boundaries", 4'(opcode)));
            for (int sample = 0; sample < 20; sample++)
                check_r3(4'(opcode), random_vector(), random_vector(),
                    5'(sample), $sformatf("R3 %04b random %0d", 4'(opcode), sample));
        end

        check_r3(4'b0001, {8{16'h00ff}}, {8{16'hff00}}, 0, "byte differences must not borrow across bytes");
        check_r3(4'b0100, {4{32'h7fff8000}}, {4{32'h0001ffff}}, 0, "halfword add saturates both signs");
        check_r3(4'b1111, {4{32'hffff0001}}, {4{32'h7fff8000}}, 0, "halfword subtract saturates both signs");
        check_r3(4'b1100, 128'h00000000_00000001_80000000_00010000, '0, 0, "CLZ 32/31/0/15");
        for (int amount = 0; amount < 32; amount++)
            check_r3(4'b1101, 128'h12345678_80000001_ffffffff_00000001,
                '0, 5'(amount), $sformatf("rotate amount=%0d", amount));

        for (int mode = 0; mode < 8; mode++) begin
            check_r4(3'(mode), '0, '0, '0, $sformatf("R4 %b zero", 3'(mode)));
            check_r4(3'(mode), '0,
                {4{32'hfffe0003}}, {4{32'h0004fffb}},
                $sformatf("R4 %b distinct upper/lower operands", 3'(mode)));
            // +/-1 products at accumulator limits exercise both saturation directions.
            if (mode >= 4) begin
                accumulator = {64'h7fff_ffff_ffff_ffff, 64'h8000_0000_0000_0000};
                a = {4{32'h00000001}};
                b = (mode & 2) ? {64'hffffffff_ffffffff, 64'h00000001_00000001}
                               : {64'h00000001_00000001, 64'hffffffff_ffffffff};
            end else begin
                accumulator = {2{64'h7fffffff_80000000}};
                a = {8{16'h0001}};
                b = (mode & 2) ? {2{64'hffffffff_00010001}}
                               : {2{64'h00010001_ffffffff}};
            end
            check_r4(3'(mode), accumulator, a, b, $sformatf("R4 %b saturation", 3'(mode)));
            for (int sample = 0; sample < 30; sample++)
                check_r4(3'(mode), random_vector(), random_vector(), random_vector(),
                    $sformatf("R4 %b random %0d", 3'(mode), sample));
        end

        // Exercise write-enable transitions after arithmetic and NOP.
        check_r3(4'b0000, '0, '0, 0, "NOP disables write after R4");
        check_r3(4'b0101, '1, '1, 0, "AND enables write after NOP");
        check_r3(4'b0000, '0, '0, 0, "NOP disables write after R3");
        instr = {1'b0, 3'd7, 16'hffff, 5'd31};
        rd_in = '0;
        check_result("LI enables write after NOP", {16'hffff, 112'b0}, 1);

        if (failures != 0)
            $fatal(1, "FAILED: %0d of %0d checks", failures, checks);
        $display("PASS: %0d ALU checks", checks);
        $finish;
    end

    // Catches time-advancing hangs; simulator iteration limits are still needed
    // for a zero-time infinite loop inside the DUT's combinational logic.
    initial begin
        #100000;
        $fatal(1, "Testbench timed out");
    end
endmodule