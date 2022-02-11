module testbench();

    logic [127:0] data_to_cipher [11];
    logic [127:0] ciphered_data  [11];
    logic clk, resetn, request, ack, valid, busy;
    logic [127:0] data_i, data_o;

    initial clk <= 0;

    always #5ns clk <= ~clk;

    integer i = 0;
    logic [128*11-1:0] print_str;


    kuznechik_cipher DUT(
        .clk_i      (clk),
        .resetn_i   (resetn),
        .data_i     (data_i),
        .request_i  (request),
        .ack_i      (ack),
        .data_o     (data_o),
        .valid_o    (valid),
        .busy_o     (busy)
    );

    initial begin
        data_to_cipher[00] <= 128'hc177d2d35af6d17477545bfcf97d43a4;
        data_to_cipher[01] <= 128'h1b877fafa3ba0026e8ef95de495ac74c;
        data_to_cipher[02] <= 128'hcd84585b9b46f02519d00f7111a34452;
        data_to_cipher[03] <= 128'hfcec82557f40f3310eed30d097b2c368;
        data_to_cipher[04] <= 128'hc6cc2ddec17abc61e995062df1dead37;
        data_to_cipher[05] <= 128'hc0ddbf359d704ad7f52420798f94fc4b;
        data_to_cipher[06] <= 128'hdb434f2542b562db98eb19ef012eadb7;
        data_to_cipher[07] <= 128'hfe59f8e79163e45ec6c47cdf80e4b0c4;
        data_to_cipher[08] <= 128'h295d9b247899b5257b88c319519e6d15;
        data_to_cipher[09] <= 128'h30f6af74f3666a67216db25238be91e2;
        data_to_cipher[10] <= 128'h44bf130e7bcab6a1d2d867280bb89269;
        $display("Testbench has been started.\nResetting");
        resetn <= 1'b0;
        ack <= 0;
        request <= 0;
        repeat(2) begin
            @(posedge clk);
        end
        resetn <= 1'b1;
        for(i=0; i < 11; i++) begin
            $display("Trying to cipher %d chunk of data", i);
            @(posedge clk);
            data_i <= data_to_cipher[i];
            while(busy) begin
                @(posedge clk);
            end
            request <= 1'b1;
            @(posedge clk);
            request <= 1'b0;
            while(~valid) begin
                @(posedge clk);
            end
            ciphered_data[i] <= data_o;
            ack <= 1'b1;
            @(posedge clk);
            ack <= 1'b0;
        end
        $display("Ciphering has been finished.");
        $display("============================");
        $display("===== Ciphered message =====");
        $display("============================");
        print_str = {ciphered_data[0],
                        ciphered_data[1],
                        ciphered_data[2],
                        ciphered_data[3],
                        ciphered_data[4],
                        ciphered_data[5],
                        ciphered_data[6],
                        ciphered_data[7],
                        ciphered_data[8],
                        ciphered_data[9],
                        ciphered_data[10]
                    };
        $display("%s", print_str);
        $display("============================");
        $finish();
    end

endmodule
