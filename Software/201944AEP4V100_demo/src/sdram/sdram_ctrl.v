module sdram_ctrl(
    input            clk,
    input            reset_n,
    
    input            sdram_wr_req,	    // write request
    input            sdram_rd_req,	    // read request
    output           sdram_wr_ack,	    // write ack
    output           sdram_rd_ack,	    // read ack
    input      [9:0] sdram_wr_burst,	// byte of burst write : 1-512
    input      [9:0] sdram_rd_burst,	// byte of burst read : 1-256
    output           sdram_init_done,   // sdram initial done

    output reg [4:0] init_state,	    // initial fsm state
    output reg [3:0] work_state,	    // work fsm state
    output reg [9:0] cnt_clk,	        // clock counter
    output reg       sdram_rd_wr 		// 0/1:w/r
);
    
    `include "sdram_para.v"
                                            //              delay   100MHz@-75deg   150MHz@-75deg   200MHz@-75deg
    parameter  TRP_CLK	  = 10'd2;          // (4)  tRP     15ns    2               3               3
    parameter  TRC_CLK	  = 10'd6;	        // (6)  tRC     60ns    6               9               12
    parameter  TRSC_CLK	  = 10'd2;	        // (6)  tRSC    2tCK    2               2               2
    parameter  TRCD_CLK	  = 10'd2;	        // (2)  tRCD    15ns    2               3               3
    parameter  TCL_CLK	  = 10'd3;	        // (3)  CL      3tCK    3               3               3
    parameter  TWR_CLK	  = 10'd2;	        // (2)  tWR     2tCK    2               2               2
    
    reg [14:0] cnt_200us;                   // powerup counter
    reg [10:0] cnt_refresh;	                // refresh counter
    reg        sdram_ref_req;		        // sdram auto refresh request
    reg        cnt_reset_n;		            // delay counter reset
    reg [ 3:0] init_ar_cnt;                 // sdram init auto refresh counter
    
    wire       done_200us;		            // powerup done
    wire       sdram_ref_ack;		        // auto refresh ack
    
    // powerup
    assign done_200us = (cnt_200us == 15'd20_000);
    
    // initial done
    assign sdram_init_done = (init_state == `I_DONE);
    
    // sdram refresh ack
    assign sdram_ref_ack = (work_state == `W_AR);
    
    // sdram write ack
    assign sdram_wr_ack = ((work_state == `W_TRCD) & ~sdram_rd_wr) | 
                          ( work_state == `W_WRITE)|
                          ((work_state == `W_WD) & (cnt_clk < sdram_wr_burst - 2'd2));
    
    // sdram read ack
    assign sdram_rd_ack = (work_state == `W_RD) & 
                          (cnt_clk >= 10'd1) & (cnt_clk < sdram_rd_burst + 2'd1);
    
    // powerup counter
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            cnt_200us <= 15'd0;
        else if(cnt_200us < 15'd20_000) 
            cnt_200us <= cnt_200us + 1'b1;
        else
            cnt_200us <= cnt_200us;
    end
    
    // refresh counter
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n)
            cnt_refresh <= 11'd0;
        else if(cnt_refresh < 11'd781)          // 64ms / 2^13 = 7812ns
            cnt_refresh <= cnt_refresh + 1'b1;
        else
            cnt_refresh <= 11'd0;
    end

    // sdram refresh request
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            sdram_ref_req <= 1'b0;
        else if(cnt_refresh == 11'd780)         // 7812ns, sdram refresh request
            sdram_ref_req <= 1'b1;
        else if(sdram_ref_ack) 
            sdram_ref_req <= 1'b0;
    end

    // delay counter
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            cnt_clk <= 10'd0;
        else if(!cnt_reset_n)
            cnt_clk <= 10'd0;
        else 
            cnt_clk <= cnt_clk + 1'b1;
    end
            
    // initial auto refresh counter
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            init_ar_cnt <= 4'd0;
        else if(init_state == `I_NOP) 
            init_ar_cnt <= 4'd0;
        else if(init_state == `I_AR)
            init_ar_cnt <= init_ar_cnt + 1'b1;
        else
            init_ar_cnt <= init_ar_cnt;
    end
        
    // sdram initial fsm
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            init_state <= `I_NOP;
        else
        begin
            case (init_state)               
                `I_NOP:  init_state <= done_200us   ? `I_PRE    : `I_NOP;                               // powerup and wait 200us
                `I_PRE:  init_state <= `I_TRP;                                                          // tRP
                `I_TRP:  init_state <= (`end_trp)   ? `I_AR     : `I_TRP;                               // wait for tRP end, to Auto Refresh
                `I_AR :  init_state <= `I_TRF;	                                                        // tRFC
                `I_TRF:  init_state <= (`end_trfc)  ? ((init_ar_cnt == 4'd8) ? `I_MRS : `I_AR) : `I_TRF;// auto refresh 8 times
                `I_MRS:	 init_state <= `I_TRSC;                                                         // tRSC
                `I_TRSC: init_state <= (`end_trsc)  ? `I_DONE   : `I_TRSC;                              // wait for tRSC end initial done
                `I_DONE: init_state <= `I_DONE;                                                         // sdram initial done
                default: init_state <= `I_NOP;
            endcase
        end
    end

    // sdram working fsm
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            work_state <= `W_IDLE;
        else
        begin
            case(work_state)
                `W_IDLE:
                begin
                    if(sdram_ref_req & sdram_init_done)                     // refresh request
                    begin
                        work_state <= `W_AR;
                        sdram_rd_wr <= 1'b1;
                    end               
                    else if(sdram_wr_req & sdram_init_done)                 // write request
                    begin
                        work_state <= `W_ACTIVE;
                        sdram_rd_wr <= 1'b0;
                    end
                    else if(sdram_rd_req && sdram_init_done)                // read request
                    begin
                        work_state <= `W_ACTIVE;
                        sdram_rd_wr <= 1'b1;
                    end
                    else
                    begin
                        work_state <= `W_IDLE;
                        sdram_rd_wr <= 1'b1;
                    end
                end
                `W_ACTIVE:  work_state <= `W_TRCD;                          // ACTIVE
                `W_TRCD:                                                    // tRCD
                begin
                    if(`end_trcd)                                           // end of tRCD
                    begin
                        if(sdram_rd_wr)
                            work_state <= `W_READ;                          // to READ
                        else
                            work_state <= `W_WRITE;                         // to WRITE
                    end
                    else
                        work_state <= `W_TRCD;
                end
                `W_READ:    work_state <= `W_CL;                                // READ
                `W_CL:      work_state <= (`end_tcl)    ? `W_RD     :`W_CL;     // CL, wait for dout
                `W_RD:      work_state <= (`end_tread)  ? `W_PRE    :`W_RD;     // read dout
                `W_WRITE:   work_state <= `W_WD;                                // WRITE
                `W_WD:	    work_state <= (`end_twrite) ? `W_TWR    :`W_WD;     // write din
                `W_TWR:	    work_state <= (`end_twr)    ? `W_PRE    :`W_TWR;    // tWR
                `W_PRE:	    work_state <= `W_TRP;                               // tRP
                `W_TRP:	    work_state <= (`end_trp)    ? `W_IDLE   :`W_TRP;    // wait for tRP
                `W_AR:      work_state <= `W_TRFC;                              // Auto Refresh
                `W_TRFC:    work_state <= (`end_trfc)   ? `W_IDLE   :`W_TRFC;   // tRFC
                default:    work_state <= `W_IDLE;
            endcase
        end
    end

    // delay counter fsm
    always @ (*)
    begin
        case (init_state)
            `I_NOP:     cnt_reset_n <= 1'b0;
            `I_PRE:     cnt_reset_n <= 1'b1;                                // tRP start
            `I_TRP:     cnt_reset_n <= (`end_trp)   ? 1'b0 : 1'b1;          // tRP end
            `I_AR:      cnt_reset_n <= 1'b1;                                // tRFC start
            `I_TRF:     cnt_reset_n <= (`end_trfc)  ? 1'b0 : 1'b1;          // tRFC end
            `I_MRS:     cnt_reset_n <= 1'b1;                                // tRSC start
            `I_TRSC:    cnt_reset_n <= (`end_trsc)  ? 1'b0 : 1'b1;          // tRSC end
            `I_DONE:                                                        // initial done
            begin
                case (work_state)
                    `W_IDLE:	cnt_reset_n <= 1'b0;
                    `W_ACTIVE: 	cnt_reset_n <= 1'b1;                        // tRCD start
                    `W_TRCD:	cnt_reset_n <= (`end_trcd)  ? 1'b0 : 1'b1;  // tRCD end
                    `W_CL:		cnt_reset_n <= (`end_tcl)   ? 1'b0 : 1'b1;  // CL
                    `W_RD:		cnt_reset_n <= (`end_tread) ? 1'b0 : 1'b1;  // Read
                    `W_WD:		cnt_reset_n <= (`end_twrite)? 1'b0 : 1'b1;  // burst write
                    `W_TWR:	    cnt_reset_n <= (`end_twr)   ? 1'b0 : 1'b1;  // tWR
                    `W_TRP:	    cnt_reset_n <= (`end_trp)   ? 1'b0 : 1'b1;  // tRP
                    `W_TRFC:	cnt_reset_n <= (`end_trfc)  ? 1'b0 : 1'b1;  // tRFC
                    default:    cnt_reset_n <= 1'b0;
                endcase
            end
            default: cnt_reset_n <= 1'b0;
        endcase
    end
endmodule 