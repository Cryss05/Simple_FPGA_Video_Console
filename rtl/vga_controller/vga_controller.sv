`timescale 1ns / 1ps

/**
 * Module: vga_controller
 * Description: Top-level video controller that manages VGA timing and Video RAM.
 * It converts CPU drawing commands into standard VGA signals (640x480 @ 60Hz).
 */
module vga_controller(
    input  logic sys_clock,      // 100MHz System Clock
    input  logic reset,          // Active high reset
    
    // CPU Interface (Memory Mapped I/O)
    input  logic cpu_we,         // Write Enable from CPU
    input  logic [10:0] cpu_addr,// VRAM Address (0 to 1199 for 40x30 tiles)
    input  logic [1:0] cpu_data, // Color data (2-bit palette)
    output logic vsync_ready,    // Interrupt/Signal indicating Vertical Blanking
    
    // Physical VGA Pins
    output logic hsync,          // Horizontal Sync
    output logic vsync,          // Vertical Sync
    output logic [3:0] vga_r,    // 4-bit Red channel
    output logic [3:0] vga_g,    // 4-bit Green channel
    output logic [3:0] vga_b     // 4-bit Blue channel
    );
    
    // Clock Divider Signals
    // VGA 640x480 @ 60Hz requires a ~25.175MHz pixel clock.
    // 100MHz / 4 = 25MHz (sufficient for most monitors).
    logic [1:0] count_div;
    logic clock_25MHz_en;
    
    /**
     * Clock Divider:
     * Generates an enable pulse every 4 cycles of the 100MHz system clock.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            count_div <= 2'b0;
        end else begin
            count_div <= count_div + 1;
        end
    end
    
    // The enable pulse is active for one sys_clock cycle every 40ns.
    assign clock_25MHz_en = (count_div == 2'b11);
    
    // Internal timing and coordinate wires
    logic [9:0] w_x;          // Current horizontal pixel (0-799)
    logic [8:0] w_y;          // Current vertical line (0-524)
    logic w_video_on;         // High during active display area (640x480)
    
    /**
     * VGA Sync Generation:
     * Handles the counters for horizontal and vertical synchronization.
     * Provides the current X/Y pixel coordinates for the VRAM to fetch colors.
     */
    sync_generation_counters vga_sync_unit(
        .sys_clock(sys_clock),
        .clock_25MHz_en(clock_25MHz_en),
        .reset(reset),
        .hsync(hsync),     
        .vsync(vsync),  
        .x(w_x),
        .y(w_y),
        .video_on(w_video_on),
        .vsync_pulse(vsync_ready) // Signals the CPU that it is safe to update VRAM
    );
    
    /**
     * Video RAM (VRAM):
     * Dual-port logic (managed by addressing) that allows the CPU to write
     * pixel data while the VGA controller simultaneously reads data for display.
     */
    video_ram vga_vram(
        .sys_clock(sys_clock),  
        .clock_25MHz_en(clock_25MHz_en),   
        .reset(reset),         
        .cpu_we(cpu_we),            
        .cpu_addr(cpu_addr),   
        .cpu_data(cpu_data),                                                                         
        .x(w_x),           
        .y(w_y),           
        .video_on(w_video_on),       
        .vga_r(vga_r),      
        .vga_g(vga_g),      
        .vga_b(vga_b)     
    );

endmodule