module sdram_fifo_ctrl(
	input             clk_ref,          // clock
	input             reset_n,          // reset_n
    
    // FIFO Write
	input             clk_write,        // FIFO Write clock
	input             fifo_wr_req,      // FIFO Write request
	input      [15:0] fifo_wr_din,      // FIFO Write data
	input      [23:0] wr_min_addr,      // sdram Write address start
	input      [23:0] wr_max_addr,      // sdram Write address stop
 	input      [ 9:0] wr_length,        // sdram Write burst length
	input             wr_load,          // clear write address and fifo
    
    // FIFO Read
	input             clk_read,         // FIFO Read clock
	input             fifo_rd_req,      // FIFO Read request
	output     [15:0] fifo_rd_dout,     // FIFO Read data
	input      [23:0] rd_min_addr,      // sdram Read address start
	input      [23:0] rd_max_addr,      // sdram Read address stop
	input      [ 9:0] rd_length,        // sdram Read burst length
	input             rd_load,          // clear read address and fifo
    
	// sdram signal
	input             sdram_read_valid, // sdram read valid
	input             sdram_init_done,  // sdram initial done
    
    // sdram write interface
	output reg		  sdram_wr_req,     // sdram write request
	input             sdram_wr_ack,     // sdram write ack
	output reg [23:0] sdram_wr_addr,    // sdram write address
	output	   [15:0] sdram_din,        // sdram write data
    
    // sdram read interface
	output reg        sdram_rd_req,     // sdram read request
	input             sdram_rd_ack,     // sdram read ack
	output reg [23:0] sdram_rd_addr,    // sdram read address
	input      [15:0] sdram_dout        // sdram read data
);
        
    reg	       wr_ack_r1;
    reg	       wr_ack_r2;
    reg        rd_ack_r1;
    reg	       rd_ack_r2;
    reg	       wr_load_r1;
    reg        wr_load_r2;
    reg	       rd_load_r1;
    reg        rd_load_r2;
    reg        read_valid_r1;
    reg        read_valid_r2;

    wire       write_done_flag;     // sdram_wr_ack negedge
    wire       read_done_flag;      // sdram_rd_ack negedge
    wire       wr_load_flag;        // wr_load      posedge
    wire       rd_load_flag;        // rd_load      posedge
    wire [9:0] fifo_wr_used;        // FIFO used
    wire [9:0] fifo_rd_used;        // FIFO used


    // negedge
    assign write_done_flag = wr_ack_r2   & ~wr_ack_r1;	
    assign read_done_flag  = rd_ack_r2   & ~rd_ack_r1;

    // posedge
    assign wr_load_flag    = ~wr_load_r2 & wr_load_r1;
    assign rd_load_flag    = ~rd_load_r2 & rd_load_r1;
    
    
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
        begin
            wr_ack_r1 <= 1'b0;
            wr_ack_r2 <= 1'b0;
        end
        else
        begin
            wr_ack_r1 <= sdram_wr_ack;
            wr_ack_r2 <= wr_ack_r1;
        end
    end
    
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_ack_r1 <= 1'b0;
            rd_ack_r2 <= 1'b0;
        end
        else begin
            rd_ack_r1 <= sdram_rd_ack;
            rd_ack_r2 <= rd_ack_r1;
        end
    end
    
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
        begin
            wr_load_r1 <= 1'b0;
            wr_load_r2 <= 1'b0;
        end
        else
        begin
            wr_load_r1 <= wr_load;
            wr_load_r2 <= wr_load_r1;
        end
    end
    
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_load_r1 <= 1'b0;
            rd_load_r2 <= 1'b0;
        end
        else
        begin
            rd_load_r1 <= rd_load;
            rd_load_r2 <= rd_load_r1;
        end
    end
    
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
        begin
            read_valid_r1 <= 1'b0;
            read_valid_r2 <= 1'b0;
        end
        else
        begin
            read_valid_r1 <= sdram_read_valid;
            read_valid_r2 <= read_valid_r1;
        end
    end
    
    // sdram write address
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
            sdram_wr_addr <= 24'd0;	
        else if(wr_load_flag)               // clear
            sdram_wr_addr <= wr_min_addr;
        else if(write_done_flag)            // sdram write done
        begin
            if(sdram_wr_addr < wr_max_addr - wr_length)
                sdram_wr_addr <= sdram_wr_addr + wr_length;
            else
                sdram_wr_addr <= wr_min_addr;
        end
    end

    // sdram read address
    always @(posedge clk_ref or negedge reset_n)
    begin
        if(!reset_n)
            sdram_rd_addr <= 24'd0;
        else if(rd_load_flag)               // clear
            sdram_rd_addr <= rd_min_addr;
        else if(read_done_flag)             // sdram read done
        begin
            if(sdram_rd_addr < rd_max_addr - rd_length)
                sdram_rd_addr <= sdram_rd_addr + rd_length;
            else
                sdram_rd_addr <= rd_min_addr;
        end
    end

    //sdram r/w request
    always@(posedge clk_ref or negedge reset_n) begin
        if(!reset_n) begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
        else if(sdram_init_done)            // initial done
        begin
            if(fifo_wr_used >= wr_length)   // get all data to write
            begin
                sdram_wr_req <= 1'b1;
                sdram_rd_req <= 1'b0;
            end
            else if((fifo_rd_used < rd_length) && read_valid_r2)    // has space to read, is there a bug here???
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b1;
            end
            else
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b0;
            end
        end
        else
        begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
    end

    wrfifo	u_wrfifo(
        // interface
        .wrclk		(clk_write),
        .wrreq		(fifo_wr_req),
        .data		(fifo_wr_din),
        
        // sdram
        .rdclk		(clk_ref),
        .rdreq		(sdram_wr_ack),
        .q			(sdram_din),
        
        .rdusedw	(fifo_wr_used),
        .aclr		(~reset_n | wr_load_flag)
        );	

    rdfifo	u_rdfifo(
        // sdram
        .wrclk		(clk_ref),
        .wrreq		(sdram_rd_ack),
        .data		(sdram_dout),
        
        // interface
        .rdclk		(clk_read),
        .rdreq		(fifo_rd_req),
        .q			(fifo_rd_dout),
        
        .wrusedw	(fifo_rd_used),
        .aclr		(~reset_n | rd_load_flag)
        );
    
endmodule 