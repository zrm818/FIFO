/******************************************************************************
 ***                                                                        ***
 *** ECE 526 L Experiment #10                    Zach Martin, Fall, 2024    ***
 ***                                                                        ***
 *** Synchronous FIFO                                                       ***
 ***                                                                        ***
 ******************************************************************************
 *** Filename: FIFO.v                  Created by Zach Martin, 12/7/2024    ***
 ***                                                                        ***
 ******************************************************************************/

module FIFO (
    output reg [WIDTH-1:0] data_out,    // Data output bus
    output valid,                       // Successful read flag
    output [$clog2(DEPTH)-1:0] count,   // Current depth of data counter
    output reg overflow,                // Wrote-to-full flag
    output reg underflow,               // Read-from-empty flag
    output full,                        // No-free-cells flag
    output near_full,                   // Nearly-no-free-cells flag
    output near_empty,                  // Nearly-no-filled-cells flag
    output empty,                       // No-filled-cells flag

    input [WIDTH-1:0] data_in,          // Data input bus
    input clk,                          // Clock input
    input wr_en,                        // Write-enable line
    input rd_en,                        // Read-enable line
    input rst                           // Active-low reset line
);

// Declare parameters
parameter WIDTH = 8;         // Width of each memory location in bits
parameter DEPTH = 32;        // Number of memory locations in FIFO
parameter near_e_depth = 2;  // Distance from bottom to raise 'near_empty' flag
parameter near_f_depth = 2;  // Distance from top to raise 'near_full' flag

// Declare loop counter used in reset
integer i;

// Declare internal memory and read and write pointers
reg [WIDTH-1:0] fifo[DEPTH-1:0];
reg [$clog2(DEPTH)-1:0] wr_pos = 'b0;
reg [$clog2(DEPTH)-1:0] rd_pos = 'b0;

// Assign depth of FIFO counter output and flags (except overflow/underflow)
assign count =      wr_pos - rd_pos;
assign empty =      (count == 0);
assign near_empty = (count <= near_e_depth) && !empty;
assign near_full =  (count >= (DEPTH-1 - near_f_depth)) && !full;
assign full =       (count == DEPTH-1);
assign valid =      (rd_en && !empty);


// Run the synchronous FIFO
always @(posedge clk or negedge rst) begin

    // RESET operation
    if (!rst) begin
        wr_pos = 'b0; rd_pos = 'b0;
        for (i = 0; i < DEPTH; i = i + 1) 
            fifo[i] = 'b0;
        data_out = fifo[rd_pos];
        overflow = 1'b0; 
        underflow = 1'b0;
    end else begin

        // WRITE operation
        if (wr_en && !full) begin
            fifo[wr_pos] = data_in;
            underflow = 1'b0;
            wr_pos = (wr_pos + 1);
        end else if (wr_en && full) 
            overflow = 1'b1;

        // READ operation
        if (rd_en && !empty) begin
            data_out = fifo[rd_pos];
            overflow = 1'b0;
            rd_pos = (rd_pos + 1);
        end else if (rd_en && empty) begin
            underflow = 1'b1;
        end
    end
    
end

endmodule