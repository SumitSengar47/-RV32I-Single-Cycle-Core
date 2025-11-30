`timescale 1ns / 1ps

// Self-checking testbench for the alu_decoder module.
// This testbench verifies that for a given instruction's opcode, funct3, and
// funct7 fields, the decoder produces the correct 4-bit alu_control signal.

module alu_decoder_tb;

    // --- DUT Inputs and Outputs ---
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire [3:0] alu_control;

    // --- DUT Instantiation ---
    // Create an instance of the decoder module we want to test.
    alu_decoder dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );

    // --- Verification Infrastructure ---
    integer total = 0;
    integer passed = 0;

    // These local parameters must match the ones inside the DUT.
    // They are used here to create a "golden model" to predict the expected output.
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_AND   = 4'b0010;
    localparam ALU_OR    = 4'b0011;
    localparam ALU_XOR   = 4'b0100;
    localparam ALU_SLT   = 4'b0101;
    localparam ALU_SLTU  = 4'b0110;
    localparam ALU_SLL   = 4'b0111;
    localparam ALU_SRL   = 4'b1000;
    localparam ALU_SRA   = 4'b1001;
    localparam ALU_LUI   = 4'b1010;
    localparam ALU_AUIPC = 4'b1011;

    // RISC-V Opcode constants.
    localparam OPC_LOAD    = 7'b0000011;
    localparam OPC_OP_IMM  = 7'b0010011;
    localparam OPC_AUIPC   = 7'b0010111;
    localparam OPC_STORE   = 7'b0100011;
    localparam OPC_OP      = 7'b0110011;
    localparam OPC_LUI     = 7'b0110111;
    localparam OPC_BRANCH  = 7'b1100011;
    localparam OPC_JAL     = 7'b1101111;
    localparam OPC_JALR    = 7'b1100111;

    // This task applies a single test vector to the DUT, computes the
    // expected result, compares it, and prints a pass/fail message.
    task run_case(
        input [6:0] t_opcode,
        input [2:0] t_f3,
        input [6:0] t_f7,
        input [128:1] desc
    );
        reg [3:0] expected;
        reg funct7_bit5;
        begin
            // Apply the inputs to the DUT.
            opcode = t_opcode;
            funct3 = t_f3;
            funct7 = t_f7;
            #2; // Wait for the combinational logic to settle.

            // Replicate the DUT's logic here to calculate the expected value.
            funct7_bit5 = t_f7[5];
            expected = ALU_ADD; // Default value, same as in the DUT.
            case (t_opcode)
                OPC_OP: begin
                    case (t_f3)
                        3'b000: expected = (funct7_bit5) ? ALU_SUB : ALU_ADD;
                        3'b001: expected = ALU_SLL;
                        3'b010: expected = ALU_SLT;
                        3'b011: expected = ALU_SLTU;
                        3'b100: expected = ALU_XOR;
                        3'b101: expected = (funct7_bit5) ? ALU_SRA : ALU_SRL;
                        3'b110: expected = ALU_OR;
                        3'b111: expected = ALU_AND;
                        default: expected = ALU_ADD;
                    endcase
                end
                OPC_OP_IMM: begin
                    case (t_f3)
                        3'b000: expected = ALU_ADD;
                        3'b001: expected = ALU_SLL;
                        3'b010: expected = ALU_SLT;
                        3'b011: expected = ALU_SLTU;
                        3'b100: expected = ALU_XOR;
                        3'b101: expected = (funct7_bit5) ? ALU_SRA : ALU_SRL;
                        3'b110: expected = ALU_OR;
                        3'b111: expected = ALU_AND;
                        default: expected = ALU_ADD;
                    endcase
                end
                OPC_LOAD, OPC_STORE, OPC_JALR: expected = ALU_ADD;
                OPC_BRANCH: expected = ALU_SUB;
                OPC_LUI: expected = ALU_LUI;
                OPC_AUIPC: expected = ALU_AUIPC;
                OPC_JAL: expected = ALU_ADD;
                default: expected = ALU_ADD;
            endcase

            // Compare the DUT's output with the expected value and report.
            total = total + 1;
            if (alu_control === expected) begin
                passed = passed + 1;
                $display("%0t | PASS | %s", $time, desc);
            end else begin
                $display("%0t | FAIL | %s | opcode=0x%h f3=%b f7[5]=%b -> got=%b expected=%b",
                         $time, desc, t_opcode, t_f3, funct7_bit5, alu_control, expected);
            end
            #1;
        end
    endtask

    // This block executes the sequence of test cases.
    initial begin
        $dumpfile("alu_decoder_tb.vcd");
        $dumpvars(0, alu_decoder_tb);

        // --- Test Vectors ---
        run_case(OPC_OP,      3'b000, 7'b0000000, "R-type ADD");
        run_case(OPC_OP,      3'b000, 7'b0100000, "R-type SUB");
        run_case(OPC_OP,      3'b001, 7'b0000000, "R-type SLL");
        run_case(OPC_OP,      3'b101, 7'b0000000, "R-type SRL");
        run_case(OPC_OP,      3'b101, 7'b0100000, "R-type SRA");
        run_case(OPC_OP_IMM,  3'b000, 7'b0000000, "I-type ADDI");
        run_case(OPC_OP_IMM,  3'b101, 7'b0000000, "I-type SRLI");
        run_case(OPC_OP_IMM,  3'b101, 7'b0100000, "I-type SRAI");
        run_case(OPC_LOAD,    3'b010, 7'b0000000, "LOAD -> ADD (addr calc)");
        run_case(OPC_STORE,   3'b010, 7'b0000000, "STORE -> ADD (addr calc)");
        run_case(OPC_BRANCH,  3'b000, 7'b0000000, "BRANCH -> SUB");
        run_case(OPC_LUI,     3'b000, 7'b0000000, "LUI -> LUI");
        run_case(OPC_AUIPC,   3'b000, 7'b0000000, "AUIPC -> AUIPC");
        run_case(OPC_JAL,     3'b000, 7'b0000000, "JAL -> ADD (pc+imm)");
        run_case(OPC_JALR,    3'b000, 7'b0000000, "JALR -> ADD (rs1+imm)");

        // --- Final Summary ---
        #5;
        $display("\n---------------------------------------------------------");
        $display("--- ALU Decoder Test Summary: %0d / %0d Passed ---", passed, total);
        $display("---------------------------------------------------------");
        if (passed != total) $display("NOTE: Some tests failed.");
        else $display("SUCCESS: All ALU Decoder tests passed.");
        $finish;
    end

endmodule
