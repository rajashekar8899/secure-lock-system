// --- SECURE DUAL-HARDWARE LOCKING SYSTEM (V1.0) ---
// LEAD LOGIC DESIGNER: T. Rajashekar (24J25A0424 - LE)
// HARDWARE SYSTEMS INTEGRATION: M. Shailusha (23J21A0424)
// SYSTEM FIRMWARE & VERIFICATION: G. Krithin (24J25A0407 - LE)
// INSTITUTION: Joginpally Baskar Rao Engineering College (JBREC)
// DEPARTMENT: Electronics and Communication Engineering (ECE)
// TARGET: Sipeed Tang Nano 20K FPGA
//
// UART CONFIG: TX=Pin 28, RX=Pin 27 (9600 Baud)
// I/O MAP: Sync=Pin 77, Emer=Pin 49, Door=Pin 42, Relay=Pin 86
// KEYPAD: COLs={76, 80, 72, 71}, ROWs={73, 74, 75, 85}

module secure_lock_system (
    input wire clk,       // 27MHz
    input wire ext_sync_btn, // Pin 77
    input wire em_btn,       // Pin 49
    input wire btn_back,  // Pin 48
    input wire btn_enter, // Pin 41
    input wire door_sense, // Pin 42
    input wire [3:0] col, // Columns
    output reg [3:0] row, // Rows
    output reg [5:0] leds, // Pins 15-20 (Active Low: 0=ON)
    output wire relay_out, // Pin 86
    output wire lcd_scl,   // UART TX (Pin 28)
    input  wire lcd_sda    // UART RX (Pin 27)
);

    // Relay is ON (Logic 0) only if Unlocked AND within 10s window
    assign relay_out = (sys_state == 3'd4 && open_tmr < 29'd270_000_000) ? 0 : 1;

    // --- 1. GLOBAL HEARTBEAT & HARDWARE DEBUG ---
    reg [24:0] hb_cnt = 0;
    always @(posedge clk) hb_cnt <= hb_cnt + 25'd1;

    // --- 2. System Boot & Internal Reset (Sim-optimized) ---
    `ifdef SIMULATION
        localparam BOOT_LIMIT = 28'd100;
    `else
        localparam BOOT_LIMIT = 28'd54_000_000;
    `endif
    reg [27:0] b_tmr = 0; reg sys_active = 0;
    initial {b_tmr, sys_active} = 0;
    always @(posedge clk) begin
        if (b_tmr < BOOT_LIMIT) begin b_tmr <= b_tmr + 28'd1; sys_active <= 1'b0; end
        else sys_active <= 1'b1;
    end

    // --- DEBOUNCERS (Bypassed for Sim) ---
    `ifdef SIMULATION
        wire s1_clean = ext_sync_btn;
        wire s2_clean = em_btn;
        wire bck_clean = btn_back;
        wire ent_clean = btn_enter;
        wire dr_clean = door_sense;
        wire s1_sync = (s1_p == 1 && s1_clean == 0); // Pulse needs s1_p
        reg s1_p = 1; always @(posedge clk) s1_p <= s1_clean;
        wire s2_pulse = (s2_p == 1 && s2_clean == 0);
        reg s2_p = 1; always @(posedge clk) s2_p <= s2_clean;
        wire bck_pulse = (bck_p == 1 && bck_clean == 0);
        reg bck_p = 1; always @(posedge clk) bck_p <= bck_clean;
        wire ent_pulse = (ent_p == 1 && ent_clean == 0);
        reg ent_p = 1; always @(posedge clk) ent_p <= ent_clean;
    `else
        localparam DB_LIMIT = 22'd1_350_000;
        localparam DR_LIMIT = 22'd675_000;
        reg s1_p = 1; reg s1_sync = 0; reg [21:0] s1_db = 0; reg s1_clean = 1;
        always @(posedge clk) begin
            if (ext_sync_btn == s1_clean) s1_db <= 22'd0;
            else if (s1_db < 22'd1_350_000) s1_db <= s1_db + 22'd1;
            else begin s1_db <= 0; s1_clean <= ext_sync_btn; end
            s1_p <= s1_clean; s1_sync <= (s1_p == 1 && s1_clean == 0); 
        end
        reg s2_p = 1; reg s2_pulse = 0; reg [21:0] s2_db = 0; reg s2_clean = 1;
        always @(posedge clk) begin
            if (em_btn == s2_clean) s2_db <= 22'd0;
            else if (s2_db < 22'd1_350_000) s2_db <= s2_db + 22'd1;
            else begin s2_db <= 0; s2_clean <= em_btn; end
            s2_p <= s2_clean; s2_pulse <= (s2_p == 1 && s2_clean == 0); 
        end
        reg bck_p = 1; reg bck_pulse = 0; reg [21:0] bck_db = 0; reg bck_clean = 1;
        always @(posedge clk) begin
            if (btn_back == bck_clean) bck_db <= 22'd0;
            else if (bck_db < 22'd1_350_000) bck_db <= bck_db + 22'd1;
            else begin bck_db <= 0; bck_clean <= btn_back; end
            bck_p <= bck_clean; bck_pulse <= (bck_p == 1 && bck_clean == 0);
        end
        reg ent_p = 1; reg ent_pulse = 0; reg [21:0] ent_db = 0; reg ent_clean = 1;
        always @(posedge clk) begin
            if (btn_enter == ent_clean) ent_db <= 22'd0;
            else if (ent_db < 22'd1_350_000) ent_db <= ent_db + 22'd1;
            else begin ent_db <= 0; ent_clean <= btn_enter; end
            ent_p <= ent_clean; ent_pulse <= (ent_p == 1 && ent_clean == 0);
        end
        reg dr_clean = 1; reg [21:0] dr_db = 0;
        always @(posedge clk) begin
            if (door_sense == dr_clean) dr_db <= 22'd0;
            else if (dr_db < DR_LIMIT) dr_db <= dr_db + 22'd1; 
            else begin dr_db <= 0; dr_clean <= door_sense; end
        end
    `endif

    // --- 3. Keypad Scanner (Sim-optimized) ---
    `ifdef SIMULATION
        localparam SC_LIMIT = 21'd1000;
        localparam SC_SAMP  = 21'd500;
    `else
        localparam SC_LIMIT = 21'd1_080_000;
        localparam SC_SAMP  = 21'd1_000_000;
    `endif
    reg [20:0] sc_tmr = 0; reg [1:0] sc_idx = 0;
    reg [3:0] k_cap = 0; reg k_vld = 0;
    always @(posedge clk) begin
        if (!sys_active) begin sc_tmr <= 0; sc_idx <= 0; row <= 4'b1110; k_vld <= 0; end
        else begin
            if (sc_tmr < SC_LIMIT) begin
                sc_tmr <= sc_tmr + 21'd1;
                if (sc_tmr == SC_SAMP) begin
                   if (col != 4'b1111) begin 
                       k_cap <= decode_matrix(row, col); 
                       k_vld <= 1; 
                   end
                   else k_vld <= 0;
                end
            end else begin
                sc_tmr <= 21'd0; sc_idx <= sc_idx + 2'd1;
                case (sc_idx)
                    2'd0: row <= 4'b1110; // Row 0
                    2'd1: row <= 4'b1101; // Row 1
                    2'd2: row <= 4'b1011; // Row 2
                    2'd3: row <= 4'b0111; // Row 3
                endcase
            end
        end
    end

    reg k_lock = 0; reg k_pulse = 0; reg [3:0] k_cur = 0;
    always @(posedge clk) begin
        if (k_vld && !k_lock) begin k_lock <= 1; k_pulse <= 1; k_cur <= k_cap; end
        else if (!k_vld) begin k_lock <= 0; k_pulse <= 0; end
        else k_pulse <= 0;
    end

    // --- 4. Logic & Alerts ---
    reg [2:0] sys_state; reg [15:0] token; reg [5:0] timer_val; reg [31:0] entry_buf; reg [3:0] e_ptr;
    reg [29:0] open_tmr = 0; reg door_was_opened = 0; reg boot_done = 0; 
    reg [27:0] a_tmr = 0; reg [1:0] a_mode = 0; reg a_sync = 0;
    wire [31:0] em_code = 32'h27168899; 
    reg em_mode = 1'b0;           
    reg sys_ready;             
    reg fully_armed = 1'b0; // 0 = Startup, 1 = Armed (Tamper Detection Active)
    reg [3:0] rx_p = 0; reg [15:0] rx_seed = 0;
    reg [7:0] rx_byte; reg rx_byte_vld = 0;
    reg [3:0] reboot_burst_cnt = 0; reg sys_active_p = 0; reg reboot_req = 0;
    reg tamper_latched = 1'b0; // 1 = System trapped in Malfunction until Emergency Code
    reg tamper_lockout = 1'b0; // 1 = Emergency Button killed until manual Reset
    reg cancel_req = 0; reg [1:0] cancel_burst_cnt = 0;
    reg [24:0] sec_tk = 0; reg [31:0] tkn_tk = 0;
    reg [25:0] s2_hold = 0;
    
    initial begin 
        sys_state=0; token=16'h0000; timer_val=6'd60; entry_buf=0; e_ptr=0; a_tmr=0; a_mode=0; sys_ready=0; reboot_req = 1'b0; reboot_burst_cnt = 4'd0;
    end

    // --- MAIN LOGIC ENGINE ---
    always @(posedge clk) begin
        if (!sys_active) begin
            sys_state <= 3'd0; token <= 16'h0000; timer_val <= 6'd60; entry_buf <= 32'd0; e_ptr <= 4'd0; a_mode <= 2'd0; sys_ready <= 1'b0;
            sec_tk <= 25'd0; tkn_tk <= 32'd0; reboot_req <= 1'b0; s2_hold <= 26'd0;
            a_sync <= 0; open_tmr <= 0; door_was_opened <= 0; boot_done <= 0;
        end else begin
            sys_active_p <= sys_active;
            if (sys_active && !sys_active_p) begin 
                reboot_req <= 1'b1; reboot_burst_cnt <= 4'd10;
            end else if (s1_sync) begin 
                reboot_req <= 1'b1; reboot_burst_cnt <= 4'd10;
                token <= 16'h0000; timer_val <= 6'd60; entry_buf <= 32'd0;
                a_mode <= 2'd1; a_tmr <= 28'd135_000_000; sys_ready <= 1'b0; open_tmr <= 0; door_was_opened <= 0; boot_done <= 0;
                
                // SECURE RESET WITH CLEAN CLOSURE REQUIREMENT
                if (tamper_latched) begin
                    // If in a deep tamper state, reboot straight back into Malfunction
                    sys_state <= 3'd5;
                    // LOCKOUT persists if reset happens while door is still open (dr_clean=1)
                    tamper_lockout <= dr_clean; 
                end else if (dr_clean == 1) begin
                    // If reset while door is open: Force ARMED Malfunction and Lockout
                    sys_state <= 3'd5;
                    tamper_latched <= 1'b1;
                    tamper_lockout <= 1'b1;
                end else begin
                    // If reset while door is closed: Clean Startup
                    sys_state <= 3'd0;
                    fully_armed <= 0;
                    tamper_lockout <= 1'b0;
                end
            end else begin
            if (!boot_done) begin
                if (tamper_latched) begin
                    // If we have a stored tamper, return to Malfunction regardless of door position
                    sys_state <= 3'd5;
                    fully_armed <= 1;
                end else if (dr_clean == 1) begin
                    // Initial startup: Door is open, show Malfunction but allow auto-clear once
                    sys_state <= 3'd5;
                    fully_armed <= 0;
                end else begin
                    // Normal startup: Door is closed, arm immediately
                    sys_state <= 3'd0;
                    fully_armed <= 1;
                end
                boot_done <= 1;
            end else begin
                // SMART ARMING & SECURITY MONITOR
                if (!fully_armed) begin
                    // Still in the Startup/Arming phase
                    if (dr_clean == 0) begin 
                        fully_armed <= 1; 
                        if (sys_state == 3'd5) begin sys_state <= 3'd0; door_was_opened <= 0; end
                    end
                end else begin
                    // System is ARMED. Monitor for Tamper.
                    // Monitor for Tamper (dr_clean=1 is open)
                    if (sys_state != 3'd4 && dr_clean == 1 && !em_mode) begin
                        sys_state <= 3'd5; // TRIGGER MALFUNCTION
                        tamper_latched <= 1'b1; // LATCH TAMPER MEMORY
                        tamper_lockout <= 1'b1; // KILL EMERGENCY BUTTON
                        door_was_opened <= 1;
                    end
                end
            end

            // SMART SENSORY RELOCKING
            if (sys_state == 3'd4) begin
                if (open_tmr < 30'd540_000_000) open_tmr <= open_tmr + 30'd1; // Extended watchdog (20s)
                
                // Sensor detection with grace period
                if (open_tmr > 30'd54_000_000) begin
                    if (dr_clean == 1) door_was_opened <= 1;
                end

                // State Transition Logic
                if (door_was_opened) begin
                    // Once opened, we wait ONLY for it to close
                    if (dr_clean == 0) begin
                        sys_state <= 3'd0; door_was_opened <= 0; open_tmr <= 0;
                    end
                end else if (open_tmr >= 30'd270_000_000) begin
                    // If never opened, relock after 10s for security
                    sys_state <= 3'd0; door_was_opened <= 0; open_tmr <= 0;
                end
            end

            // PAUSE ROTATION WHEN UNLOCKED
            if (sys_ready && sys_state != 3'd4) begin
                if (sec_tk < 25'd27000000) sec_tk <= sec_tk + 25'd1;
                else begin sec_tk <= 0; if (timer_val > 0) timer_val <= timer_val - 6'd1; end
                if (tkn_tk < 32'd1620000000) tkn_tk <= tkn_tk + 32'd1;
                else begin 
                    tkn_tk <= 0; timer_val <= 6'd60; sec_tk <= 0;
                    if (token == 16'h0000) token <= 16'hACE1; // LFSR Zero-State Rescue
                    else token <= (token << 1) | (token[15]^token[13]^token[12]^token[10]); 
                end
            end
            if (a_tmr > 0) a_tmr <= a_tmr - 28'd1; else begin a_mode <= 2'd0; a_sync <= 1'b0; end

            if (bck_pulse || (k_pulse && (k_cur == 4'hE || k_cur == 4'hD))) begin
                if (e_ptr > 0) begin entry_buf <= entry_buf >> 4; e_ptr <= e_ptr - 4'd1; end
                else if (em_mode) em_mode <= 1'b0; 
                else begin cancel_req <= 1'b1; cancel_burst_cnt <= 2'd3; end
            end

            if (k_pulse && a_mode == 2'd0 && sys_state != 3'd4) begin
                if (em_mode && e_ptr < 4'd8) begin
                    entry_buf <= (entry_buf << 4) | {28'd0, k_cur}; e_ptr <= e_ptr + 4'd1;
                end else if (!em_mode && e_ptr < 4'd4) begin
                    entry_buf <= (entry_buf << 4) | {28'd0, k_cur}; e_ptr <= e_ptr + 4'd1;
                end
            end

            if (ent_pulse && sys_state != 3'd4 && e_ptr > 0) begin
                if (em_mode) begin
                    if (tamper_latched) begin
                        // SPECIAL: Clear Malfunction with 4-Digit '2716' Only
                        if (e_ptr == 4'd4 && entry_buf[15:0] == 16'h2716) begin
                            sys_state <= 3'd0;
                            tamper_latched <= 1'b0;
                            em_mode <= 1'b0; e_ptr <= 4'd0; entry_buf <= 32'd0; open_tmr <= 0; door_was_opened <= 0;
                            fully_armed <= 1'b1;
                        end else begin
                            // Wrong Clear Code -> Fail
                            sys_state <= 3'd0; a_tmr <= 28'd135_000_000; a_mode <= 2'd2; em_mode <= 1'b0; e_ptr <= 4'd0; entry_buf <= 32'd0;
                        end
                    end else begin
                        // NORMAL: 8-Digit Emergency Unlock
                        if (e_ptr == 4'd8 && entry_buf == em_code) begin
                            sys_state <= 3'd4;
                            em_mode <= 1'b0; e_ptr <= 4'd0; entry_buf <= 32'd0; open_tmr <= 0; door_was_opened <= 0;
                            fully_armed <= 1'b1;
                        end else begin
                            // Wrong Unlock Code -> Fail
                            sys_state <= 3'd0; a_tmr <= 28'd135_000_000; a_mode <= 2'd2; em_mode <= 1'b0; e_ptr <= 4'd0; entry_buf <= 32'd0;
                        end
                    end
                end else if (sys_ready) begin
                    if (e_ptr == 4'd4 && entry_buf[15:0] == token) begin
                        sys_state <= 3'd4; e_ptr <= 4'd0; entry_buf <= 32'd0; open_tmr <= 0; door_was_opened <= 0;
                    end else begin
                        sys_state <= 3'd0; a_tmr <= 28'd135_000_000; a_mode <= 2'd2; e_ptr <= 4'd0; entry_buf <= 32'd0;
                    end
                end else begin
                    sys_state <= 3'd0; a_tmr <= 28'd135_000_000; a_mode <= 2'd2; e_ptr <= 4'd0; entry_buf <= 32'd0;
                end
            end
            
            if (s2_clean == 1'b0 && !em_mode) begin 
                // Emergency Button is KILLED (Lockout) if a tamper happened.
                // It stays dead even if door is closed, until manual RESET (Pin 77).
                if (tamper_lockout) begin
                    s2_hold <= 0;
                end else if (tamper_latched && dr_clean == 1) begin
                    // Also disabled if door is physically open during malfunction
                    s2_hold <= 0;
                end else begin
                    `ifdef SIMULATION
                        // Instant trigger for simulation
                        if (s2_clean == 1'b0) begin em_mode <= 1; sys_state <= 0; e_ptr <= 4'd0; entry_buf <= 32'd0; s2_hold <= 0; end
                    `else
                        if (s2_hold < 26'd54_000_000) s2_hold <= s2_hold + 26'd1;
                        else begin em_mode <= 1; sys_state <= 0; e_ptr <= 4'd0; entry_buf <= 32'd0; s2_hold <= 0; end
                    `endif
                end
            end else s2_hold <= 0;

            if (rx_byte_vld) begin
                if (rx_byte == 8'h21) begin rx_p <= 4'd1; rx_seed <= 16'd0; end
                else if (rx_p == 4'd1) begin if (rx_byte == 8'h49) rx_p <= 4'd2; else rx_p <= 4'd0; end
                else if (rx_p >= 4'd2 && rx_p <= 4'd5) begin
                    if (rx_p == 4'd5) begin 
                        token <= {rx_seed[11:0], (rx_byte >= 8'h41 ? (4'd10 + rx_byte[3:0] - 4'd1) : rx_byte[3:0])};
                        sys_ready <= 1'b1; rx_p <= 4'd0; timer_val <= 6'd60; sec_tk <= 25'd0; tkn_tk <= 32'd0; 
                        a_sync <= 1'b1; a_tmr <= 28'd27_000_000;
                    end else begin
                        rx_seed <= {rx_seed[11:0], (rx_byte >= 8'h41 ? (4'd10 + rx_byte[3:0] - 4'd1) : rx_byte[3:0])};
                        rx_p <= rx_p + 4'd1;
                    end
                end else rx_p <= 4'd0;
            end
            if (u_p == 5'd2 && u_kick && (reboot_req || cancel_req)) begin
                if (reboot_req) begin
                    if (reboot_burst_cnt > 0) reboot_burst_cnt <= reboot_burst_cnt - 4'd1;
                    else reboot_req <= 1'b0;
                end else begin
                    if (cancel_burst_cnt > 0) cancel_burst_cnt <= cancel_burst_cnt - 2'd1;
                    else cancel_req <= 1'b0;
                end
            end
        end
    end
end

    always @(posedge clk) begin
        leds[0] <= reboot_req ? hb_cnt[21] : ext_sync_btn; // LED0: Sync (Flicker on Reset)
        leds[1] <= em_btn;          // LED1: Emergency Button (Direct Monitor)
        leds[2] <= btn_back;        // LED2: Back Button (Direct Monitor)
        leds[3] <= btn_enter;       // LED3: Enter Button (Direct Monitor)
        leds[4] <= door_sense;      // LED4: Door Sensor (Direct Monitor)
        leds[5] <= hb_cnt[24];      // LED5: Heartbeat
    end

    wire [7:0] u_tx_b; wire u_kick; wire u_busy;
    uart_paced_logic u_inst (.clk(clk), .rst_n(1'b1), .d(u_tx_b), .s(u_kick), .p(lcd_scl), .b(u_busy));

    reg [4:0] u_p = 5'd0; reg [25:0] u_g = 26'd0; reg u_k_reg = 0;
    always @(posedge clk) begin
        if (u_g < 26'd2_700_000) begin u_g <= u_g + 26'd1; u_p <= 5'd0; u_k_reg <= 1'b0; end
        else begin
            if (u_p == 5'd0) begin u_p <= 5'd1; u_k_reg <= 1'b1; end
            else if (!u_busy && !u_k_reg) begin
                if (u_p < 5'd23) begin u_p <= u_p + 5'd1; u_k_reg <= 1'b1; end
                else begin u_g <= 26'd0; u_p <= 5'd0; end
            end else u_k_reg <= 1'b0;
        end
    end
    assign u_kick = u_k_reg;

    wire [5:0] t_sub = (timer_val >= 6'd60) ? (timer_val - 6'd60) : 
                       (timer_val >= 6'd50) ? (timer_val - 6'd50) : 
                       (timer_val >= 6'd40) ? (timer_val - 6'd40) : 
                       (timer_val >= 6'd30) ? (timer_val - 6'd30) : 
                       (timer_val >= 6'd20) ? (timer_val - 6'd20) : 
                       (timer_val >= 6'd10) ? (timer_val - 6'd10) : timer_val;
    wire [3:0] tm = (timer_val >= 6'd60) ? 4'd6 : (timer_val >= 6'd50) ? 4'd5 : (timer_val >= 6'd40) ? 4'd4 :
                    (timer_val >= 6'd30) ? 4'd3 : (timer_val >= 6'd20) ? 4'd2 : (timer_val >= 6'd10) ? 4'd1 : 4'd0;
    wire [3:0] tl = t_sub[3:0];

    reg [7:0] stat_char;
    always @(*) begin
        if (!sys_active) stat_char = 8'h42;      
        else if (em_mode) stat_char = 8'h58;     
        else if (rx_p != 4'd0) stat_char = 8'h49; 
        else if (!sys_ready) stat_char = 8'h57;  
        // Door sense is only a malfunction if we are in LOCKED mode
        else if (dr_clean == 1'b1 && sys_state == 3'd0) stat_char = 8'h4D; 
        else if (sys_state == 3'd5) stat_char = 8'h4D; // Explicitly report state 5 as Malfunction
        else if (a_mode == 2'd1 || a_sync) stat_char = 8'h52; 
        else if (a_mode == 2'd2) stat_char = 8'h45; 
        else if (sys_state == 3'd4) stat_char = 8'h55; 
        else stat_char = 8'h4C;                  
    end

    assign u_tx_b = (u_p == 5'd1) ? 8'h21 : 
                    (u_p == 5'd2) ? (reboot_req ? 8'h52 : (cancel_req ? 8'h58 : 8'h53)) : 
                    (u_p == 5'd3) ? stat_char : (u_p == 5'd4) ? 8'h21 : (u_p == 5'd5) ? 8'h54 :
                    (u_p == 5'd6) ? h(token[15:12]) : (u_p == 5'd7) ? h(token[11:8]) : (u_p == 5'd8) ? h(token[7:4]) : (u_p == 5'd9) ? h(token[3:0]) :
                    (u_p == 5'd10)? 8'h21 : (u_p == 5'd11)? 8'h43 : (u_p == 5'd12)? h(tm) : (u_p == 5'd13)? h(tl) : (u_p == 5'd14)? 8'h21 : (u_p == 5'd15)? 8'h4B :
                    (u_p == 5'd16)? (em_mode ? (e_ptr < 4'd8 ? 8'h5F : h(entry_buf[31:28])) : (e_ptr < 4'd4 ? 8'h5F : h(entry_buf[15:12]))) :
                    (u_p == 5'd17)? (em_mode ? (e_ptr < 4'd7 ? 8'h5F : h(entry_buf[27:24])) : (e_ptr < 4'd3 ? 8'h5F : h(entry_buf[11:8]))) :
                    (u_p == 5'd18)? (em_mode ? (e_ptr < 4'd6 ? 8'h5F : h(entry_buf[23:20])) : (e_ptr < 4'd2 ? 8'h5F : h(entry_buf[7:4]))) :
                    (u_p == 5'd19)? (em_mode ? (e_ptr < 4'd5 ? 8'h5F : h(entry_buf[19:16])) : (e_ptr < 4'd1 ? 8'h5F : h(entry_buf[3:0]))) :
                    (u_p == 5'd20)? (em_mode ? (e_ptr < 4'd4 ? 8'h5F : h(entry_buf[15:12])) : 8'h20) :
                    (u_p == 5'd21)? (em_mode ? (e_ptr < 4'd3 ? 8'h5F : h(entry_buf[11:8])) : 8'h20) : 
                    (u_p == 5'd22)? (em_mode ? (e_ptr < 4'd2 ? 8'h5F : h(entry_buf[7:4])) : 8'h20) : 
                    (em_mode ? (e_ptr < 4'd1 ? 8'h5F : h(entry_buf[3:0])) : 8'h20);

    reg [2:0] rx_st = 0; reg [13:0] rx_c = 0; reg [3:0] rx_b = 0;
    always @(posedge clk) begin
        case(rx_st)
            3'd0: begin rx_byte_vld <= 1'b0; if(!lcd_sda) begin rx_c <= 14'd0; rx_st <= 3'd1; end end
            3'd1: if(rx_c < 14'd1406) rx_c <= rx_c + 14'd1; else begin rx_c <= 14'd0; if(!lcd_sda) begin rx_st <= 3'd2; rx_b <= 4'd0; end else rx_st <= 3'd0; end
            3'd2: if(rx_c < 14'd2812) rx_c <= rx_c + 14'd1; else begin rx_c <= 14'd0; rx_byte <= {lcd_sda, rx_byte[7:1]}; if(rx_b < 4'd7) rx_b <= rx_b + 4'd1; else rx_st <= 3'd3; end
            3'd3: if(rx_c < 14'd2812) rx_c <= rx_c + 14'd1; else begin rx_c <= 14'd0; rx_st <= 3'd0; if(lcd_sda) rx_byte_vld <= 1'b1; end
            default: rx_st <= 3'd0;
        endcase
    end
    function [7:0] h; input [3:0] v; begin if (v < 4'd10) h = 8'd48 + {4'd0, v}; else h = 8'd65 + {4'd0, v - 4'd10}; end endfunction
    function [3:0] decode_matrix; input [3:0] r, c;
        // FINAL MAPPING: Based on "A->A, B->3, C->2, D->1" Feedback
        // logical c[0] = Physical Col 4 (A,B,C,D)
        // logical c[3] = Physical Col 1 (1,4,7,*)
        // logical r[3] = Physical Row 1 (Top)
        // logical r[0] = Physical Row 4 (Bottom)
        case (c)
            // Column 4 (A, B, C, D) Input = 1110
            4'b1110: case(r) 4'b0111: decode_matrix=4'hA; 4'b1011: decode_matrix=4'hB; 4'b1101: decode_matrix=4'hC; 4'b1110: decode_matrix=4'hD; default: decode_matrix=4'hC; endcase 
            // Column 3 (3, 6, 9, #/F) Input = 1101
            4'b1101: case(r) 4'b0111: decode_matrix=4'h3; 4'b1011: decode_matrix=4'h6; 4'b1101: decode_matrix=4'h9; 4'b1110: decode_matrix=4'hF; default: decode_matrix=4'hC; endcase 
            // Column 2 (2, 5, 8, 0) Input = 1011
            4'b1011: case(r) 4'b0111: decode_matrix=4'h2; 4'b1011: decode_matrix=4'h5; 4'b1101: decode_matrix=4'h8; 4'b1110: decode_matrix=4'h0; default: decode_matrix=4'hC; endcase 
            // Column 1 (1, 4, 7, */E) Input = 0111
            4'b0111: case(r) 4'b0111: decode_matrix=4'h1; 4'b1011: decode_matrix=4'h4; 4'b1101: decode_matrix=4'h7; 4'b1110: decode_matrix=4'hE; default: decode_matrix=4'hC; endcase 
            default: decode_matrix = 4'hC;
        endcase
    endfunction
endmodule

module uart_paced_logic (input wire clk, input wire rst_n, input wire [7:0] d, input wire s, output reg p, output reg b);
    localparam BP = 27000000 / 9600;
    reg [24:0] c = 0; reg [3:0] i = 0; reg [9:0] l; reg [1:0] st = 0;
    always @(posedge clk) begin
        if (!rst_n) begin st <= 0; p <= 1; b <= 0; end
        else begin
            case (st)
                0: begin b <= 1'b0; p <= 1'b1; if (s) begin l <= {1'b1, d, 1'b0}; st <= 2'd1; b <= 1'b1; c <= 25'd0; i <= 4'd0; end end
                1: begin p <= l[0]; if (c < BP-25'd1) c <= c + 25'd1; else begin c <= 25'd0; st <= 2'd2; i <= 4'd1; end end
                2: begin p <= l[i]; if (c < BP-25'd1) c <= c + 25'd1; else begin c <= 25'd0; if (i < 4'd9) i <= i + 4'd1; else begin st <= 2'd0; b <= 1'b0; end end end
            endcase
        end
    end
endmodule
