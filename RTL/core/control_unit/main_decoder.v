// main_decoder.v
// This module decodes the instruction's opcode to produce high-level control signals.


module main_decoder (
    // --- Ports ---
    input  wire [6:0] op,          // The 7-bit opcode from the instruction.
    output reg  [1:0] result_src,  // Selects the source for register write-back.
    output reg        mem_write,   // Enables writing to data memory.
    output reg        branch,      // Indicates a conditional branch instruction.
    output reg        alu_src,     // Selects the ALU's second operand (rs2 or immediate).
    output reg        alu_src_a,   // Selects the ALU's first operand (rs1 or PC).
    output reg        reg_write,   // Enables writing to the register file.
    output reg        jump,        // Indicates a JAL or JALR instruction.
    output reg  [2:0] imm_src      // Selects the immediate format for the extend unit.
);

    // --- Encodings for Control Signals ---
    localparam RS_ALU = 2'b00, RS_MEM = 2'b01, RS_PC4 = 2'b10;
    localparam IMM_I = 3'd0, IMM_S = 3'd1, IMM_B = 3'd2, IMM_U = 3'd3, IMM_J = 3'd4, IMM_R = 3'd5;

    // --- RISC-V Opcode Constants ---
    localparam OPC_LOAD   = 7'b0000011, OPC_OP_IMM = 7'b0010011, OPC_AUIPC  = 7'b0010111;
    localparam OPC_STORE  = 7'b0100011, OPC_OP     = 7'b0110011, OPC_LUI    = 7'b0110111;
    localparam OPC_BRANCH = 7'b1100011, OPC_JAL    = 7'b1101111, OPC_JALR   = 7'b1100111;

    // --- Combinational Decoder Logic ---
    always @(*) begin
        // --- Default Control Signal Values ---
        result_src = RS_ALU;
        mem_write  = 1'b0;
        branch     = 1'b0;
        alu_src    = 1'b0; // Default to using rs2 as ALU input B
        alu_src_a  = 1'b0; // Default to using rs1 as ALU input A
        reg_write  = 1'b0;
        jump       = 1'b0;
        imm_src    = IMM_R;

        // --- Opcode-Based Decoding ---
        case (op)
            OPC_LOAD:   {reg_write, alu_src, imm_src, result_src} = {1'b1, 1'b1, IMM_I, RS_MEM};
            OPC_STORE:  {mem_write, alu_src, imm_src}             = {1'b1, 1'b1, IMM_S};
            OPC_OP:     {reg_write, imm_src}                      = {1'b1, IMM_R};
            OPC_OP_IMM: {reg_write, alu_src, imm_src}             = {1'b1, 1'b1, IMM_I};
            OPC_BRANCH: {branch, imm_src}                         = {1'b1, IMM_B};
            OPC_JAL:    {reg_write, jump, imm_src, result_src}    = {1'b1, 1'b1, IMM_J, RS_PC4}; // CRITICAL FIX: JAL writes PC+4
            OPC_JALR:   {reg_write, jump, alu_src, imm_src, result_src} = {1'b1, 1'b1, 1'b1, IMM_I, RS_PC4}; // CRITICAL FIX: JALR writes PC+4
            OPC_LUI:    {reg_write, alu_src, imm_src}             = {1'b1, 1'b1, IMM_U};
            OPC_AUIPC:  {reg_write, alu_src, alu_src_a, imm_src}   = {1'b1, 1'b1, 1'b1, IMM_U}; // CRITICAL FIX: AUIPC uses PC
            default: begin end
        endcase
    end

endmodule

