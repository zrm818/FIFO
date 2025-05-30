/******************************************************************************
 ***                                                                        ***
 *** ECE 526 L Experiment #10                    Zach Martin, Fall, 2024    ***
 ***                                                                        ***
 *** Synchronous FIFO                                                       ***
 ***                                                                        ***
 ******************************************************************************
 *** Filename: FIFO_tb.v               Created by Zach Martin, 12/7/2024    ***
 ***                                                                        ***
 ******************************************************************************/

`define WIDTH 8     // Width of each memory location in bits
`define DEPTH 32    // Number of memory locations in FIFO
`define CLK_T 20    // Test clock period

`timescale 1ns / 1ns

module FIFO_tb ();

// Determines how to view waveforms depending on current compiler
// I've been using Icarus so I can compile offline, it's pretty handy
`ifdef __ICARUS__
    initial begin
        $dumpfile("FIFO_tb.vcd");
        $dumpvars(0, FIFO_tb);
    end
`elsif __VCS__
    initial begin
        $vcdpluson;
    end
`endif

// Declare FIFO input registers (and establish clock procedure)
reg clk = 0;    always #(`CLK_T) clk = (~clk);
reg [`WIDTH-1:0] data_in;
reg wr_en, rd_en, rst;

// Declare FIFO output wires
wire [`WIDTH-1:0] data_out;
wire valid;
wire [$clog2(`DEPTH)-1:0] count;
wire overflow, underflow, full, near_full, near_empty, empty;

// Declare loop counter used in multi-write and multi-read tests
integer i;

// Instantiate a test FIFO module 
FIFO FIFO32(
    .data_out (data_out),
    .valid (valid),
    .count (count),
    .overflow (overflow),
    .underflow (underflow),
    .full (full),
    .near_full (near_full),
    .near_empty (near_empty),
    .empty (empty),

    .data_in (data_in),
    .clk (clk),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .rst (rst)
);

// Define monitor string and formatting (this one's a bit long)
initial begin #1
$monitor("| %b | %b | %b | %h || %h |%b| %h| %b | %b |%b| %b | %b |%b| %h | %h |",
    wr_en, rd_en, rst, data_in, data_out, valid, count, overflow, underflow,
    full, near_full, near_empty, empty, FIFO32.wr_pos, FIFO32.rd_pos);
end

initial begin

    // Start with RESET to determine initial conditions
    rst = 0;


    $display("\n");
    $display("|-------------------- MULTI-WRITE TEST --------------------|");
    $display("|w_e|r_e|rst|d_in||Dout|v|cnt|o_f|u_f|f|n_f|n_e|e|wr_p|rd_p|");
    $display("|---|---|---|----||----|-|---|---|---|-|---|---|-|----|----|");
    
    // WRITE to every location plus one
    @(negedge clk) wr_en = 1; rd_en = 0; rst = 1; 
    data_in = 0;
    for (i = 1; i < `DEPTH; i = i + 1) begin
        $monitoroff;
        @(negedge clk) data_in = i;
        $monitoron;
    end
    @(negedge clk);


    $display("\n");
    $display("|-------------------- MULTI-READ TEST ---------------------|");
    $display("|w_e|r_e|rst|d_in||Dout|v|cnt|o_f|u_f|f|n_f|n_e|e|wr_p|rd_p|");
    $display("|---|---|---|----||----|-|---|---|---|-|---|---|-|----|----|");

    // READ from every location plus one
    @(negedge clk) wr_en = 0; rd_en = 1;
    for (i = 1; i < `DEPTH + 100; i = i + 1) begin
        @(negedge clk);
    end


    // RESET FIFO
    $monitoroff;
    $display("\n\t\tResetting FIFO.....\n");
    rst = 0; wr_en = 0; rd_en = 0; data_in = 0;
    $monitoron;


    $display("|------------- SIMULTANEOUS READ/WRITE TEST ---------------|");
    $display("|w_e|r_e|rst|d_in||Dout|v|cnt|o_f|u_f|f|n_f|n_e|e|wr_p|rd_p|");
    $display("|---|---|---|----||----|-|---|---|---|-|---|---|-|----|----|");

    // WRITE five times, then begin reading and continue writing
    @(negedge clk) rst = 1; wr_en = 1; 
                   data_in = 'h41;
    @(negedge clk) data_in = 'h22;
    @(negedge clk) data_in = 'h7d;
    @(negedge clk) data_in = 'hff;
    @(negedge clk) data_in = 'h3a;
    @(negedge clk) rd_en = 1;           // Begin reading
                   data_in = 'h99;      // Continue writing
    @(negedge clk) data_in = 'h86;
    @(negedge clk) data_in = 'hbc;


    #1 $display("\n");
    $display("|-------------------- END OF TESTING ----------------------|\n");
    $finish;
end

endmodule