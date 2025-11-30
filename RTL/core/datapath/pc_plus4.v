// pc_plus4.v
// This module is a simple combinational adder that calculates PC + 4.
// This value represents the address of the next sequential instruction,
// as each RISC-V instruction is 4 bytes long.

module pc_plus4 #(
    // This parameter makes the module's data width configurable.
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] pc,       // The current Program Counter value.
    output wire [WIDTH-1:0] pc_plus4  // The calculated PC + 4 value.
);

    // This is a single, continuous assignment that performs the addition.
   
    assign pc_plus4 = pc + 4;

endmodule

