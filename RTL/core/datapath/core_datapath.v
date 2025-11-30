// core_datapath.v
// This module connects all the datapath components of the single-cycle processor.
// It is responsible for the flow of data between the PC, register file, ALU, etc.

module core_datapath #(
    parameter DATA_WIDTH = 32
) (
    // --- Control Inputs (from Control Unit) ---
    input  wire               clk,
    input  wire               reset_n,
    input  wire [1:0]         result_src,
    input  wire               pc_src,
    input  wire               alu_src,
    input  wire               alu_src_a,
    input  wire               reg_write,
    input  wire [2:0]         imm_src,
    input  wire [3:0]         alu_control,

    // --- Data Inputs ---
    input  wire [31:0]        instr,
    input  wire [31:0]        read_data,

    // --- Flag and Data Outputs ---
    output wire               zero,
    output wire               carry,      
    output wire               overflow,   // ADDED: For signed branches
    output wire               negative,   // ADDED: For signed branches
    output wire [31:0]        pc,
    output wire [31:0]        alu_result,
    output wire [31:0]        write_data,

    // --- Debug Port (for Testbench) ---
    input  wire [4:0]         dbg_reg_addr,
    output wire [31:0]        dbg_reg_data
);

    // --- Internal Wires ---
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] pc_target;
    wire [31:0] imm_ext;
    wire [31:0] rf_rd1;         // Data from register file read port 1 (for rs1)
    wire [31:0] rf_rd2;         // Data from register file read port 2 (for rs2)
    wire [31:0] src_a;          // First input to the ALU
    wire [31:0] src_b;          // Second input to the ALU
    wire [31:0] result;         // The final result to be written back to the register file

    // --- PC Logic Block ---
    // This section calculates the address of the next instruction.
    pc u_pc (.clk(clk), .reset_n(reset_n), .pc_next(pc_next), .pc(pc));
    pc_plus4 u_pc_plus4 (.pc(pc), .pc_plus4(pc_plus4));
    pc_target u_pc_target (.pc(pc), .imm_ext(imm_ext), .pc_target(pc_target));
    pc_mux u_pc_mux (.pc_plus4(pc_plus4), .pc_target(pc_target), .pc_src(pc_src), .pc_next(pc_next));

    // --- Register File ---
    // Reads from and writes to the main processor registers.
    register_file u_register_file (
        .clk(clk),
        .reset_n(reset_n),
        .we3(reg_write),
        .ra1(instr[19:15]),
        .ra2(instr[24:20]),
        .wa3(instr[11:7]),
        .wd3(result),
        .rd1(rf_rd1),
        .rd2(rf_rd2),
        .dbg_addr(dbg_reg_addr),
        .dbg_data(dbg_reg_data)
    );

    // --- Immediate Generation Unit ---
    // Decodes and sign-extends the immediate value from the instruction.
    extend u_extend (.instr(instr), .imm_src(imm_src), .imm_ext(imm_ext));
    
    // --- ALU Path ---
    // This section performs the main calculation for the instruction.

    // Mux to select the first ALU input: either from the register file (rs1) or the PC.
    assign src_a = alu_src_a ? pc : rf_rd1;

    // Mux to select the second ALU input: either from the register file (rs2) or the immediate.
    alu_mux u_alu_mux (.wd(rf_rd2), .imm_ext(imm_ext), .alu_src(alu_src), .b(src_b));

    // The main ALU that performs the calculation.
    alu u_alu (
        .src_a(src_a),
        .src_b(src_b),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow),
        .negative(negative)
    );
    
    // --- Write-Back Path ---
    // This section selects the final result to be written back to the register file.

    // Mux to select the final result: from the ALU, from memory, or PC+4.
    result_mux u_result_mux (
        .alu_result(alu_result),
        .read_data(read_data),
        .pc_plus4(pc_plus4),
        .result_src(result_src),
        .result(result)
    );

    // --- Final Datapath Outputs ---
    // The data to be written to memory for a store instruction comes from read port 2.
    assign write_data = rf_rd2;

endmodule

