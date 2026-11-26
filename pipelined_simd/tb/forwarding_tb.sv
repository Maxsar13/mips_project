`timescale 1ns/1ps

module forwarding_tb;
    logic [4:0] id_ex_rs1;
    logic [4:0] id_ex_rs2;
    logic [4:0] id_ex_rs3;
    logic [4:0] id_ex_rd;
    logic [4:0] ex_wb_rd;
    logic ex_wb_reg_write;
    logic id_ex_rs1_valid;
    logic id_ex_rs2_valid;
    logic id_ex_rs3_valid;
    logic forward_rs1;
    logic forward_rs2;
    logic forward_rs3;
    logic forward_rd;
    logic [127:0] rs1;
    logic [127:0] rs2;
    logic [127:0] rs3;
    logic [127:0] rd_in;
    logic [127:0] ex_wb_data;
    logic [127:0] muxed_rs1;
    logic [127:0] muxed_rs2;
    logic [127:0] muxed_rs3;
    logic [127:0] muxed_rd;
    integer failures;

    data_forward forwarding (
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
    forward_muxes muxes (
        .rs1(rs1),
        .rs2(rs2),
        .rs3(rs3),
        .rd_in(rd_in),
        .ex_mem_data_in(ex_wb_data),
        .forward_rs1(forward_rs1),
        .forward_rs2(forward_rs2),
        .forward_rs3(forward_rs3),
        .forward_rd(forward_rd),
        .muxed_rs1(muxed_rs1),
        .muxed_rs2(muxed_rs2),
        .muxed_rs3(muxed_rs3),
        .muxed_rd_out(muxed_rd)
    );

    task automatic check_bit(input logic actual, input logic expected,
                             input string label);
        if (actual !== expected) begin
            failures++;
            $display("FAIL %s: expected %b, got %b", label, expected, actual);
        end
    endtask
    task automatic check_data(input logic [127:0] actual,
                              input logic [127:0] expected,
                              input string label);
        if (actual !== expected) begin
            failures++;
            $display("FAIL %s: expected %h, got %h", label, expected, actual);
        end
    endtask

    initial begin
        failures = 0;
        rs1 = 128'h11;
        rs2 = 128'h22;
        rs3 = 128'h33;
        rd_in = 128'h44;
        ex_wb_data = 128'hfeed;
        id_ex_rs1 = 5'd7;
        id_ex_rs2 = 5'd7;
        id_ex_rs3 = 5'd7;
        id_ex_rd = 5'd7;
        ex_wb_rd = 5'd7;
        ex_wb_reg_write = 1'b1;
        id_ex_rs1_valid = 1'b1;
        id_ex_rs2_valid = 1'b1;
        id_ex_rs3_valid = 1'b1;
        #1;
        check_bit(forward_rs1, 1, "valid rs1 hazard");
        check_bit(forward_rs2, 1, "valid rs2 hazard");
        check_bit(forward_rs3, 1, "valid rs3 hazard");
        check_bit(forward_rd, 1, "destination hazard");
        check_data(muxed_rs1, ex_wb_data, "rs1 mux forwards data");
        check_data(muxed_rs2, ex_wb_data, "rs2 mux forwards data");
        check_data(muxed_rs3, ex_wb_data, "rs3 mux forwards data");
        check_data(muxed_rd, ex_wb_data, "rd mux forwards data");

        id_ex_rs1_valid = 1'b0;
        id_ex_rs2_valid = 1'b0;
        id_ex_rs3_valid = 1'b0;
        #1;
        check_bit(forward_rs1, 0, "immediate/NOP rs1 is not forwarded");
        check_bit(forward_rs2, 0, "immediate/NOP rs2 is not forwarded");
        check_bit(forward_rs3, 0, "unused rs3 is not forwarded");
        check_data(muxed_rs1, rs1, "invalid rs1 selects register data");

        id_ex_rs1_valid = 1'b1;
        ex_wb_rd = '0;
        #1;
        check_bit(forward_rs1, 0, "r0 producer is not forwarded");
        ex_wb_rd = 7;
        ex_wb_reg_write = 1'b0;
        #1;
        check_bit(forward_rs1, 0, "write-disabled producer is not forwarded");

        if (failures != 0)
            $fatal(1, "forwarding_tb failed with %0d errors", failures);
        $display("PASS: forwarding_tb");
        $finish;
    end
endmodule
