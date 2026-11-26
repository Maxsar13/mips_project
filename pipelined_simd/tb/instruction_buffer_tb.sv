`timescale 1ns/1ps

module instruction_buffer_tb;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [24:0] instruction;
    integer failures;

    instruction_buffer dut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    task automatic check_value(input logic [24:0] actual,
                               input logic [24:0] expected,
                               input string label);
        if (actual !== expected) begin
            failures++;
            $display("FAIL %s: expected %h, got %h", label, expected, actual);
        end
    endtask

    initial begin
        failures = 0;
        for (int i = 0; i < 64; i++)
            dut.buffer[i] = i;

        @(posedge clk);
        #1;
        check_value(dut.pc_out, '0, "reset PC");
        check_value(instruction, '0, "instruction at reset PC");

        rst = 1'b0;
        @(posedge clk);
        #1;
        check_value(dut.pc_out, 6'd1, "first PC increment");
        check_value(instruction, 25'd1, "instruction at PC 1");
        @(posedge clk);
        #1;
        check_value(dut.pc_out, 6'd2, "second PC increment");
        check_value(instruction, 25'd2, "instruction at PC 2");

        dut.pc_out = 6'd63;
        #1;
        check_value(instruction, 25'd63, "last buffer entry");
        @(posedge clk);
        #1;
        check_value(dut.pc_out, '0, "PC wraps after 64 entries");
        check_value(instruction, '0, "instruction after PC wrap");

        if (failures != 0)
            $fatal(1, "instruction_buffer_tb failed with %0d errors", failures);
        $display("PASS: instruction_buffer_tb");
        $finish;
    end
endmodule
