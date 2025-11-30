// single_cycle_core.v
// This is the top-level module for the processor core.
// It instantiates and connects the two main sub-blocks: the control unit and the datapath.

module single_cycle_core (
    // --- Standard Ports ---
    input  wire        clk,        // System clock.
    input  wire        reset_n,    // Active-low reset.
    input  wire [31:0] instr,      // The instruction being executed.
    input  wire [31:0] read_data,  // Data read from data memory (for loads).

    output wire [31:0] pc,         // The current program counter.
    output wire        mem_write,  // Write enable signal for data memory.
    output wire [31:0] alu_result, // The result from the ALU.
    output wire [31:0] write_data, // Data to be written to memory (from rs2).
    
    // --- Debug Ports ---
    input  wire [4:0]  dbg_reg_addr, // Address for the debug register read port.
    output wire [31:0] dbg_reg_data  // Data from the debug register read port.
);

    // --- Internal Wires ---
    // These wires connect the control unit and the datapath.
    wire        alu_src;
    wire        reg_write;
    wire        jump;
    wire        pc_src;
    wire [1:0]  result_src;
    wire [2:0]  imm_src;
    wire [3:0]  alu_control;
    
    // CRITICAL FIX 1: Add a wire for the new alu_src_a control signal.
    wire        alu_src_a;

    // CRITICAL FIX 2: Add wires to carry the ALU flags from the datapath back to the control unit.
    wire        alu_zero;
    wire        alu_carry;
    wire        alu_overflow;
    wire        alu_negative;

    // -------------------------
    // Control Unit Instantiation
    // -------------------------
    control_unit control_u (
        // Instruction fields
        .opcode     (instr[6:0]),
        .funct3     (instr[14:12]),
        .funct7     (instr[31:25]),
        
        // ALU flags (feedback from datapath)
        .alu_zero   (alu_zero),     
        .alu_carry  (alu_carry),    
        .alu_over   (alu_overflow), 
        .alu_neg    (alu_negative), 

        // Control signals (outputs to datapath)
        .result_src (result_src),
        .mem_write  (mem_write),
        .alu_src    (alu_src),
        .alu_src_a  (alu_src_a),    
        .reg_write  (reg_write),
        .jump       (jump),
        .imm_src    (imm_src),
        .alu_control(alu_control),
        .pc_src     (pc_src)
    );

    // -------------------------
    // Datapath Instantiation
    // -------------------------
    core_datapath datapath_u (
        // Standard inputs
        .clk        (clk),
        .reset_n    (reset_n),
        .instr      (instr),
        .read_data  (read_data),

        // Control signals (inputs from control unit)
        .result_src (result_src),
        .pc_src     (pc_src),
        .alu_src    (alu_src),
        .alu_src_a  (alu_src_a),   
        .reg_write  (reg_write),
        .imm_src    (imm_src),
        .alu_control(alu_control),

        // Standard outputs
        .pc         (pc),
        .alu_result (alu_result),
        .write_data (write_data),
        
        // Flag outputs (feedback to control unit)
        .zero       (alu_zero),
        .carry      (alu_carry),    
        .overflow   (alu_overflow), 
        .negative   (alu_negative), // CORRECTED: Connect to the new flag output.
        
        // Debug port passthrough
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_data(dbg_reg_data)
    );

endmodule

