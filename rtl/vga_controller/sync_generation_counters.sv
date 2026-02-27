`timescale 1ns / 1ps

/**
 * Module: sync_generation_counters
 * Description: Generates horizontal and vertical synchronization signals (HSync/VSync)
 * and active video coordinates (X, Y) for a 640x480 @ 60Hz VGA display.
 */
module sync_generation_counters(
        input  logic sys_clock,      // 100MHz System Clock
        input  logic clock_25MHz_en, // 25MHz Enable pulse
        input  logic reset,          // Active high reset
        
        output logic hsync,          // Horizontal Sync pulse (Active Low)
        output logic vsync,          // Vertical Sync pulse (Active Low)
        
        output logic [9:0] x,        // Current horizontal pixel (0 - 639)
        output logic [8:0] y,        // Current vertical line (0 - 479)
        output logic video_on,       // High during active video region
        
        output logic vsync_pulse     // Single-cycle pulse at the start of V-Blank (for CPU sync)
    );
    
    // VGA 640x480 Timing Parameters (Horizontal)
    localparam int H_SYNC  = 96;  // Sync pulse width
    localparam int H_BP    = 48;  // Back Porch
    localparam int H_VIDEO = 640; // Visible Video
    localparam int H_FP    = 16;  // Front Porch
    localparam int H_TOTAL = 800; // Total scanline width
    
    // VGA 640x480 Timing Parameters (Vertical)
    localparam int V_SYNC  = 2;   // Sync pulse width
    localparam int V_BP    = 33;  // Back Porch
    localparam int V_VIDEO = 480; // Visible Video
    localparam int V_FP    = 10;  // Front Porch
    localparam int V_TOTAL = 525; // Total frame height
    
    // Calculated start/end boundaries for active video
    localparam int H_START = H_SYNC + H_BP;       
    localparam int H_END   = H_START + H_VIDEO; 
    
    localparam int V_START = V_SYNC + V_BP;
    localparam int V_END   = V_START + V_VIDEO;
    
    logic [9:0] hcnt; // Horizontal counter (0 to 799)
    logic [9:0] vcnt; // Vertical counter (0 to 524)
    
    /**
     * Scanline and Frame Counters:
     * Increments the horizontal counter at 25MHz. When a line is finished,
     * it resets and increments the vertical counter.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            hcnt <= 10'b0;
            vcnt <= 10'b0;
        end
        else if(clock_25MHz_en) begin
            if(hcnt == H_TOTAL - 1) begin
                hcnt <= 10'b0;
                if(vcnt == V_TOTAL - 1) 
                    vcnt <= 10'b0;
                else 
                    vcnt <= vcnt + 1;
            end
            else begin
                hcnt <= hcnt + 1;
            end
        end
    end
    
    /**
     * Sync Signal Generation:
     * Generates active-low sync pulses during the designated sync intervals.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end
        else if(clock_25MHz_en) begin
            hsync <= ~(hcnt < H_SYNC);
            vsync <= ~(vcnt < V_SYNC);
        end
    end
    
    /**
     * CPU Synchronization Pulse:
     * Generates a pulse when the display reaches the end of the active video area.
     * This allows the CPU to synchronize game logic with the monitor's V-Blank interval.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            vsync_pulse <= 1'b0;
        end
        else if(clock_25MHz_en) begin
            if(vcnt == V_START + V_VIDEO && hcnt == 0) begin
                vsync_pulse <= 1'b1;
            end
            else begin
                vsync_pulse <= 1'b0;
            end
        end
    end
    
    /**
     * Coordinate and Video-On Logic:
     * Determines if the current scan position is within the visible 640x480 area.
     * Offsets the internal counters to provide relative (0,0) coordinates to the VRAM.
     */
    always_ff @(posedge sys_clock) begin
        if (reset) begin
            video_on <= 1'b0;
            x <= 10'd0;
            y <= 9'd0;
        end 
        else if(clock_25MHz_en) begin
            video_on <= ((hcnt >= H_START) && (hcnt < H_END) && (vcnt >= V_START) && (vcnt < V_END));
            x <= (hcnt >= H_START && hcnt < H_END) ? (hcnt - H_START) : 10'd0;
            y <= (vcnt >= V_START && vcnt < V_END) ? (vcnt - V_START) : 9'd0;
        end
    end
endmodule