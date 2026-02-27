`timescale 1ns / 1ps

module tb_vga_single_frame();

    logic sys_clock = 0;
    logic reset;
    logic cpu_we;
    logic [10:0] cpu_addr;
    logic [1:0] cpu_data;
    logic vsync_ready;
    
    logic hsync, vsync;
    logic [3:0] vga_r, vga_g, vga_b;

    // Clock generation (100MHz)
    always #5 sys_clock = ~sys_clock;

    vga_controller dut (
        .sys_clock(sys_clock),
        .reset(reset),
        .cpu_we(cpu_we),
        .cpu_addr(cpu_addr),
        .cpu_data(cpu_data),
        .vsync_ready(vsync_ready),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );


    initial begin
        reset = 1;
        cpu_we = 0;
        cpu_addr = 0;
        cpu_data = 0;
        
        #100 reset = 0;

        // Writing the image in VRAM
        $display("Loading data in VRAM...");
        
        // Color pattern of all possible combinations
        for (int i = 0; i < 1200; i++) begin
            @(posedge sys_clock);
            cpu_we = 1;
            cpu_addr = i;
            if(i%4 == 0) begin
                cpu_data = 2'b01;
            end
            else if(i%4 == 1) begin
                cpu_data = 2'b00;
            end
            
            else if(i%4 == 2) begin
                cpu_data = 2'b10;
            end
            
            else if(i%4 == 3) begin
                cpu_data = 2'b11;
            end
        end
        
        @(posedge sys_clock);
        cpu_we = 0;

        $display("Data loaded. Starting frame capture...");
                
        @(posedge vsync_ready); // waiting for all frame to be generated
        
        $display("Simulation ready. Check output_image.ppm");
        $finish;
    end

    // PPM writing logic
    int fd;
    initial begin
        fd = $fopen("../../../../../results/output_image.ppm", "wb");
        // Header PPM: P3 (text), 640x480, 255 (max color)
        $fwrite(fd, "P3\n640 480\n15\n"); 
        
        forever begin
            @(posedge sys_clock);
            // If we are in the display area we capture the RGB signal
            if (dut.clock_25MHz_en && dut.vga_vram.video_on_r2) begin
                $fwrite(fd, "%0d %0d %0d ", vga_r, vga_g, vga_b);
            end
            
            if (dut.clock_25MHz_en && dut.vga_sync_unit.hcnt == 799) begin
                $fwrite(fd, "\n");
            end
        end
    end

endmodule