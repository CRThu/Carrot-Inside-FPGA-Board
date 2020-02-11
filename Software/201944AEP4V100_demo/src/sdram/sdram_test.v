module sdram_test(
    input             clk_50m,          // clock
    input             reset_n,          // reset_n
    
    output reg        wr_en,            // test write enable
    output reg [15:0] wr_data,          // test write data
    output reg        rd_en,            // test read enable
    input      [15:0] rd_data,          // test read data
    
    input             sdram_init_done,  // sdram initial done
    output reg        error_flag        // sdram error flag
);

    reg        init_done_d0;
    reg        init_done_d1;
    reg [10:0] wr_cnt;                  // write counter
    reg [10:0] rd_cnt;                  // read counter
    reg        rd_valid;                // read vaild count

    // sync to the clock domain in this module
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            init_done_d0 <= 1'b0;
            init_done_d1 <= 1'b0;
        end
        else
        begin
            init_done_d0 <= sdram_init_done;
            init_done_d1 <= init_done_d0;
        end
    end            

    // write counter
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n) 
            wr_cnt <= 11'd0;  
        else if(init_done_d1 && (wr_cnt <= 11'd1024))
            wr_cnt <= wr_cnt + 1'b1;
        else
            wr_cnt <= wr_cnt;
    end    

    // write enable and write data(1-1024)
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin      
            wr_en   <= 1'b0;
            wr_data <= 16'd0;
        end
        else if(wr_cnt >= 11'd1 && (wr_cnt <= 11'd1024))
        begin
            wr_en   <= 1'b1;
            wr_data <= wr_cnt;
        end    
        else
        begin
            wr_en   <= 1'b0;
            wr_data <= 16'd0;
        end                
    end        

    // read enable    
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n) 
            rd_en <= 1'b0;
        else if(wr_cnt > 11'd1024)
            rd_en <= 1'b1;
    end

    // read counter
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n) 
            rd_cnt <= 11'd0;
        else if(rd_en)
        begin
            if(rd_cnt < 11'd1024)
                rd_cnt <= rd_cnt + 1'b1;
            else
                rd_cnt <= 11'd1;
        end
    end

    // read vaild
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
            rd_valid <= 1'b0;
        else if(rd_cnt == 11'd1024)     // first time to read
            rd_valid <= 1'b1;
        else
            rd_valid <= rd_valid;
    end
    
    // read data
    always @(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
            error_flag <= 1'b0;
        else if(rd_valid && (rd_data != rd_cnt))
            error_flag <= 1'b1;
        else
            error_flag <= error_flag;
    end
    
endmodule 