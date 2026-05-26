`timescale 1ns / 1ps

module apb_tb_slave();

reg clk, reset_n;

wire pselx;
wire penable;
wire [31:0] paddr;
wire [31:0] pwdata;
wire pwrite;

reg pready;

reg transfer;
reg [31:0] addr;
reg [31:0] wdata;
reg write;

//
// DUT Instantiation
//
apb_master dut(
    .reset_n(reset_n),
    .transfer(transfer),
    .addr(addr),
    .wdata(wdata),
    .write(write),
    .clk(clk),
    .pselx(pselx),
    .penable(penable),
    .paddr(paddr),
    .pwdata(pwdata),
    .pwrite(pwrite),
    .pready(pready)
);

//
// Clock Generation
//
always #5 clk = ~clk;

//
// Test
//
initial
begin
    clk      = 0;
    reset_n  = 0;
    transfer = 0;
    addr     = 0;
    wdata    = 0;
    write    = 0;
    pready   = 0;

    #20;
    reset_n = 1;

    // APB Write Transfer
    @(posedge clk);

    transfer = 1;
    addr     = 32'habcd_1234;
    wdata    = 32'hface_cafe;
    write    = 1;

    @(posedge clk);
    transfer = 0;

    // Wait state
    repeat(3)
        @(posedge clk);

    pready = 1;

    @(posedge clk);
    pready = 0;

    #50;
    $finish;
end

endmodule