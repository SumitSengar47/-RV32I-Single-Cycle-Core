# 32-Bit Single-Cycle RISC-V Processor

![Language](https://img.shields.io/badge/Language-Verilog%20%7C%20SystemVerilog-blue)
![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-orange)
![Toolchain](https://img.shields.io/badge/Tools-Vivado%20%7C%20GTKWave-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

## 📌 Project Overview
This repository contains a fully synthesized **Register-Transfer Level (RTL)** implementation of a 32-bit Single-Cycle RISC-V Processor. Designed strictly according to the **RV32I Base Integer Instruction Set Architecture**, this core executes distinct instructions—from fetch to write-back—in a single clock cycle.

The project demonstrates a rigorous modular hardware design approach, separating the Control Unit from the Datapath, and serves as a foundational project for understanding processor microarchitecture.

## ✨ Key Features
* **ISA Compliance:** Supports the core RISC-V RV32I instruction set (Arithmetic, Logical, Memory, Branching).
* **Harvard Architecture:** Separate **Instruction Memory (IMEM)** and **Data Memory (DMEM)** interfaces.
* **Modular Design:** Hierarchical Verilog modules for easier debugging and synthesis.
* **Synthesizable:** Written in clean, synthesizable Verilog suitable for FPGA implementation (e.g., Artix-7).
* **Self-Checking Verification:** Validated using a robust testbench infrastructure.

---

## 🏗️ Architecture & Design

### 1. Conceptual Datapath
The architecture follows the standard single-cycle implementation as described in the reference textbook *Digital Design and Computer Architecture: RISC-V Edition*. The diagram below illustrates the flow of data through the Control Unit, ALU, Register File, and Memory interfaces.

![Conceptual Architecture](Architecture.png)

### 2. Vivado Design Hierarchy
The design is structured hierarchically to ensure clean separation of concerns. This structure corresponds directly to the design hierarchy used in verification and synthesis.

![Design Hierarchy](https://github.com/SumitSengar47/-RV32I-Single-Cycle-Core/blob/caaed0ea427e0660de759cfd3853167670d9ec35/schematic.png)

### 3. Synthesized Logic (RTL Schematic)
The design was successfully synthesized in Xilinx Vivado. The schematic below visualizes the gate-level implementation and the connections between the `control_unit`, `datapath_unit`, and memory modules.

![Synthesized Schematic](schematic.png)
