`timescale 1ns / 1ps

/**
 * Module: tb_top
 * Description: Top-level testbench for the CPU and Video Console.
 * Automatically runs the processor, monitors the VSync pulse, and dumps 
 * the contents of the Video RAM into .ppm image files to generate a video sequence.
 */
module tb_top();

    // System Signals
    logic sys_clock;
    logic reset;
    logic [3:0] buttons_in;
    
    // VGA Physical Pins (Monitored but not explicitly used for saving images here)
    logic hsync, vsync;
    logic [3:0] vga_r, vga_g, vga_b;

    // Instantiate the Device Under Test (DUT)
    top dut (
        .sys_clock(sys_clock),
        .reset(reset),
        .buttons_in(buttons_in),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    // Clock Generation (100 MHz)
    initial begin
        sys_clock = 0;
        forever #5 sys_clock = ~sys_clock; 
    end

    // Variables for File Saving and Image Generation
    integer file_desc;
    integer x, y, block_x, block_y, vram_index;
    logic [1:0] pixel_color;
    integer r, g, b; // Red, Green, Blue channels for the PPM file
    
    integer frame_count = 0;
    logic prev_vsync_pulse = 0;
    string filename;

    /**
     * Frame Capture Logic:
     * Triggers at every VSYNC pulse (end of a drawn frame) to read the VRAM 
     * and save it as a 640x480 Netpbm color image (.ppm).
     */
    always_ff @(posedge sys_clock) begin
        prev_vsync_pulse <= dut.vsync_pulse;
        
        // Detect the rising edge of vsync_pulse (indicates a completed frame)
        if (dut.vsync_pulse == 1'b1 && prev_vsync_pulse == 1'b0) begin
            frame_count++;
            
            // Format filename with zero-padding (e.g., frames/frame_0001.ppm)
            filename = $sformatf("frames/frame_%04d.ppm", frame_count);
            file_desc = $fopen(filename, "w");
            
            if (file_desc) begin
                // Write PPM Header: Magic Number (P3), Width, Height, Max Color Value
                $fdisplay(file_desc, "P3\n640 480\n255");
                
                // Iterate through every pixel on the 640x480 screen
                for (y = 0; y < 480; y++) begin
                    for (x = 0; x < 640; x++) begin
                        // Map the 640x480 resolution to the 40x30 VRAM grid (16x16 blocks)
                        block_x = x / 16;
                        block_y = y / 16;
                        vram_index = (block_y * 40) + block_x;
                        
                        // Extract color code from the DUT's VRAM
                        pixel_color = dut.vga_inst.vga_vram.vram[vram_index];
                        
                        // Map 2-bit VRAM codes to 8-bit RGB values for the image file
                        case(pixel_color)
                            2'b00: begin r = 0;   g = 0;   b = 150; end // Background: Blue
                            2'b01: begin r = 0;   g = 200; b = 0;   end // Snake Body: Green
                            2'b10: begin r = 50;  g = 255; b = 50;  end // Snake Head: Bright Green
                            2'b11: begin r = 255; g = 0;   b = 0;   end // Random Apple: Red
                            default: begin r = 0; g = 0; b = 0; end
                        endcase
                        
                        // Write the RGB pixel to the file
                        $fdisplay(file_desc, "%0d %0d %0d", r, g, b);
                    end
                end
                $fclose(file_desc);
                $display("Time=%0t | Frame saved: %s", $time, filename);
            end else begin
                // Failsafe if the directory is missing
                $display("ERROR: Could not create %s. Did you create the 'frames' folder in your simulation directory?", filename);
                $finish;
            end
            
            // Stop simulation after capturing exactly 60 frames (1 second of 60Hz video)
            if (frame_count == 60) begin
                $display("=== Success! 60 frames generated. ===");
                $finish;
            end
        end
    end

    // Reset and Initialization Sequence
    initial begin
        reset = 1'b1;
        buttons_in = 4'b0000;
        
        #100; // Hold reset for 100ns
        reset = 1'b0;
    end

endmodule