module sdram_cmd(
    input             clk,			    // clock
    input             reset_n,          // reset_n
    
    input      [23:0] sys_wraddr,		// sdram write address
    input      [23:0] sys_rdaddr,		// sdram read address
    input      [ 9:0] sdram_wr_burst,	// sdram write burst length
    input      [ 9:0] sdram_rd_burst,	// sdram read burst length
    
    input      [ 4:0] init_state,		// sdram initial fsm state
    input      [ 3:0] work_state, 		// sdram working fsm state
    input      [ 9:0] cnt_clk,		    // delay count
    input             sdram_rd_wr,	    // w/r:0/1
    
    // sdram interface
    output            sdram_cke,
    output            sdram_cs_n,
    output            sdram_ras_n,
    output            sdram_cas_n,
    output            sdram_we_n,
    output reg [ 1:0] sdram_bs,
    output reg [12:0] sdram_addr
);
    
    `include "sdram_para.v"

    reg  [ 4:0] sdram_cmd_r;            // sdram command
    wire [23:0] sys_addr;               // sdram address
    
    assign { sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n } = sdram_cmd_r;   // sdram command
    assign sys_addr = sdram_rd_wr ? sys_rdaddr : sys_wraddr;                                // sdram address
    
    // sdram op and address line
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            sdram_cmd_r <= `CMD_INIT;
            sdram_bs    <= 2'b11;
            sdram_addr  <= 13'h1fff;
        end
        else
        begin
            case(init_state)                   
                `I_NOP,`I_TRP,`I_TRF,`I_TRSC:           // NOP
                begin
                    sdram_cmd_r <= `CMD_NOP;
                    sdram_bs    <= 2'b11;
                    sdram_addr  <= 13'h1fff;	
                end
                `I_PRE:                                 // Precharge
                begin
                    sdram_cmd_r <= `CMD_PRGE;
                    sdram_bs    <= 2'b11;
                    sdram_addr  <= 13'h1fff;
                end 
                `I_AR:                                  // Auto Refresh
                begin
                    sdram_cmd_r <= `CMD_A_REF;
                    sdram_bs    <= 2'b11;
                    sdram_addr  <= 13'h1fff;						
                end 			 	
                `I_MRS:                                 // Load Mode Register
                begin
                    sdram_cmd_r <= `CMD_LMR;
                    sdram_bs    <= 2'b00;
                    sdram_addr  <= {
                                        3'b000,		    // A12-10   Reserved
                                        1'b0,		    // A9       Burst Read and Burst Write
                                        2'b00,		    // A8-A7    Reserved
                                        3'b011,		    // A6-A4    CAS = 3
                                        1'b0,		    // A3       Addressing Mode = Sequential
                                        3'b111          // A2-A0    Burst Length = Full Page
                                   };
                    end
                `I_DONE:                                // initial done
                begin
                    case(work_state)                
                        `W_IDLE,`W_TRCD,`W_CL,`W_TWR,`W_TRP,`W_TRFC:    // NOP
                        begin
                            sdram_cmd_r <= `CMD_NOP;
                            sdram_bs    <= 2'b11;
                            sdram_addr  <= 13'h1fff;
                        end
                        `W_ACTIVE:                                      // ACTIVE
                        begin
                            sdram_cmd_r <= `CMD_ACTIVE;
                            sdram_bs    <= sys_addr[23:22];
                            sdram_addr  <= sys_addr[21:9];
                        end
                        `W_READ:                                        // READ
                        begin
                            sdram_cmd_r <= `CMD_READ;
                            sdram_bs    <= sys_addr[23:22];
                            sdram_addr  <= {4'b0000,sys_addr[8:0]};
                        end
                        `W_RD:                                          // READ BURST STOP
                        begin
                            if(`end_rdburst) 
                                sdram_cmd_r <= `CMD_B_STOP;
                            else
                            begin
                                sdram_cmd_r <= `CMD_NOP;
                                sdram_bs    <= 2'b11;
                                sdram_addr  <= 13'h1fff;
                            end
                        end								
                        `W_WRITE:                                       // WRITE
                        begin
                            sdram_cmd_r <= `CMD_WRITE;
                            sdram_bs    <= sys_addr[23:22];
                            sdram_addr  <= {4'b0000,sys_addr[8:0]};
                        end		
                        `W_WD:                                          // WRITE BURST STOP
                        begin
                            if(`end_wrburst) 
                                sdram_cmd_r <= `CMD_B_STOP;
                            else
                            begin
                                sdram_cmd_r <= `CMD_NOP;
                                sdram_bs    <= 2'b11;
                                sdram_addr  <= 13'h1fff;
                            end
                        end
                        `W_PRE:                                         // PRECHARGE
                        begin
                            sdram_cmd_r <= `CMD_PRGE;
                            sdram_bs    <= sys_addr[23:22];
                            sdram_addr  <= 13'h0000;
                        end				
                        `W_AR:                                          // AUTO REFRESH
                        begin
                            sdram_cmd_r <= `CMD_A_REF;
                            sdram_bs    <= 2'b11;
                            sdram_addr  <= 13'h1fff;
                        end
                        default:
                        begin
                            sdram_cmd_r <= `CMD_NOP;
                            sdram_bs    <= 2'b11;
                            sdram_addr  <= 13'h1fff;
                        end
                    endcase
                end
                default:
                begin
                    sdram_cmd_r <= `CMD_NOP;
                    sdram_bs    <= 2'b11;
                    sdram_addr  <= 13'h1fff;
                end
            endcase
        end
    end
endmodule 