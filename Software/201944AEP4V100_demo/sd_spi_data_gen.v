`define TEST_SEC_ADDR 32'd2000

module sd_spi_data_gen(
    input wire          clk_50m         ,   // clock
    input wire          reset_n         ,   // reset
    input wire          sd_init_done    ,   // sd initial done
    /*  Write  */
    input wire          wr_busy         ,   // write busy
    input wire          wr_req          ,   // write request
    output reg          wr_start_en     ,   // start writing data
    output reg  [31:0]  wr_sec_addr     ,   // write sector address
    output wire [15:0]  wr_data         ,   // write data
    /*  Read  */
    input wire          rd_en           ,   // read enable
    input wire  [15:0]  rd_data         ,   // read data
    output reg          rd_start_en     ,   // start reading data
    output reg  [31:0]  rd_sec_addr     ,   // read sector address
    
    output wire         error_flag          // sd error flag
);
    
    reg         sd_init_done_delay1 ;       // initial done signal delay
    reg         sd_init_done_delay2 ;       
    reg         wr_busy_delay0      ;       // write busy signal delay
    reg         wr_busy_delay1      ;       
    reg [15:0]  wr_data_buf         ;       // write data buffer
    reg [15:0]  rd_comp_data        ;       // compare data
    reg [8:0]   rd_correct_cnt      ;       // count correct data
    
    wire        pos_init_done       ;       // posedge of init_done for start writing signal
    wire        neg_wr_busy         ;       // negedge of wr_busy for finishing writing data
    
    
    assign pos_init_done = (~sd_init_done_delay2) & sd_init_done_delay1;
    assign neg_wr_busy = wr_busy_delay1 & (~wr_busy_delay0);
    assign wr_data = (wr_data_buf > 16'd0) ? (wr_data_buf -1'b1) : 16'd0;
    assign error_flag = (rd_correct_cnt == (9'd256)) ? 1'b0 : 1'b1;
    
    // sd_init_done_delay generator
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            sd_init_done_delay1 <= 1'b0;
            sd_init_done_delay2 <= 1'b0;
        end
        else
        begin
            sd_init_done_delay1 <= sd_init_done;
            sd_init_done_delay2 <= sd_init_done_delay1;
        end
    end
    
    // wr_start_en control
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            wr_start_en <= 1'b0;
            wr_sec_addr <= 32'd0;
        end
        else
        begin
            if(pos_init_done)
            begin
                wr_start_en <= 1'b1;
                wr_sec_addr <= `TEST_SEC_ADDR;    // sector address
            end
            else
            begin
                wr_start_en <= 1'b0;
            end
        end
    end

    // write
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
            wr_data_buf <= 16'b0;
        else if(wr_req)
            wr_data_buf <= wr_data_buf + 16'b1;
    end

    // wr_busy
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            wr_busy_delay0 <= 1'b0;
            wr_busy_delay1 <= 1'b0;
        end
        else
        begin
            wr_busy_delay0 <= wr_busy;
            wr_busy_delay1 <= wr_busy_delay0;
        end
    end

    // read
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_start_en <= 1'b0;
            rd_sec_addr <= 32'd0;
        end
        else
        begin
            if(neg_wr_busy)
            begin
                rd_start_en <= 1'b1;
                rd_sec_addr <= `TEST_SEC_ADDR;
            end
            else
                rd_start_en <= 1'b0;
        end
    end

    // rd_correct_cnt for error_flag
    always @(posedge clk_50m or negedge reset_n) begin
        if(!reset_n)
        begin
            rd_comp_data <= 16'd0;
            rd_correct_cnt <= 9'd0;
        end
        else
        begin
            if(rd_en)
            begin
                rd_comp_data <= rd_comp_data + 16'b1;
                if(rd_data == rd_comp_data)
                begin
                    rd_correct_cnt <= rd_correct_cnt + 9'd1;
                end
            end
        end
    end

endmodule
