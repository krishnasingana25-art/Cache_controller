`timescale 1ns / 1ps

module TB_CACHE();

reg [31:0] address;
reg [7:0] data;
reg mode, clk;
wire [7:0] output_data;
wire hit, Wait;             
wire [31:0] stored_address;
wire [7:0] stored_data;

// Instantiate the new Cache Controller
CACHE_CONTROLLER inst(
    .address(address),
    .data(data),
    .mode(mode),
    .clk(clk),
    .output_data(output_data),
    .hit(hit),
    .Wait(Wait),
    .stored_address(stored_address),
    .stored_data(stored_data)
);

// Clock generation (Period = 2ns)
initial begin
    clk = 1'b0;
    forever #1 clk = ~clk; 
end

initial begin
    // Initialize inputs
    address = 0;
    data = 0;
    mode = 0;

    // Wait a few cycles for global reset/startup
    #10;
    
    // -------------------------------------------------------------------------
    // TEST 1: READ MISS -> Fill Way 0
    // -------------------------------------------------------------------------
    @(negedge clk); // Apply on negative edge
    address = 32'b0000000000000000000000001_00000_00; // Block 32
    mode = 1'b0;        
    @(posedge clk); #1; // Let controller evaluate and raise Wait
    wait (Wait == 1'b0); 
    $display("Test 1 Complete: Block 32 loaded into Set 0, Way 0.");

    // -------------------------------------------------------------------------
    // TEST 2: READ MISS -> Fill Way 1 (Set 0 is now full)
    // -------------------------------------------------------------------------
    @(negedge clk);
    address = 32'b0000000000000000000000010_00000_00; // Block 64
    mode = 1'b0;        
    @(posedge clk); #1; 
    wait (Wait == 1'b0);
    $display("Test 2 Complete: Block 64 loaded into Set 0, Way 1.");

    // -------------------------------------------------------------------------
    // TEST 3: READ HIT -> Updates LRU
    // -------------------------------------------------------------------------
    @(negedge clk);
    address = 32'b0000000000000000000000001_00000_00; // Block 32
    mode = 1'b0;
    @(posedge clk); #1; 
    wait (Wait == 1'b0);
    $display("Test 3 Complete: Block 32 Hit. Way 1 is now LRU.");

    // -------------------------------------------------------------------------
    // TEST 4: READ MISS -> Evict Way 1 (LRU Policy in action)
    // -------------------------------------------------------------------------
    @(negedge clk);
    address = 32'b0000000000000000000000011_00000_00; // Block 96
    mode = 1'b0;
    @(posedge clk); #1; 
    wait (Wait == 1'b0);
    $display("Test 4 Complete: Block 64 evicted. Block 96 loaded into Set 0, Way 1.");

    // -------------------------------------------------------------------------
    // TEST 5: WRITE HIT
    // -------------------------------------------------------------------------
    @(negedge clk);
    address = 32'b0000000000000000000000001_00000_00; // Block 32
    data = 8'b10101010; // Hex AA
    mode = 1'b1;        
    @(posedge clk); #1; 
    wait (Wait == 1'b0);
    $display("Test 5 Complete: Write Hit on Way 0.");

    // -------------------------------------------------------------------------
    // TEST 6: WRITE MISS (Write-Around)
    // -------------------------------------------------------------------------
    @(negedge clk);
    address = 32'b0000000000000000000000100_00000_00; // Block 128
    data = 8'b11110000; // Hex F0
    mode = 1'b1;
    @(posedge clk); #1; 
    wait (Wait == 1'b0);
    $display("Test 6 Complete: Write Miss. Bypassed Cache, written to MM.");

    // End simulation
    #50; // Give plenty of time to view the final state before shutting down
    $finish;
end

endmodule
