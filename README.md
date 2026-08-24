# Parameterizable Hardware Multiplier Unit

## Overview
A multi-cycle sequential hardware multiplier written in standard Verilog-2001. Rather than utilizing a large, purely combinational array multiplier (which consumes massive silicon area and dictates long critical paths), this module implements a **Shift-and-Add Architecture**. 

The design processes mathematical multiplication sequentially over `N` clock cycles (where `N` is the parameterizable width of the operands), making it ideal for integration into high-frequency CPU datapaths with strict area constraints.

## Architecture Highlights
* **Shift-and-Add Algorithm:** Evaluates the Least Significant Bit (LSB) of the multiplier operand (`a_reg`) every clock cycle. If the bit is `1`, the shifted multiplicand (`b_shifted`) is added to the accumulator. Both operands are then shifted for the next evaluation cycle.
* **Finite State Machine (FSM) Control:** Features an internal FSM (`IDLE`, `CALC`, `FIN`) that orchestrates the multi-cycle mathematical sequence.
* **Handshake Protocol:** Includes `start`, `busy`, and `done` control signals to interface seamlessly with external CPU pipeline stall controllers.
* **Parameterizable Width:** Designed with a default 16-bit datapath (`WIDTH=16`), but can be easily scaled up or down via instantiation parameters.

## Verification
An automated Verilog testbench (`multiplier_tb.v`) is provided to validate the algorithmic hardware against the following conditions:
1. **Basic Multiplication:** Confirms standard integer scaling.
2. **Zero Operand Handling:** Ensures multiplication by zero correctly evaluates to zero.
3. **Maximum Boundary Value:** Tests the limits of the operand width (`255 * 255`).
4. **Back-to-Back Saturation:** Issues continuous `start` pulses to verify the FSM transitions from `FIN` directly back into `CALC` without requiring an `IDLE` penalty cycle.
