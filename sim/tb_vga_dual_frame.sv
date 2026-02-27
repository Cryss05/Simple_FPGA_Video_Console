`timescale 1ns / 1ps

module tb_vga_dual_frame();

    logic sys_clock = 0;
    logic reset;
    logic cpu_we;
    logic [10:0] cpu_addr;
    logic [1:0] cpu_data;
    logic vsync_ready;
    logic hsync, vsync;
    logic [3:0] vga_r, vga_g, vga_b;

    // Clock generating (100 MHz)
    always #5 sys_clock = ~sys_clock;

    vga_controller dut (.*); 

    // Task to fill the all screen with one color
    task fill_vram(input logic [1:0] color);
        for (int i = 0; i < 1200; ++i) begin
            @(posedge sys_clock);
            cpu_we = 1;
            cpu_addr = i;
            cpu_data = color;
        end
        @(posedge sys_clock);
        cpu_we = 0;
    endtask

    // Simulation control
    initial begin
        reset = 1;
        cpu_we = 0;
        #100 reset = 0;
    
        // After reset is off we start writing in the VRAM
        $display("Frame 1: Blue Blackground...");
        fill_vram(2'b00); 
        
        // Waiting for VGA controller to finish writing in VRAM
        wait(vsync_ready); 
        $display("vsync_ready detected! We are now in between frames pause.");

        // (V-Blank) 
        // Writing a frame with the Snake and Apple
        $display("Frame 2: Snake + Apple on the screen");
        for (int j = 565; j < 574; ++j) begin
            @(posedge sys_clock);
            cpu_we = 1;
            cpu_addr = j;
            cpu_data = 2'b01; // Green
        end
        
        @(posedge sys_clock);
        cpu_we = 1;
        cpu_addr = 575;
        cpu_data = 2'b11; // Red
        
        @(posedge sys_clock);    
        cpu_we = 0;

        // Waiting for the second frame to be ready
        @(posedge vsync_ready);
        $display("Second frame finished. Simulation done.");
        $finish;
    end

    // Logic of creating the PPM files
    int frame_count = 1;
    int fd;
    string filename;

    int pixels_written;

    initial begin

        wait(reset == 0);
  
        forever begin
            $sformat(filename, "../../../../../results/frame%0d.ppm", frame_count);
            fd = $fopen(filename, "w");
            $fwrite(fd, "P3\n640 480\n15\n");
            
            pixels_written = 0;

            // We collect the exact number of pixels 
            while (pixels_written < 307200) begin
                @(posedge sys_clock);
                if (dut.clock_25MHz_en && dut.vga_vram.video_on_r2) begin
                    $fwrite(fd, "%0d %0d %0d ", vga_r, vga_g, vga_b);
                    pixels_written++;
                end
            end

            $fclose(fd);
            $display("Saved %s (%0d pixels)", filename, pixels_written);
            frame_count++;

            if (frame_count > 2) $finish;
            
            // Waiting for the next frame before restarting the loop
            @(posedge vsync_ready);
        end
    end

endmodule