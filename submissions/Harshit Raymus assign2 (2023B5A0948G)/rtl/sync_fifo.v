module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input wire clk,
    input wire rst_n,

    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire wr_full,

    input wire rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    output wire rd_empty,

    output reg [ADDR_WIDTH:0] count
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;

assign wr_full  = (count == DEPTH);
assign rd_empty = (count == 0);

always @(posedge clk) begin
    if(!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;
        rd_data <= 0;
    end
    else begin

        // simultaneous read and write
        if(wr_en && rd_en && !rd_empty && !wr_full) begin
            mem[wr_ptr] <= wr_data;
            rd_data <= mem[rd_ptr];

            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
        end

        // write only
        else if(wr_en && !wr_full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            count <= count + 1;
        end

        // read only
        else if(rd_en && !rd_empty) begin
            rd_data <= mem[rd_ptr];
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            count <= count - 1;
        end

    end
end

endmodule