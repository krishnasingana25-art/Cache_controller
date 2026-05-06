`timescale 1ns / 1ps

module MAIN_MEMORY();

// ---------------------------------------------------------
// Main Memory Parameters
// (These match the CACHE_CONTROLLER perfectly)
// ---------------------------------------------------------
parameter no_of_main_memory_blocks = 16384; // 2^14 total lines in main memory
parameter main_memory_block_size = 32;      // 32 bits per block (4 bytes)
parameter no_of_bytes_main_memory_block = 4;  
parameter byte_size = 8;          
parameter main_memory_byte_size = 65536;    // Total size: 64 KB

// ---------------------------------------------------------
// The Memory Array
// A flat 1D array of 16,384 rows, where each row is 32-bits wide
// ---------------------------------------------------------
reg [main_memory_block_size-1:0] main_memory [0:no_of_main_memory_blocks-1];

// ---------------------------------------------------------
// Initialization
// ---------------------------------------------------------
initial 
begin: initialization_main_memory
    integer i;
    for (i=0; i < no_of_main_memory_blocks; i=i+1)
    begin
        // Initializing memory with its own index value for testing purposes
        main_memory[i] = i;        
    end
end

endmodule
