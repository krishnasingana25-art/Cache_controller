`timescale 1ns / 1ps

module CACHE_CONTROLLER(
    input [no_of_address_bits-1:0] address, 
    input clk, 
    input [byte_size-1:0] data, 
    input mode,             // mode=0 : Read, mode=1 : Write
    output reg [byte_size-1:0] output_data, 
    output reg hit,         // hit=1 shows requested memory was found in Cache
    output reg Wait,        // Wait=1 signals the processor to stall
    output reg [no_of_address_bits-1:0] stored_address, 
    output reg [byte_size-1:0] stored_data
);

/********************************/
// General Parameters
parameter no_of_address_bits = 32;    
parameter no_of_blkoffset_bits = 2;
parameter byte_size = 8;               // one byte is 8 bits

/********************************/
// Cache Parameters (2-Way Set Associative)
parameter no_of_cache_ways = 2;
parameter no_of_cache_sets = 32;       // 64 total blocks / 2 ways = 32 sets
parameter no_of_bytes_cache_block = 4; // Each Block has 4 bytes
parameter cache_block_bit_size = 32;   // 4 bytes * 8 bits = 32 bits
parameter no_of_cache_index_bits = 5;  // 2^5 = 32 sets
parameter no_of_cache_tag_bits = 25;   // 32 total - 5 index - 2 offset = 25 tag bits

/********************************/
// Main Memory Parameters
parameter no_of_main_memory_blocks = 16384; 
parameter main_memory_block_size = 32;       
parameter no_of_bytes_main_memory_block = 4;     
parameter main_memory_latency = 10;    // Delay in fetching from main memory
/*************************************/

reg stored_mode;        
reg Ccount = 0;   

// Internal tracking variables
reg [no_of_address_bits-no_of_blkoffset_bits-1:0] main_memory_blk_id; 
reg [no_of_cache_tag_bits-1:0] cache_tag;         
reg [no_of_cache_index_bits-1:0] cache_index;         
reg [no_of_blkoffset_bits-1:0] offset;            
reg [no_of_cache_tag_bits-1:0] evict_tag;

// LRU tracking variable
reg lru_way_to_replace;

// Delay counters
reg [3:0] main_memory_delay_counter = 0;
reg [3:0] main_memory_delay_counter_w = 0;

// Memory Instantiations
// Note: CACHE_MEMORY module must now use 2D arrays: e.g., cache_valid[31:0][1:0], lru[31:0]
MAIN_MEMORY main_memory_instance();
CACHE_MEMORY cache_memory_instance();

always @(posedge clk)
begin
    if (Ccount == 0)
        output_data = 0;
        
    if(Ccount == 0 || Wait == 0) // Store input from processor if ready
    begin
        stored_address = address;
        Ccount = 1;
        stored_mode = mode;
        stored_data = data;
    end
    
    // Address decoding
    main_memory_blk_id = (stored_address >> no_of_blkoffset_bits) % MAIN_MEMORY.no_of_main_memory_blocks; 
    cache_index = main_memory_blk_id % no_of_cache_sets;  
    cache_tag = main_memory_blk_id >> no_of_cache_index_bits;
    offset = stored_address % MAIN_MEMORY.no_of_bytes_main_memory_block;  

    // ---------------------------------------------------------
    // READ OPERATION
    // ---------------------------------------------------------
    if (stored_mode == 0)
    begin
        // Check Way 0 for a Hit
        if (CACHE_MEMORY.cache_valid[cache_index][0] && CACHE_MEMORY.cache_tag_array[cache_index][0] == cache_tag) 
        begin
            $display("Read Hit in Cache Way 0");
            output_data = CACHE_MEMORY.cache_memory[cache_index][0][((offset+1)*byte_size-1)-:byte_size]; 
            hit = 1;      
            Wait = 0;
            // Update LRU: Since we just used Way 0, Way 1 is now the Least Recently Used (set LRU bit to 1)
            CACHE_MEMORY.lru[cache_index] = 1;          
        end
        // Check Way 1 for a Hit
        else if (CACHE_MEMORY.cache_valid[cache_index][1] && CACHE_MEMORY.cache_tag_array[cache_index][1] == cache_tag) 
        begin
            $display("Read Hit in Cache Way 1");
            output_data = CACHE_MEMORY.cache_memory[cache_index][1][((offset+1)*byte_size-1)-:byte_size]; 
            hit = 1;      
            Wait = 0;
            // Update LRU: Since we just used Way 1, Way 0 is now the Least Recently Used (set LRU bit to 0)
            CACHE_MEMORY.lru[cache_index] = 0; 
        end
        // Miss in Cache, fetch from Main Memory
        else 
        begin
            $display("Miss in Cache. Fetching from Main Memory...");
            hit = 0;      
            
            if (main_memory_delay_counter < main_memory_latency) 
            begin
                main_memory_delay_counter = main_memory_delay_counter + 1; 
                Wait = 1; // Stall processor
            end
            else 
            begin 
                // Latency complete, handle eviction and memory transfer
                main_memory_delay_counter = 0;  
                Wait = 0; 
                hit = 1; 
                
                // Determine which way to evict based on the 1-bit LRU
                lru_way_to_replace = CACHE_MEMORY.lru[cache_index];
                
                // If the way we are replacing has valid data, write it back to Main Memory
                if (CACHE_MEMORY.cache_valid[cache_index][lru_way_to_replace] == 1)
                begin
                    evict_tag = CACHE_MEMORY.cache_tag_array[cache_index][lru_way_to_replace];
                    MAIN_MEMORY.main_memory[{evict_tag, cache_index}] = CACHE_MEMORY.cache_memory[cache_index][lru_way_to_replace];
                end
                
                // Fetch new block from Main Memory to Cache
                CACHE_MEMORY.cache_memory[cache_index][lru_way_to_replace] = MAIN_MEMORY.main_memory[main_memory_blk_id];
                CACHE_MEMORY.cache_valid[cache_index][lru_way_to_replace] = 1;
                CACHE_MEMORY.cache_tag_array[cache_index][lru_way_to_replace] = cache_tag;
                
                // Output the requested byte
                output_data = CACHE_MEMORY.cache_memory[cache_index][lru_way_to_replace][((offset+1)*byte_size-1)-:byte_size];
                
                // Update LRU: Flip the bit because the way we just filled is now the MOST recently used
                CACHE_MEMORY.lru[cache_index] = ~lru_way_to_replace;
            end
        end
    end
    
    // ---------------------------------------------------------
    // WRITE OPERATION
    // ---------------------------------------------------------
    else 
    begin
        output_data = 0;
        
        // Check Way 0 for Write Hit
        if (CACHE_MEMORY.cache_valid[cache_index][0] && CACHE_MEMORY.cache_tag_array[cache_index][0] == cache_tag) 
        begin
            $display("Write Hit in Cache Way 0");
            CACHE_MEMORY.cache_memory[cache_index][0][((offset+1)*byte_size-1)-:byte_size] = stored_data;     
            Wait = 0;      
            hit = 1;  
            CACHE_MEMORY.lru[cache_index] = 1; // Way 1 is now LRU
        end
        // Check Way 1 for Write Hit
        else if (CACHE_MEMORY.cache_valid[cache_index][1] && CACHE_MEMORY.cache_tag_array[cache_index][1] == cache_tag) 
        begin
            $display("Write Hit in Cache Way 1");
            CACHE_MEMORY.cache_memory[cache_index][1][((offset+1)*byte_size-1)-:byte_size] = stored_data;     
            Wait = 0;      
            hit = 1;  
            CACHE_MEMORY.lru[cache_index] = 0; // Way 0 is now LRU
        end
        // Write Miss (Write-Around Policy)
        else 
        begin  
            hit = 0; 
            
            if(main_memory_delay_counter_w < main_memory_latency) 
            begin 
                main_memory_delay_counter_w = main_memory_delay_counter_w + 1; 
                Wait = 1; 
            end
            else
            begin 
                main_memory_delay_counter_w = 0;  
                Wait = 0;       
                // Write directly to main memory bypassing the cache on a miss
                MAIN_MEMORY.main_memory[main_memory_blk_id][((offset+1)*byte_size-1)-:byte_size] = stored_data;      
            end
        end 
    end
end
endmodule
