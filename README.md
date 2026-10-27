# APB Master Protocol Using Verilog HDL

## 1. Project Overview

The **Advanced Peripheral Bus (APB)** is a part of the **Advanced Microcontroller Bus Architecture (AMBA)** developed by Arm. It is designed for simple, low-power communication between a processor or bus master and peripheral devices.

APB is commonly used to connect peripherals such as UART controllers, GPIO modules, timers, and control registers. Unlike high-performance protocols such as AXI, APB uses a simple, non-pipelined transfer mechanism that is easy to implement and verify.

This project implements an **FSM-based APB Master using Verilog HDL** and AMD Xilinx Vivado. The master controls read and write transactions by generating the required APB control signals and following the protocol's setup and access phases.

The design focuses on protocol sequencing, finite state machine implementation, wait-state handling, and RTL simulation.

### Objectives

- Understand the fundamentals of the AMBA APB protocol.
- Design an APB Master using Verilog HDL.
- Implement the APB transaction sequence using an FSM.
- Generate address, control, and write-data signals.
- Handle peripheral wait states using `PREADY`.
- Verify read and write transactions through RTL simulation.

## 2. Design Specifications

| Parameter | Description |
|---|---|
| Project | APB Master Protocol |
| Protocol | AMBA APB |
| Design type | FSM-based bus master |
| HDL | Verilog HDL |
| EDA tool | AMD Xilinx Vivado |
| Transfer types | Read and write |
| Transaction phases | Setup and access |
| Wait-state handling | `PREADY` |
| Verification | RTL simulation and waveform analysis |

The exact APB version and supported features depend on the implementation. This project focuses on the basic APB transaction mechanism.

## 3. Understanding the AMBA APB Protocol

AMBA is a family of on-chip communication protocols used to connect functional blocks within a System-on-Chip (SoC).

Different AMBA protocols serve different purposes:

- **APB:** Simple, low-bandwidth peripheral communication.
- **AHB:** Higher-performance transfers for systems requiring more bandwidth.
- **AXI:** High-performance, channel-based communication supporting independent address and data channels.

APB is suitable for peripherals that do not require high throughput. Its simple transfer mechanism reduces control complexity and makes it useful for register accesses.

### APB Architecture

A typical APB system consists of:

- **APB Master:** Initiates a read or write transaction and generates the control signals.
- **APB Slave:** Responds to the transaction and provides read data or accepts write data.
- **Address and data buses:** Carry the address, write data, and read data.
- **Control signals:** Coordinate selection, transfer phase, direction, and completion.

In this project, the APB Master is implemented in RTL, while the slave response can be modeled in a testbench for simulation.

## 4. APB Interface Signals

| Signal | Direction from Master perspective | Function |
|---|---|---|
| `PCLK` | Input | APB clock |
| `PRESETn` | Input | Active-low reset |
| `PADDR` | Output | Address of the peripheral register |
| `PSEL` | Output | Selects the target peripheral |
| `PENABLE` | Output | Indicates the access phase |
| `PWRITE` | Output | `1` for write, `0` for read |
| `PWDATA` | Output | Data to be written |
| `PRDATA` | Input | Data returned by the slave |
| `PREADY` | Input | Indicates completion of the access |
| `PSLVERR` | Input | Indicates an error response, when supported |

The precise signal set depends on the APB version and design requirements. `PSLVERR` is optional in implementations that support error signaling.

## 5. APB Transfer Mechanism

An APB transfer normally proceeds through two main phases: **Setup** and **Access**.

### A. Setup Phase

During setup:

- The master selects the target peripheral by asserting `PSEL`.
- The master places the required address on `PADDR`.
- The master sets `PWRITE` to indicate a read or write.
- For a write transaction, the master places the write data on `PWDATA`.
- `PENABLE` remains low.

This phase establishes the transaction information before the access phase begins.

### B. Access Phase

During access:

- `PSEL` remains asserted.
- The master asserts `PENABLE`.
- The address, direction, and write data remain stable throughout the transfer.
- The slave indicates completion by asserting `PREADY`.

If `PREADY` is low, the access phase continues for additional wait cycles. When `PREADY` becomes high at the active clock edge, the transfer completes.

After completion, the master can return to the idle state or begin another transfer according to its design.

### Example Transaction

```text
Clock Cycle:   C1       C2       C3       C4
Phase:        SETUP    ACCESS   ACCESS   IDLE
PSEL:           1        1        1        0
PENABLE:        0        1        1        0
PREADY:         X        0        1        X
Transfer:    Prepare   Wait     Complete   Done
```

Here, the slave inserts one wait cycle by keeping `PREADY` low during the first access cycle. The transfer completes when `PREADY` is high during the next access cycle.

`X` represents a signal value that is not relevant to the example, rather than a required logic value.

## 6. FSM-Based APB Master Design

The APB Master uses a Finite State Machine to control the sequence of protocol operations.

A basic implementation can use three states:

- **IDLE:** Waits for a transaction request and prepares the master for a new transfer.
- **SETUP:** Asserts `PSEL` and establishes the address, transfer direction, and write data.
- **ACCESS:** Asserts `PENABLE` and waits for the slave to complete the transaction.

### State Transition Concept

| Current state | Condition | Next state |
|---|---|---|
| IDLE | No request | IDLE |
| IDLE | New request | SETUP |
| SETUP | Setup cycle completed | ACCESS |
| ACCESS | `PREADY = 0` | ACCESS |
| ACCESS | `PREADY = 1` | IDLE or next transaction |

The key protocol requirement is that the master must not leave the access phase until the transfer completes. When `PREADY` is low, the access phase and required transfer information are maintained.

### RTL Design Structure

A typical implementation contains:

1. **State register:** Stores the current FSM state and updates on the clock edge.
2. **Next-state logic:** Determines whether the master should remain idle, enter setup, or continue in access.
3. **Output logic:** Generates `PSEL`, `PENABLE`, `PADDR`, `PWRITE`, and `PWDATA` according to the current transaction.

The state register is commonly implemented using a clocked `always` block, while next-state logic uses combinational logic.

The exact request interface, reset style, and output assignments depend on the project's RTL implementation.

## 7. Read and Write Transactions

### Write Transaction

In a write transaction, the master transfers data to the selected peripheral.

1. The master receives a write request.
2. It places the target address on `PADDR`.
3. It asserts `PSEL` during setup.
4. It sets `PWRITE = 1` and drives the write data on `PWDATA`.
5. It asserts `PENABLE` during access.
6. It waits until `PREADY` is high.
7. The transfer completes, and the master returns to idle or proceeds to the next transaction.

### Read Transaction

In a read transaction, the master retrieves data from the selected peripheral.

1. The master receives a read request.
2. It places the target address on `PADDR`.
3. It selects the peripheral during setup.
4. It sets `PWRITE = 0`.
5. It asserts `PENABLE` during access.
6. It waits for `PREADY` to indicate completion.
7. It captures or makes available `PRDATA` at the appropriate transfer-completion point.

Correct read-data capture depends on the implementation and must follow the protocol timing.

## 8. Simulation and Verification

RTL simulation verifies whether the APB Master generates valid protocol signals and responds correctly to the slave.

A testbench can model a peripheral by controlling `PREADY`, providing `PRDATA`, and checking the master's output signals.

### Recommended Test Cases

| Test case | Expected behavior |
|---|---|
| Reset | FSM enters IDLE and outputs return to their defined reset values |
| Write transaction | Correct address, write direction, and write data are generated |
| Read transaction | Correct address and read direction are generated |
| Normal transfer | Transfer completes when `PREADY` is high during access |
| Wait-state handling | Master remains in ACCESS while `PREADY` is low |
| Read-data capture | Correct `PRDATA` is sampled at transfer completion |
| Back-to-back requests | Subsequent transactions follow valid APB phase sequencing |

### Important Signals to Observe

- `PCLK` and `PRESETn`
- `PADDR` and `PWRITE`
- `PSEL` and `PENABLE`
- `PWDATA` and `PRDATA`
- `PREADY`
- FSM state

Waveform analysis helps identify incorrect phase sequencing, unstable transaction information, premature completion, and wait-state handling errors.

## 9. Applications

The APB protocol is commonly used for communication with:

- UART and serial communication controllers.
- GPIO and input/output control registers.
- Timers and counters.
- Interrupt controllers.
- Configuration and status registers.
- Low-bandwidth peripherals in SoC designs.

