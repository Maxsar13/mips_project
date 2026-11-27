`timescale 1ns/1ps

module cpu_top_tb;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [24:0] nop_instruction;
    logic [127:0] expected_regs [0:31];
    integer results_file;
    integer cycle;
    integer failures;
    integer forwarding_events;
    integer invalid_forwarding_events;
    integer program_length;
    integer expected_register_count;
    integer run_cycles;

    cpu_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    function automatic integer count_file_lines(input string file_name);
        integer input_file;
        integer line_count;
        string line;

        input_file = $fopen(file_name, "r");
        if (input_file == 0)
            $fatal(1, "Could not open %s", file_name);

        line_count = 0;
        while ($fgets(line, input_file))
            line_count++;
        $fclose(input_file);
        return line_count;
    endfunction

    initial begin
        nop_instruction = 25'b11_0000_0000_00000_00000_00000;
        results_file = $fopen("tb/cpu_results.log", "w");
        if (results_file == 0)
            $fatal(1, "Could not open tb/cpu_results.log");

        program_length = count_file_lines("tb/cpu_program.mem");
        if (program_length == 0 || program_length > 64)
            $fatal(1, "Program must contain between 1 and 64 instructions");

        for (int i = 0; i < 64; i++)
            dut.instruction_buffer_inst.buffer[i] = nop_instruction;
        $readmemb("tb/cpu_program.mem", dut.instruction_buffer_inst.buffer, 0,
                  program_length - 1);

        for (int i = 0; i < 32; i++)
            expected_regs[i] = '0;
        expected_register_count = count_file_lines("tb/cpu_expected.mem");
        if (expected_register_count > 32)
            $fatal(1, "Expected-results file contains more than 32 registers");
        if (expected_register_count != 0)
            $readmemh("tb/cpu_expected.mem", expected_regs, 0,
                      expected_register_count - 1);

        run_cycles = program_length + 4;

        cycle = 0;
        failures = 0;
        forwarding_events = 0;
        invalid_forwarding_events = 0;
        $fdisplay(
            results_file,
            "cycle IF_instruction ID_instruction EX_instruction ID_rs1 ID_rs2 ID_rs3 EX_rs1 EX_rs2 EX_rs3 ALU_result WB_rd WB_data WB_en fwd_rs1 fwd_rs2 fwd_rs3 fwd_rd"
        );

        repeat (2) @(negedge clk);
        rst = 1'b0;
        repeat (run_cycles) @(posedge clk);
        #1;

        for (int i = 0; i < 32; i++) begin
            if (dut.regfile_inst.regs[i] !== expected_regs[i]) begin
                failures++;
                $display("FAIL r%0d: expected %h, got %h", i,
                         expected_regs[i], dut.regfile_inst.regs[i]);
            end
        end

        if (forwarding_events == 0) begin
            failures++;
            $display("FAIL: program exercised no forwarding paths");
        end
        if (invalid_forwarding_events != 0) begin
            failures++;
            $display("FAIL: observed %0d invalid forwarding events",
                     invalid_forwarding_events);
        end

        $fclose(results_file);
        if (failures != 0)
            $fatal(1, "CPU regression failed: %0d register mismatches", failures);
        $display("PASS: CPU program completed with %0d register checks", 32);
        $finish;
    end

    always @(posedge clk) begin
        #1;
        if (!rst) begin
            $fdisplay(
                results_file,
                "%0d %h %h %h %h %h %h %h %h %h %h r%0d %h %b %b %b %b %b",
                cycle,
                dut.instruction,
                dut.if_id_instr_out,
                dut.id_ex_instr_out,
                dut.rs1,
                dut.rs2,
                dut.rs3,
                dut.id_ex_rs1_out,
                dut.id_ex_rs2_out,
                dut.id_ex_rs3_out,
                dut.rd_out,
                dut.ex_wb_wr_addr_out,
                dut.ex_wb_rd_out_out,
                dut.ex_wb_write_en_out,
                dut.forward_rs1,
                dut.forward_rs2,
                dut.forward_rs3,
                dut.forward_rd
            );
            if ((dut.forward_rs1 && (dut.id_ex_rs1 != '0)) ||
                (dut.forward_rs2 && (dut.id_ex_rs2 != '0)) ||
                (dut.forward_rs3 && (dut.id_ex_rs3 != '0)))
                forwarding_events++;
            if ((dut.forward_rs1 && !dut.id_ex_rs1_valid) ||
                (dut.forward_rs2 && !dut.id_ex_rs2_valid) ||
                (dut.forward_rs3 && !dut.id_ex_rs3_valid))
                invalid_forwarding_events++;
            cycle++;
        end
    end

    initial begin
        #10000;
        $fatal(1, "CPU testbench timed out");
    end
endmodule
