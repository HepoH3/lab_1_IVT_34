module kuznechik_cipher(
    input               clk_i,      // Тактовый сигнал
                        resetn_i,   // Синхронный сигнал сброса с активным уровнем LOW
                        request_i,  // Сигнал запроса на начало шифрования
                        ack_i,      // Сигнал подтверждения приема зашифрованных данных
                [127:0] data_i,     // Шифруемые данные

    output              busy_o,     // Сигнал, сообщающий о невозможности приёма
                                    // очередного запроса на шифрование, поскольку
                                    // модуль в процессе шифрования предыдущего
                                    // запроса
           reg          valid_o,    // Сигнал готовности зашифрованных данных
           reg  [127:0] data_o      // Зашифрованные данные
);

reg [127:0] key_mem [0:9];

reg [7:0] S_box_mem [0:255];

reg [7:0] L_mul_16_mem  [0:255];
reg [7:0] L_mul_32_mem  [0:255];
reg [7:0] L_mul_133_mem [0:255];
reg [7:0] L_mul_148_mem [0:255];
reg [7:0] L_mul_192_mem [0:255];
reg [7:0] L_mul_194_mem [0:255];
reg [7:0] L_mul_251_mem [0:255];

initial begin
    $readmemh("keys.mem",key_mem );
    $readmemh("S_box.mem",S_box_mem );

    $readmemh("L_16.mem", L_mul_16_mem );
    $readmemh("L_32.mem", L_mul_32_mem );
    $readmemh("L_133.mem",L_mul_133_mem);
    $readmemh("L_148.mem",L_mul_148_mem);
    $readmemh("L_192.mem",L_mul_192_mem);
    $readmemh("L_194.mem",L_mul_194_mem);
    $readmemh("L_251.mem",L_mul_251_mem);
end

////////////////My part/////////////////////////////////////
reg[2:0]    State;           //                           //
reg[2:0]    StateForward;    //                           //
                             //                           //
localparam  Idle = 0;        //                           //
localparam  Key_phase = 1;   // defines and registers for //
localparam  S_phase = 2;     //     our state machine     //
localparam  L_phase = 3;     //                           //
localparam  Finish = 4;      //                           //
////////////////////////////////////////////////////////////
reg[3:0]    rounds_cnt; 
reg[4:0]    L_phase_cnt;
always @(posedge clk_i or negedge clk_i)
begin
    if (!resetn_i)
    begin
        State <= Idle;
    end
    else
        State <= StateForward;
end

always @(posedge clk_i)
begin
    if (!resetn_i)
    begin
        StateForward <= Idle;
        rounds_cnt <=  'd0;
        L_phase_cnt <= 'd0;
    end
    else
    begin
        if (StateForward == Idle)
        begin
            if (request_i)
            begin
                StateForward <= Key_phase;
                rounds_cnt <= 'd0; 
            end
        end
        else if (StateForward == Key_phase)
        begin
            if (rounds_cnt <'d9)  
                rounds_cnt <= rounds_cnt + 1;
            else
                StateForward <= Finish;
                  
        end
        else if (StateForward == S_phase)
        begin
            StateForward <= L_phase;
            StateForward <= S_phase;
        end
        else if (StateForward == L_phase)
        begin
            if (L_phase_cnt < 'd15)
                L_phase_cnt <= L_phase_cnt + 'd1;
            else
                StateForward <= Key_phase;
        end
        else if (StateForward == Finish)
        begin
            if (request_i)
            begin
                StateForward <= Key_phase;
            end
            else if (ack_i)
            begin
                StateForward <= Idle;
            end
            rounds_cnt <= 'd0;
        end
        else
            StateForward <= Idle;
    end
end
reg[127:0] data;

//////////////////////////////////////////////////////////////////
reg[10:0] clk_cnt;                  //                          //
reg[4:0]  req_cnt;                  //                          //
                                    //                          //
always @(posedge clk_i)             //                          //
begin                               //                          //
    if (!resetn_i)                  //                          //
        req_cnt <= 0;               //                          //
    else if (request_i)             //                          //
    begin                           //                          //
        req_cnt <= req_cnt + 1;     //                          //
        if (req_cnt == 10)          //                          //
        begin                       //                          //
            req_cnt <= 0;           //                          //
            clk_cnt <= 0;           //                          //
        end                         //                          //
    end                             //                          //
end                                 //                          //
always @(posedge clk_i)             //                          //
begin                               //                          //
    if (!resetn_i)                  //  for checking how many   //
        clk_cnt <= 'd0;             //      clks we gonna need  //
    else                            //      for 10 raunds       //
    begin                           //                          //
        clk_cnt <= clk_cnt + 'd1;   //                          //
    end                             //                          //
end                                 //                          //
 /////////////////////////////////////////////////////////////////
always @(posedge clk_i)
begin
    if (!resetn_i)
    begin
        data <= 'b0;
        valid_o <= 0;
    end
    else
    begin
        case(State)
////////////////////////////////////////////////////
            Idle:
            begin
                if (request_i)
                    data <= data_i;
                    valid_o <= 0;
            end
////////////////////////////////////////////////////
            Key_phase:
            begin
                data <= key_mem[rounds_cnt] ^ data;
                valid_o <= 0;
            end 
////////////////////////////////////////////////////
            S_phase: data <= {S_box_mem[data[127:120]], S_box_mem[data[119:112]], S_box_mem[data[111:104]], 
                        S_box_mem[data[103:96]], S_box_mem[data[95:88]], S_box_mem[data[87:80]], 
                        S_box_mem[data[79:72]], S_box_mem[data[71:64]], S_box_mem[data[63:56]], 
                        S_box_mem[data[55:48]], S_box_mem[data[47:40]], S_box_mem[data[39:32]], 
                        S_box_mem[data[31:24]], S_box_mem[data[23:16]], S_box_mem[data[15:8]], S_box_mem[data[7:0]]};
////////////////////////////////////////////////////
            L_phase: data <= {L_mul_148_mem[data[127:120]] ^ L_mul_32_mem[data[119:112]] ^ L_mul_133_mem[data[111:104]] ^ L_mul_16_mem[data[103:96]] ^ L_mul_194_mem[data[95:88]] ^ L_mul_192_mem[data[87:80]] ^ data[79:72] ^ L_mul_194_mem[data[71:64]] ^ data[63:56] ^ L_mul_192_mem[data[55:48]] ^ L_mul_194_mem[data[47:40]] ^ L_mul_16_mem[data[39:32]] ^ L_mul_133_mem[data[31:24]] ^ L_mul_32_mem[data[23:16]] ^ L_mul_148_mem[data[15:8]] ^ data[7:0], data[127 : 8]};
            Finish :
            begin
            valid_o <= 1;
            data_o <= data;
            end
        endcase
    end
end 
assign busy_o = !(State == Idle || State == Finish);

endmodule
