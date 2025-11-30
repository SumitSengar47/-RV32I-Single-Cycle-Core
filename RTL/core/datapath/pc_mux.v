// pc_mux.v
// This module implements the main Program Counter (PC) multiplexer.
// It acts as a switch, selecting the address of the next instruction based on
// the 'pc_src' control signal.

module pc_mux #(
    // This parameter makes the module's data width configurable.
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] pc_plus4,   // Input 0: The next sequential address (PC + 4).
    input  wire [WIDTH-1:0] pc_target,  // Input 1: The target address for a branch or jump.
    input  wire               pc_src,     // Select signal: 0 chooses pc_plus4, 1 chooses pc_target.
    output wire [WIDTH-1:0] pc_next     // The selected address for the next PC value.
);

  
    // The ternary operator is a concise way to describe this selection logic.
    assign pc_next = pc_src ? pc_target : pc_plus4;

endmodule

