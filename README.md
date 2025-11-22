# ⚡ Basys3 Floating-Point ALU (FP32) – VHDL Project

This FPGA project implements a **floating-point arithmetic logic unit (ALU)** using the **IEEE-754 single-precision (FP32)** format on the **Digilent Basys3** development board.  
The design supports real-time floating-point multiplication and division, binary/decimal conversion, and 7-segment display output — all written in **pure VHDL**.

It demonstrates modular hardware design, pipelined arithmetic units, debounced inputs, real-time register loading, and FPGA-driven display formatting.

---

## 🚀 Features

- 🧮 **FP32 Floating-Point ALU**  
  Complete ALU with support for **multiplication** and **division**, using dedicated arithmetic cores.

- 🔢 **IEEE-754 ↔ BCD Conversion**  
  Convert binary floating-point numbers into human-readable BCD for displaying on 7-segment digits.

- 🎛️ **Debounced Inputs**  
  Clean, stable button input using a custom *debouncer* module for Basys3 mechanical switches.

- 📟 **7-Segment Display Driver**  
  Fully multiplexed display for 4-digit output, showing BCD-formatted results from arithmetic operations.

- 🧱 **Modular Architecture**  
  Each functionality is implemented as an independent VHDL module (IEEE conversion, ALU core, arithmetic cores, registers, decoder, etc.).

- 🔗 **Top-Level Integration**  
  The `main_basys3.vhd` file ties the entire system to Basys3 switches, buttons, clock, and display.

- 📐 **Synchronized with XDC constraints**  
  The project includes the full pin-mapping file (`basys3_main.xdc`) fully compatible with Xilinx Vivado.

---

## 🧰 Technologies Used

- **VHDL 2008** – Hardware description and design  
- **Xilinx Vivado** – Synthesis, simulation, implementation, and programming  
- **IEEE-754 Standard** – Floating-point arithmetic format  
- **Basys3 FPGA Board (Artix-7 XC7A35T-1CPG236C)**  
- **7-Segment Display Multiplexing**  
- **Debouncing Logic** for mechanical inputs  
- **Pipelined Arithmetic Units** (division & multiplication cores)

---

## 🛠️ Project Overview

The system processes floating-point numbers using a custom-designed ALU:

### **Core modules**
- `alu_fp32.vhd` – Top arithmetic unit; selects multiplication/division; routes signals  
- `multiplication_core.vhd` – Performs FP32 multiplication  
- `division_core.vhd` – Performs FP32 division  
- `multiplication_ieee.vhd` / `division_ieee.vhd` – Wrapper modules for IEEE-754 compliance  

### **Conversion modules**
- `bcd_to_ieee.vhd` – Converts BCD inputs to IEEE-754 floating point  
- `ieee_to_bcd.vhd` – Converts internal binary FP32 results into BCD for display  

### **User-interface modules**
- `sevenseg_bcd4.vhd` – 4-digit 7-segment display multiplexer  
- `number_register.vhd` – Simple input register for operand selection  
- `debouncer.vhd` – Stabilizes button input signals  

### **Integration**
- `main_basys3.vhd` – Connects switches/buttons to the ALU and display  
- `basys3_main.xdc` – Pin constraint file for Vivado  

---

## 💻 How It Works

1. The user selects operands using Basys3 switches or incremental buttons.  
2. A debouncer ensures clean button transitions.  
3. The input BCD value is converted to IEEE-754 using `bcd_to_ieee.vhd`.  
4. The ALU (`alu_fp32.vhd`) receives two FP32 inputs and performs:  
   - ✖ Multiplication  
   - ➗ Division  
5. The result is converted back into BCD using `ieee_to_bcd.vhd`.  
6. The BCD result is displayed using `sevenseg_bcd4.vhd` on the Basys3 7-segment display.

The design uses fully synchronous logic and the Basys3 on-board 100 MHz clock, typically divided down internally.

---

## 📂 Project Structure

/src
├─ alu_fp32.vhd
├─ bcd_to_ieee.vhd
├─ debouncer.vhd
├─ division_core.vhd
├─ division_ieee.vhd
├─ ieee_to_bcd.vhd
├─ main_basys3.vhd
├─ multiplication_core.vhd
├─ multiplication_ieee.vhd
├─ number_register.vhd
└─ sevenseg_bcd4.vhd
/constraints
└─ basys3_main.xdc
README.md

Each VHDL file represents a standalone module intended for separate simulation and reuse.

---

## ▶️ How to Run the Project (Vivado)

### 1️⃣ Clone the repository
