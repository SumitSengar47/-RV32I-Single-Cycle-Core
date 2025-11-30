// pc_target.v
// This module computes the target address for PC-relative instructions
// like branches and jumps by performing a simple addition.

module pc_target #(
    // This parameter makes the module's data width configurable.
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] pc,       // The current Program Counter value.
    input  wire [WIDTH-1:0] imm_ext,  // The sign-extended immediate offset from the instruction.
    output wire [WIDTH-1:0] pc_target // The calculated target address (pc + imm_ext).
);

   
    // The wrap-around behavior needed for 2's complement arithmetic is
    // handled naturally by the fixed-width addition.
    assign pc_target = pc + imm_ext;

endmodule

