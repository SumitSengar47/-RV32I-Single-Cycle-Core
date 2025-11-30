// alu_mux.v
// Simple ALU B-input multiplexer
// Selects between register operand (wd) and immediate (imm_ext)


module alu_mux #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] wd,       // register operand (rs2)
    input  wire [WIDTH-1:0] imm_ext,  // immediate, already sign/zero-extended
    input  wire             alu_src,  // select: 0 = wd (rs2), 1 = imm_ext
    output wire [WIDTH-1:0] b         // selected ALU B input
);

 
    assign b = (alu_src) ? imm_ext : wd;

endmodule
