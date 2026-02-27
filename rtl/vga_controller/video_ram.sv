`timescale 1ns / 1ps

/**
 * Module: video_ram
 * Description: Implements the Video RAM (VRAM) and color palette logic. 
 * It manages simultaneous access: the CPU writes game data while the VGA 
 * controller reads pixel data to generate the monitor signals.
 */
module video_ram(
        input  logic sys_clock,      // 100MHz System Clock
        input  logic clock_25MHz_en, // 25MHz Pixel Clock Enable
        input  logic reset,          // Active high reset
        
        // CPU Interface (Write Port)
        input  logic cpu_we,         // Write Enable from CPU
        input  logic [10:0] cpu_addr,// Address for the 40x30 grid (0-1199)
        input  logic [1:0] cpu_data, // 2-bit color code from CPU
        
        // VGA Interface (Read Port)
        input  logic [9:0] x,        // Current horizontal pixel (0-639)
        input  logic [8:0] y,        // Current vertical pixel (0-479)
        input  logic video_on,       // Signal indicating active display area
        
        // Outputs to Physical VGA DAC
        output logic [3:0] vga_r,    // 4-bit Red channel
        output logic [3:0] vga_g,    // 4-bit Green channel
        output logic [3:0] vga_b     // 4-bit Blue channel
    );
    
    // VRAM storage: 1200 entries (40x30 tiles), each storing a 2-bit color code
    logic [1:0] vram [0:1199];  
    logic [10:0] read_addr;      // Calculated address for current pixel
    logic [1:0]  pixel_code;     // Color code fetched from memory
    logic [1:0]  pixel_code_r;   // Registered color code for timing alignment
    logic video_on_r1, video_on_r2; // Pipeline registers for video_on signal
    
    /**
     * Dual-Port Memory Logic:
     * Port A (CPU): Asynchronous-style write on the system clock.
     * Port B (VGA): Synchronous read on the 25MHz pixel clock enable.
     */
    always_ff @(posedge sys_clock) begin
        // CPU Write Path
        if(cpu_we) begin
            vram[cpu_addr] <= cpu_data;
        end
        
        // VGA Read Path
        if(clock_25MHz_en) begin
            pixel_code <= vram[read_addr];
        end
    end
     
    /**
     * Pipeline Synchronization:
     * Aligns the 'video_on' signal with the data latency of the VRAM.
     * Ensures colors are only displayed when the VGA counters are in the valid region.
     */
    always_ff @(posedge sys_clock) begin
        if (reset) begin
            video_on_r1  <= 1'b0;
            video_on_r2  <= 1'b0;
            pixel_code_r <= 2'b00;
        end else if (clock_25MHz_en) begin
            video_on_r1  <= video_on;
            video_on_r2  <= video_on_r1;
            pixel_code_r <= pixel_code;
        end
    end
     
    /**
     * Color Palette (Look-Up Table):
     * Maps 2-bit codes to 12-bit (4R, 4G, 4B) colors.
     */
    always_comb begin 
        if(!video_on_r2) begin 
            {vga_r, vga_g, vga_b} = 12'h000; // Blanking period (must be black)
        end else begin 
            case(pixel_code_r)
                2'b00: {vga_r, vga_g, vga_b} = 12'h003; // Background: Deep Blue
                2'b01: {vga_r, vga_g, vga_b} = 12'h0C0; // Snake Body: Green
                2'b10: {vga_r, vga_g, vga_b} = 12'h0F0; // Snake Head: Bright Green
                2'b11: {vga_r, vga_g, vga_b} = 12'hF00; // Apple: Red
                default: {vga_r, vga_g, vga_b} = 12'h000;
            endcase
        end
    end
    
    /**
     * Address Calculation Logic:
     * Maps 640x480 pixels to a 40x30 tile grid.
     * Each tile is 16x16 pixels. 
     * Formula: (y/16) * 40 + (x/16)
     * Optimization: (y >> 4) * 40 + (x >> 4) => (y[8:4] * 32 + y[8:4] * 8) + x[9:4]
     */
    assign read_addr = ((y[8:4] << 5) + (y[8:4] << 3)) + x[9:4]; 
    
endmodule