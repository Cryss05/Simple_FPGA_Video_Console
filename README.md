# Simple FPGA Video Console (16-bit RISC CPU)

A complete, custom 16-bit RISC CPU and Retro Video Console implemented from scratch in **SystemVerilog**. This project includes a custom Instruction Set Architecture (ISA), a memory-mapped VGA controller and a hardware input debouncing system.

![System Architecture](https://img.shields.io/badge/Architecture-16--bit_RISC-blue)
![Language](https://img.shields.io/badge/Language-SystemVerilog-green)
![VGA](https://img.shields.io/badge/Display-VGA_640x480-orange)

https://github.com/user-attachments/assets/e347b8c2-a644-4cce-86cc-2ef14ce79e41
* This is only a demo, actual Snake gameplay soon to be implemented!

## Key Features

* **Custom 16-bit RISC CPU**: A multi-cycle architecture coordinated by a Finite State Machine (FSM). This allows for stable synchronous memory accesses (ROM/RAM) and features a full ALU supporting signed/unsigned arithmetic and bitwise operations.
* **Harvard Architecture (Dedicated ROM):** Separate memory spaces and buses for instructions and data. The Instruction Memory (ROM) is a synchronous 16K $\times$ 32-bit block that automatically initializes from an external `program.hex` file.
* **Memory-Mapped I/O (MMIO):** Seamless integration of peripherals using unified address decoding.
* **VGA Controller:** Generates industry-standard 640x480 @ 60Hz VGA timing. Features a tile-based rendering engine ($40 \times 30$ grid) with a 4-color palette.
* **Robust Input Controller:** Hardware debouncing (10ms filter), rising-edge detection, and asynchronous FIFO queuing for 4 physical buttons.
* **Hardware RNG:** 16-bit Linear Feedback Shift Register (LFSR) for single-cycle pseudo-random number generation (crucial for game logic like spawning items).
* **Simulation-to-Video Testbench:** A SystemVerilog testbench (`tb_top.sv`) that dumps VRAM states at every V-Blank directly into `.ppm` image sequences.

## System Memory Map

The system uses a 16-bit address bus, managed by the `system_bus` module to route CPU read/write requests to the appropriate subsystems:

| Address Range | Size | Subsystem | Description |
| :--- | :--- | :--- | :--- |
| `0x0000` - `0x7FFF` | 32 KB | **General RAM** | Standard synchronous data memory for variables and game state. |
| `0x8000` - `0x8FFF` | 4 KB | **Video RAM (VRAM)** | Dual-ported memory. Addresses `0` to `1199` map to the 40x30 screen grid. Uses 2-bit color codes. |
| `0xF000` | 1 Word | **Input Buffer** | Read-only MMIO port. Pops the oldest valid button press from the hardware FIFO. |

## Video Architecture (Tile-Based)

To maintain a retro aesthetic and conserve FPGA Block RAM, the video pipeline uses a **Tile-Based approach**:
1. The physical screen resolution is **640x480**.
2. The hardware logically divides this into a **$40 \times 30$ grid**.
3. Each "tile" is a $16 \times 16$ pixel block.
4. The CPU writes a 2-bit color code (00, 01, 10, or 11) to a specific tile address in VRAM, and the VGA controller maps it to a 12-bit physical color via a hardware Look-Up Table (LUT).

## Getting Started & Simulation

You do not need an actual FPGA board to see the console in action. The provided testbench automatically executes the compiled machine code (`program.hex`) and dumps the visual output frame-by-frame.

### 1. Run the Simulation
Run `tb_top.sv` in your preferred SystemVerilog simulator (e.g., Vivado). 
* **Important:** Ensure you create an empty folder named `frames/` in your simulation run directory.
* The testbench will execute the CPU logic and capture 60 frames (1 second of video) as `.ppm` files.

### 2. Generate the Video (FFmpeg)
Once the `.ppm` frames are generated, navigate to the `frames/` directory in your terminal and use **FFmpeg** to stitch them into a high-quality, web-ready `.mp4` video:

```bash
ffmpeg -framerate 60 -i frame_%04d.ppm -c:v libx264 -pix_fmt yuv420p demo_video.mp4
