`timescale 1ns / 1ps

module top(
    input  logic sys_clock,
    input  logic reset,
    
    // Physical Input Buttons
    input  logic [3:0] buttons_in,
    
    // VGA Interface Outputs
    output logic hsync,
    output logic vsync,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);    

    // ==========================================
    // Wires & Buses Internal Connections
    // ==========================================

    // Program Counter (PC) & Instruction Memory Wires
    logic [15:0] pc_out;
    logic [31:0] current_instruction;
    logic        pc_en;
    logic        do_jump;
    logic [15:0] jump_value;
    
    // Instruction Decoding (New format with full 16-bit Immediate)
    logic [ 3:0] opcode;
    logic [ 3:0] rA;           // Source Operand 0 Register
    logic [ 3:0] rB;           // Source Operand 1 Register
    logic [ 3:0] rD;           // Destination Register
    logic [ 3:0] alu_func;
    logic [15:0] imm_value;    // 16-bit Immediate value or ALU Function selection
    
    // Instruction Format: 
    // [31:28] Opcode | [27:24] rA | [23:20] rB | [19:16] rD | [15:0] Imm / Func
    assign opcode     = current_instruction[31:28];
    assign rA         = current_instruction[27:24];
    assign rB         = current_instruction[23:20];
    assign rD         = current_instruction[19:16];
    
    assign imm_value  = current_instruction[15:0]; 
    assign jump_value = current_instruction[15:0]; 
    
    // Extract alu_func from the last 4 bits of the immediate field 
    // (Used exclusively by control_block when opcode == 1)
    assign alu_func   = current_instruction[3:0]; 

    // System Data Bus Wires
    logic [15:0] proc_addr;
    logic [15:0] proc_data_out;
    logic        proc_mem_w_en;
    logic [15:0] proc_data_in;
    
    // RAM Interface Wires
    logic [15:0] ram_addr;
    logic [15:0] ram_data_out;
    logic        ram_w_en;
    logic [15:0] ram_data_in;
    
    // VGA Subsystem Wires
    logic [15:0] vga_addr;
    logic [15:0] vga_data;
    logic        vga_w_en;
    logic        vsync_pulse;
    
    // Input Buffer & LFSR Randomizer Wires
    logic [ 3:0] buttons_data;
    logic [15:0] buttons_data_ext; 
    logic        btn_read_en;
    logic [15:0] lfsr_rand_val;
    
    // RALU & Control Unit Interconnects
    logic        w_en;
    logic [ 3:0] alu_op_sel;
    logic        alu_src;
    logic [ 1:0] reg_write_src;
    logic [15:0] operand0;
    logic [15:0] operand1;
    logic [15:0] alu_result;
    logic        zero_flag;
    logic        data_mem_w_en;

    // Direct Bus-to-Processor Connections
    assign proc_addr        = alu_result;   
    assign proc_data_out    = operand1;    
    assign proc_mem_w_en    = data_mem_w_en;
    assign buttons_data_ext = {12'b0, buttons_data}; // Zero-extend 4-bit input to 16-bit bus

    // Read Enable Logic for Input Buffer FIFO
    // Triggered when CPU reads from specific I/O address 0xF000
    assign btn_read_en = (proc_addr == 16'hF000) && (w_en == 1'b1) && (reg_write_src == 2'b01);

    // ==========================================
    // Submodule Instantiations
    // ==========================================

    // Program Counter Logic
    program_counter pc_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .pc_en(pc_en),
        .do_jump(do_jump),
        .jump_value(jump_value),
        .pc(pc_out)
    );

    // Instruction Memory (ROM)
    instr_mem imem_inst(
        .sys_clock(sys_clock),
        .addr_read(pc_out),
        .data_read(current_instruction)
    );

    // Main Control Unit (FSM)
    control_block ctrl_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .opcode(opcode),
        .alu_func(alu_func),
        .zero_flag(zero_flag),
        .vsync_pulse(vsync_pulse),
        .pc_en(pc_en),
        .do_jump(do_jump),
        .w_en(w_en),
        .alu_op_sel(alu_op_sel),
        .alu_src(alu_src),
        .reg_write_src(reg_write_src),
        .data_mem_w_en(data_mem_w_en)
    );

    // Register File + ALU Unit (RALU)
    ralu ralu_inst(
        .sys_clock(sys_clock),
        .w_en(w_en),
        .addr_operand0(rA),
        .addr_operand1(rB),
        .addr_result(rD),
        .instr_value(imm_value),
        .data_mem_data_read(proc_data_in),
        .rand_value(lfsr_rand_val),
        .alu_op_sel(alu_op_sel),
        .alu_src(alu_src),
        .reg_write_src(reg_write_src),
        .operand0(operand0),
        .operand1(operand1),
        .result(alu_result),
        .zero_flag(zero_flag)
    );

    // System Bus Address Decoder & Multiplexer
    system_bus bus_inst(
        .proc_addr(proc_addr),
        .proc_data_out(proc_data_out),
        .proc_mem_w_en(proc_mem_w_en),
        .proc_data_in(proc_data_in),
        .ram_addr(ram_addr),
        .ram_data_out(ram_data_out),
        .ram_w_en(ram_w_en),
        .ram_data_in(ram_data_in),
        .vga_addr(vga_addr),
        .vga_data(vga_data),
        .vga_w_en(vga_w_en),
        .buttons_data(buttons_data_ext)
    );

    // General Purpose Data RAM
    data_mem dmem_inst (
        .sys_clock(sys_clock),
        .mem_w_en(ram_w_en),
        .addr_read(ram_addr),
        .data_write(ram_data_out),
        .data_read(ram_data_in)
    );

    // Input Controller with Debouncing and FIFO
    input_controller input_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .buttons_in(buttons_in),
        .cpu_read_en(btn_read_en),
        .data_to_cpu(buttons_data)
    );

    // Video Subsystem (VRAM & Timing)
    vga_controller vga_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .cpu_we(vga_w_en),
        .cpu_addr(vga_addr[10:0]),  // Maps addresses 0 to 1199 for 40x30 grid
        .cpu_data(vga_data[1:0]),   // 2-bit color data (4 color palette)
        .vsync_ready(vsync_pulse),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    // Hardware Random Number Generator (LFSR)
    lfsr16 rand_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .rand_out(lfsr_rand_val)
    );

endmodule