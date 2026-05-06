`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: CACHE_MEMORY
// Description: 2-Way Set-Associative Single-Level Cache Data Storage
//////////////////////////////////////////////////////////////////////////////////

module CACHE_MEMORY();

// ---------------------------------------------------------
// Cache Parameters (2-Way Set Associative)
// ---------------------------------------------------------
parameter no_of_cache_sets = 32;       // 32 sets total
parameter no_of_cache_ways = 2;        // 2 ways per set
parameter cache_block_bit_size = 32;   // 4 bytes * 8 bits = 32 bits per block
parameter no_of_cache_tag_bits = 25;   // 32-bit address - 5 index bits - 2 offset bits = 25 tag bits

// ---------------------------------------------------------
// 2D Memory Arrays: Structure is [Set_Index][Way]
// ---------------------------------------------------------
// The actual data storage (32 sets, 2 ways, 32-bit data block)
reg [cache_block_bit_size-1:0] cache_memory [0:no_of_cache_sets-1][0:no_of_cache_ways-1];

// The tag array (32 sets, 2 ways, 25-bit tags)
reg [no_of_cache_tag_bits-1:0] cache_tag_array [0:no_of_cache_sets-1][0:no_of_cache_ways-1];

// The valid bits (32 sets, 2 ways, 1-bit boolean flag)
reg cache_valid [0:no_of_cache_sets-1][0:no_of_cache_ways-1];

// ---------------------------------------------------------
// LRU (Least Recently Used) Tracker
// ---------------------------------------------------------
// 1 bit per set. 
// If lru[set] == 0: Way 0 is the oldest, evict Way 0.
// If lru[set] == 1: Way 1 is the oldest, evict Way 1.
reg lru [0:no_of_cache_sets-1];

// ---------------------------------------------------------
// Initialization
// ---------------------------------------------------------
initial 
begin: initialization_cache_memory
    integer i, j;
    
    // Loop through all 32 sets
    for (i = 0; i < no_of_cache_sets; i = i + 1)
    begin
        lru[i] = 0;  // At startup, default to evicting Way 0 first
        
        // Loop through both ways in the current set
        for (j = 0; j < no_of_cache_ways; j = j + 1)
        begin
            cache_valid[i][j] = 0;      // All blocks start empty (invalid)
            cache_tag_array[i][j] = 0;  // Clear tags
            cache_memory[i][j] = 0;     // Clear data
        end
    end
end

endmodule
