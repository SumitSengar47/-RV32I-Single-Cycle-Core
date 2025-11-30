// alu_decoder.v
// Decodes instruction fields to generate the 4-bit ALU control signal.
// This module is the second level of a two-level control design. It takes
// the full opcode, funct3, and funct7 fields and creates the specific
// operation code that the main ALU will execute.
//
module alu_decoder (
    input  wire [6:0] opcode,      // The 7-bit opcode from the instruction (instr[6:0])
    input  wire [2:0] funct3,      // The 3-bit funct3 from the instruction (instr[14:12])
    input  wire [6:0] funct7,      // The 7-bit funct7 from the instruction (instr[31:25])
    output reg  [3:0] alu_control  // The final 4-bit control signal for the ALU
);

    // ----------------------------
    // RISC-V Opcode Constants
    // ----------------------------
    // These constants represent the unique 7-bit code for each instruction type.
    localparam OPC_LOAD    = 7'b0000011; // For LW, LB, etc.
    localparam OPC_OP_IMM  = 7'b0010011; // For I-type instructions like ADDI
    localparam OPC_AUIPC   = 7'b0010111; // Add Upper Immediate to PC
    localparam OPC_STORE   = 7'b0100011; // For SW, SB, etc.
    localparam OPC_OP      = 7'b0110011; // For R-type instructions like ADD, SUB
    localparam OPC_LUI     = 7'b0110111; // Load Upper Immediate
    localparam OPC_BRANCH  = 7'b1100011; // For BEQ, BNE, etc.
    localparam OPC_JAL     = 7'b1101111; // Jump and Link
    localparam OPC_JALR    = 7'b1100111; // Jump and Link Register

    // ----------------------------
    // ALU Control Code Constants
    // ----------------------------
    // These are the 4-bit codes our main ALU understands. This decoder's job
    // is to produce one of these codes.
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

    // A wire for bit 30 of the instruction (funct7[5]), which is used to
    // differentiate between ADD/SUB and SRL/SRA.
    wire funct7_bit5;
    assign funct7_bit5 = funct7[5];

    // Main combinational decoding logic.
    always @(*) begin
        // By default, we set the ALU to perform an ADD. This is a safe default
        // as it's used for address calculations in loads and stores.
        alu_control = ALU_ADD;

        case (opcode)
            // For R-type instructions, we need to look at funct3 and funct7
            // to determine the specific arithmetic/logical operation.
            OPC_OP: begin
                case (funct3)
                    3'b000: alu_control = (funct7_bit5) ? ALU_SUB : ALU_ADD; // ADD or SUB
                    3'b001: alu_control = ALU_SLL;                           // SLL
                    3'b010: alu_control = ALU_SLT;                           // SLT
                    3'b011: alu_control = ALU_SLTU;                          // SLTU
                    3'b100: alu_control = ALU_XOR;                           // XOR
                    3'b101: alu_control = (funct7_bit5) ? ALU_SRA : ALU_SRL; // SRL or SRA
                    3'b110: alu_control = ALU_OR;                            // OR
                    3'b111: alu_control = ALU_AND;                           // AND
                    default: alu_control = ALU_ADD; // Should not be reached
                endcase
            end

            // For I-type instructions, we only need to look at funct3.
            OPC_OP_IMM: begin
                case (funct3)
                    3'b000: alu_control = ALU_ADD;                           // ADDI
                    3'b001: alu_control = ALU_SLL;                           // SLLI
                    3'b010: alu_control = ALU_SLT;                           // SLTI
                    3'b011: alu_control = ALU_SLTU;                          // SLTIU
                    3'b100: alu_control = ALU_XOR;                           // XORI
                    3'b101: alu_control = (funct7_bit5) ? ALU_SRA : ALU_SRL; // SRLI or SRAI
                    3'b110: alu_control = ALU_OR;                            // ORI
                    3'b111: alu_control = ALU_AND;                           // ANDI
                    default: alu_control = ALU_ADD; // Should not be reached
                endcase
            end

            // For loads, stores, and JALR, the ALU is always used to
            // calculate an address by performing an addition.
            OPC_LOAD, OPC_STORE, OPC_JALR: begin
                alu_control = ALU_ADD;
            end

            // For all branches, the ALU performs a subtraction to generate
            // the flags (zero, negative) needed to make the branch decision.
            OPC_BRANCH: begin
                alu_control = ALU_SUB;
            end

            // For LUI and AUIPC, we assign a unique ALU control code.
            OPC_LUI: begin
                alu_control = ALU_LUI;
            end
            OPC_AUIPC: begin
                alu_control = ALU_AUIPC;
            end

            // For JAL, the ALU is used to calculate the target address,
            // which is an addition (pc + imm).
            OPC_JAL: begin
                alu_control = ALU_ADD;
            end

            // If the opcode is not recognized, default to ADD.
            default: begin
                alu_control = ALU_ADD;
            end
        endcase
    end

endmodule

