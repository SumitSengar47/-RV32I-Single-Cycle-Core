// control_unit.v

// This is the top-level control unit. It integrates the decoders and the branch
// decision logic to generate all control signals for the datapath.
// This is the final, corrected version with fixes for branch logic.

module control_unit (
    // --- Inputs ---
    input  wire [6:0] opcode,     // The instruction's opcode field.
    input  wire [2:0] funct3,     // The instruction's funct3 field.
    input  wire [6:0] funct7,     // The instruction's funct7 field.
    input  wire       alu_zero,   // The 'zero' flag from the ALU.
    input  wire       alu_carry,  // The 'carry' flag from the ALU.
    input  wire       alu_over,   // The 'overflow' flag from the ALU.
    input  wire       alu_neg,    // The 'negative' flag from the ALU.

    // --- Outputs ---
    // These signals are wired directly to the datapath.
    output wire [1:0] result_src,
    output wire       mem_write,
    output wire       alu_src,
    output wire       alu_src_a,
    output wire       reg_write,
    output wire       jump,
    output wire [2:0] imm_src,
    output wire [3:0] alu_control,
    output wire       pc_src      // The final decision signal for the PC multiplexer.
);
    
    // --- Internal Wires ---
    // Wire to hold the preliminary 'branch' signal from the main decoder.
    wire branch;

    // --- Main Decoder Instantiation ---
    // This first-level decoder generates high-level control signals based only on the opcode.
    main_decoder u_main_decoder (
        .op        (opcode),
        .result_src(result_src),
        .mem_write (mem_write),
        .branch    (branch),
        .alu_src   (alu_src),
        .alu_src_a (alu_src_a),
        .reg_write (reg_write),
        .jump      (jump),
        .imm_src   (imm_src)
    );

    // --- ALU Decoder Instantiation ---
    // This second-level decoder generates the specific 4-bit control code for the ALU.
    alu_decoder u_alu_decoder (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .alu_control(alu_control)
    );

    // --- Branch Decision Logic ---
    // This block determines if a conditional branch should be taken.
    wire branch_cond;

    // This single 'assign' statement is a robust and efficient way to implement the branch logic.
    // It correctly implements all standard RISC-V branch conditions.
    // It uses the funct3 field to determine the type of comparison and the ALU
    // flags to evaluate the condition.
    assign branch_cond = (branch) ? // Only evaluate if it's a branch instruction
                         ( (funct3 == 3'b000 &&  alu_zero)   | // BEQ (Branch if Equal)
                           (funct3 == 3'b001 && ~alu_zero)   | // BNE (Branch if Not Equal)
                           (funct3 == 3'b100 && (alu_neg ^ alu_over)) | // BLT (Branch if Less Than, signed)
                           (funct3 == 3'b101 && ~(alu_neg ^ alu_over))| // BGE (Branch if Greater/Equal, signed)
                           (funct3 == 3'b110 && ~alu_carry)  | // BLTU (Branch if Less Than, unsigned)
                           (funct3 == 3'b111 &&  alu_carry) )  // BGEU (Branch if Greater/Equal, unsigned)
                         : 1'b0;

    // --- Final PC Source Selection ---
    // The PC should change to the target address if it's an unconditional jump
    // OR if it's a conditional branch whose condition was met.
    assign pc_src = jump | branch_cond;

endmodule

