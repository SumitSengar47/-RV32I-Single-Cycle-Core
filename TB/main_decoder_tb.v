`timescale 1ns/1ps

// Self-checking testbench for the main_decoder module.
// This testbench verifies that for a given instruction's opcode, the decoder
// produces the correct high-level control signals for the datapath.

module main_decoder_tb;

    // --- DUT Inputs and Outputs ---
    reg  [6:0] op;
    wire [1:0] result_src;
    wire       mem_write;
    wire       branch;
    wire       alu_src;
    wire       reg_write;
    wire       jump;
    wire [2:0] imm_src;
    wire [1:0] alu_op;
    wire       alu_src_a; // *** NEW *** Port added for AUIPC test

    // --- DUT Instantiation ---
    main_decoder dut (
        .op(op),
        .result_src(result_src),
        .mem_write(mem_write),
        .branch(branch),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .jump(jump),
        .imm_src(imm_src),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a) // *** NEW *** Connection for the new signal
    );

    // --- Verification Infrastructure ---

    // Local copies of encodings that must mirror main_decoder.v
    localparam RS_ALU    = 2'b00;
    localparam RS_MEM    = 2'b01;
    localparam RS_PC4    = 2'b10;

    localparam IMM_I = 3'd0;
    localparam IMM_S = 3'd1;
    localparam IMM_B = 3'd2;
    localparam IMM_U = 3'd3;
    localparam IMM_J = 3'd4;
    localparam IMM_R = 3'd5;

    localparam ALUOP_ADD   = 2'b00;
    localparam ALUOP_SUB   = 2'b01;
    localparam ALUOP_FUNCT = 2'b10;
    localparam ALUOP_MISC  = 2'b11;

    // RISC-V Opcode constants
    localparam OPC_LOAD    = 7'b0000011;
    localparam OPC_OP_IMM  = 7'b0010011;
    localparam OPC_AUIPC   = 7'b0010111;
    localparam OPC_STORE   = 7'b0100011;
    localparam OPC_OP      = 7'b0110011;
    localparam OPC_LUI     = 7'b0110111;
    localparam OPC_BRANCH  = 7'b1100011;
    localparam OPC_JAL     = 7'b1101111;
    localparam OPC_JALR    = 7'b1100111;

    integer total = 0;
    integer passed = 0;

    // This task applies a single opcode to the DUT, computes the
    // expected control signals, compares them, and prints a pass/fail message.
    task run_case(
        input [6:0] t_op,
        input [80:1] desc
    );
        // Registers to hold the expected ("exp") values for all control signals.
        reg [1:0] exp_result_src;
        reg       exp_mem_write;
        reg       exp_branch;
        reg       exp_alu_src;
        reg       exp_reg_write;
        reg       exp_jump;
        reg [2:0] exp_imm_src;
        reg [1:0] exp_alu_op;
        reg       exp_alu_src_a; // *** NEW *** Expected value for the new signal
        begin
            op = t_op;
            #2; // Allow the combinational logic to settle.

            // Set the default expected values, mirroring the DUT's default logic.
            exp_result_src = RS_ALU;
            exp_mem_write  = 1'b0;
            exp_branch     = 1'b0;
            exp_alu_src    = 1'b0;
            exp_reg_write  = 1'b0;
            exp_jump       = 1'b0;
            exp_imm_src    = IMM_R;
            exp_alu_op     = ALUOP_ADD;
            exp_alu_src_a  = 1'b0; // *** NEW *** Default is 0

            // Calculate the specific expected values for the given opcode.
            case (t_op)
                OPC_LOAD: begin
                    exp_reg_write  = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_I;
                    exp_result_src = RS_MEM;
                end
                OPC_STORE: begin
                    exp_mem_write  = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_S;
                end
                OPC_OP: begin
                    exp_reg_write  = 1'b1;
                    exp_alu_op     = ALUOP_FUNCT;
                end
                OPC_OP_IMM: begin
                    exp_reg_write  = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_I;
                    exp_alu_op     = ALUOP_FUNCT;
                end
                OPC_BRANCH: begin
                    exp_branch     = 1'b1;
                    exp_imm_src    = IMM_B;
                    exp_alu_op     = ALUOP_SUB;
                end
                OPC_JAL: begin
                    exp_reg_write  = 1'b1;
                    exp_jump       = 1'b1;
                    exp_imm_src    = IMM_J;
                    exp_result_src = RS_PC4;
                end
                OPC_JALR: begin
                    exp_reg_write  = 1'b1;
                    exp_jump       = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_I;
                    exp_result_src = RS_PC4;
                end
                OPC_LUI: begin
                    exp_reg_write  = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_U;
                    exp_alu_op     = ALUOP_MISC;
                end
                OPC_AUIPC: begin
                    exp_reg_write  = 1'b1;
                    exp_alu_src    = 1'b1;
                    exp_imm_src    = IMM_U;
                    exp_alu_op     = ALUOP_MISC;
                    exp_alu_src_a  = 1'b1; 
                end
                default: begin
                    // For unknown opcodes, all signals remain at their default values.
                end
            endcase

            // Compare all DUT outputs with their expected values.
            total = total + 1;
            if ((result_src === exp_result_src) &&
                (mem_write  === exp_mem_write)  &&
                (branch     === exp_branch)     &&
                (alu_src    === exp_alu_src)    &&
                (reg_write  === exp_reg_write)  &&
                (jump       === exp_jump)       &&
                (imm_src    === exp_imm_src)    &&
                (alu_op     === exp_alu_op)     &&
                (alu_src_a  === exp_alu_src_a)) begin 
                passed = passed + 1;
                $display("%0t | PASS | %s | op=0x%h", $time, desc, t_op);
            end else begin
                $display("%0t | FAIL | %s | op=0x%h", $time, desc, t_op);
                // Print detailed breakdown on failure.
                $display("       got: result_src=%b mem_write=%b branch=%b alu_src=%b reg_write=%b jump=%b imm_src=%b alu_op=%b alu_src_a=%b",
                         result_src, mem_write, branch, alu_src, reg_write, jump, imm_src, alu_op, alu_src_a);
                $display("       exp: result_src=%b mem_write=%b branch=%b alu_src=%b reg_write=%b jump=%b imm_src=%b alu_op=%b alu_src_a=%b",
                         exp_result_src, exp_mem_write, exp_branch, exp_alu_src, exp_reg_write, exp_jump, exp_imm_src, exp_alu_op, exp_alu_src_a);
            end
            #1;
        end
    endtask

    // This block executes the sequence of test cases.
    initial begin
        $dumpfile("main_decoder_tb.vcd");
        $dumpvars(0, main_decoder_tb);

        // --- Test Vectors ---
        run_case(OPC_OP,      "R-type (OP)");
        run_case(OPC_OP_IMM,  "I-type ALU (OP-IMM)");
        run_case(OPC_LOAD,    "Load (LW)");
        run_case(OPC_STORE,   "Store (SW)");
        run_case(OPC_BRANCH,  "Branch (B-type)");
        run_case(OPC_JAL,     "JAL");
        run_case(OPC_JALR,    "JALR");
        run_case(OPC_LUI,     "LUI");
        run_case(OPC_AUIPC,   "AUIPC");

        // --- Final Summary ---
        #5;
        $display("\n---------------------------------------------------------");
        $display("--- Main Decoder Test Summary: %0d / %0d Passed ---", passed, total);
        $display("---------------------------------------------------------");
        if (passed != total) $display("NOTE: Some tests failed.");
        else $display("SUCCESS: All Main Decoder tests passed.");
        $finish;
    end

endmodule
