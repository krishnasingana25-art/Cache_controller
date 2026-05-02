module mc_scheduler;

`timescale 1ps/1ps

// -----------------------------
// Transaction structure (simplified)
// -----------------------------
typedef struct {
    logic [33:0] address_hex;
    logic [15:0] row;
    logic [9:0]  col;
    logic [1:0]  request_type; // 0/2 = READ, 1 = WRITE
} Transaction;

// -----------------------------
// FSM States
// -----------------------------
typedef enum {INITIAL, PRE, ACT, READ, WRITE, DONE} States;

// -----------------------------
// Timing parameters (single-bank relevant)
// -----------------------------
parameter tRCD = 39;
parameter tRAS = 76;
parameter tRP  = 39;
parameter tCL  = 40;
parameter tCWD = 38;
parameter tBURST = 8;
parameter tWR  = 30;

// -----------------------------
// Variables
// -----------------------------
Transaction trans_data;
Transaction current;

Transaction main_q[$:15];

States state;

bit enable;
bit sim_end;

string line;
string filename, filename1;
int fh, fh1;

string parts[4];
string clock_cycle, core, request_type, address;

longint cpu_clk;
longint clk_req;

// -----------------------------
// Single-bank model
// -----------------------------
bit row_open;
int open_row;

// timing trackers
longint last_act;
longint last_pre;
longint last_read;
longint last_write;

// -----------------------------
// Parse function
// -----------------------------
function void parse_transaction(string clk, string core, string req, string addr);
    trans_data.address_hex = addr.atohex();
    trans_data.row = trans_data.address_hex[33:18];
    trans_data.col = trans_data.address_hex[17:2];
    trans_data.request_type = req.atoi();
endfunction

// -----------------------------
// Initialization
// -----------------------------
initial begin

    row_open = 0;
    open_row = -1;

    last_act = 0;
    last_pre = 0;
    last_read = 0;
    last_write = 0;

    cpu_clk = 0;
    sim_end = 0;
    enable = 1;

    state = INITIAL;

    if (!$value$plusargs("INPUT_FILE%s", filename))
        filename = "trace.txt";

    if (!$value$plusargs("OUTPUT_FILE%s", filename1))
        filename1 = "dram.txt";

    fh = $fopen(filename, "r");
    fh1 = $fopen(filename1, "w");

    if (!fh) begin
        $display("ERROR: Cannot open input file");
        $finish;
    end

// -----------------------------
// Main loop
// -----------------------------
    while (!sim_end) begin

        // -------------------------
        // Read input
        // -------------------------
        if (enable && !$feof(fh)) begin
            if ($fgets(line, fh)) begin
                $sscanf(line, "%s %s %s %s", parts[0], parts[1], parts[2], parts[3]);

                clock_cycle = parts[0];
                core = parts[1];
                request_type = parts[2];
                address = parts[3];

                clk_req = clock_cycle.atoi();

                parse_transaction(clock_cycle, core, request_type, address);

                enable = 0;
            end
        end

        if (cpu_clk >= clk_req && main_q.size() < 16) begin
            main_q.push_back(trans_data);
            enable = 1;
        end

        // -------------------------
        // FSM execution
        // -------------------------
        if (main_q.size() > 0) begin
            current = main_q[0];

            case (state)

                INITIAL: begin
                    if (!row_open) begin
                        state = ACT;
                    end
                    else if (current.row == open_row) begin
                        if (current.request_type == 1)
                            state = WRITE;
                        else
                            state = READ;
                    end
                    else begin
                        state = PRE;
                    end
                end

                PRE: begin
                    if (cpu_clk - last_act >= tRAS &&
                        cpu_clk - last_write >= tWR) begin

                        $fwrite(fh1, "%0d PRE\n", cpu_clk);

                        row_open = 0;
                        last_pre = cpu_clk;

                        state = ACT;
                    end
                end

                ACT: begin
                    if (cpu_clk - last_pre >= tRP) begin

                        $fwrite(fh1, "%0d ACT %h\n", cpu_clk, current.row);

                        row_open = 1;
                        open_row = current.row;
                        last_act = cpu_clk;

                        if (current.request_type == 1)
                            state = WRITE;
                        else
                            state = READ;
                    end
                end

                READ: begin
                    if (cpu_clk - last_act >= tRCD) begin

                        $fwrite(fh1, "%0d READ %h\n", cpu_clk, current.col);

                        last_read = cpu_clk;
                        state = DONE;
                    end
                end

                WRITE: begin
                    if (cpu_clk - last_act >= tRCD) begin

                        $fwrite(fh1, "%0d WRITE %h\n", cpu_clk, current.col);

                        last_write = cpu_clk;
                        state = DONE;
                    end
                end

                DONE: begin
                    if ((current.request_type != 1 &&
                        cpu_clk - last_read >= tCL + tBURST) ||
                        (current.request_type == 1 &&
                        cpu_clk - last_write >= tCWD + tBURST)) begin

                        main_q.pop_front();
                        state = INITIAL;
                    end
                end

            endcase
        end

        // -------------------------
        // End condition
        // -------------------------
        if ($feof(fh) && main_q.size() == 0)
            sim_end = 1;

        cpu_clk++;
    end

    $display("Simulation completed");
end

endmodule
