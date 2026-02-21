// --- SECURE DUAL-HARDWARE LOCKING SYSTEM: BRIDGE MODULE (V1.0) ---
// LEAD LOGIC DESIGNER: T. Rajashekar (24J25A0424 - LE)
// HARDWARE SYSTEMS INTEGRATION: M. Shailusha (23J21A0424)
// SYSTEM FIRMWARE & VERIFICATION: G. Krithin (24J25A0407 - LE)
// INSTITUTION: Joginpally Baskar Rao Engineering College (JBREC)
#include <esp_now.h>
#include <WiFi.h>
#include <Wire.h>
#include <Preferences.h>
#include <LiquidCrystal_I2C.h>
#include <esp_wifi.h>

// --- SECURE CONFIGURATION ---
uint8_t tokenAddress[6] = {0, 0, 0, 0, 0, 0}; 
uint8_t broadcastAddress[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
bool bootPairing = false; // Hold button at boot

LiquidCrystal_I2C lcd(0x27, 16, 2);
Preferences prefs;

enum SystemState { STATE_IDLE, STATE_SEARCHING, STATE_PAIRING, STATE_CONNECTED, STATE_LOST, STATE_ADMIN, STATE_FOUND };
SystemState currentState = STATE_IDLE;

typedef struct struct_message {
    char token[5];
    char countdown[3];
    char status;
    uint8_t flags; // Bit 0: HB, Bit 1: Admin Req
    uint32_t signature; // Secure Handshake ID
} struct_message;

struct_message outgoingData;
String masterEmergencyCode = "27168899";
bool adminTokenReq = false;
unsigned long adminHoldStart = 0;
String current_token = "----";
String current_countdown = "60";
char current_status = 'L';
char last_status = 'L';
String current_keys = "____";
String tokenAddressStr = "";
unsigned long msgTimer = 0;
String persistentMsg = "";
String pLine2 = "";
unsigned long lastAutoSync = 0;
unsigned long stateTimer = 0;
bool redraw = true;
bool hb_dot = false;
bool tokenPresent = false;
unsigned long lastRecvTime = 0;
bool secureSerialActive = false;
String serialInput = "";
unsigned long lastUARTTime = 0; // FPGA Watchdog
bool fpgaLive = false;
unsigned long sessionStart = 0;
unsigned long sleepTimerStart = 0; 
unsigned long lastSerialActivity = 0;

const unsigned long SESSION_DURATION = 300000; // 5 Minutes Pairing Timeout
const unsigned long MASTER_SLEEP_LIMIT = 600000; // 10 Minutes Locked Sleep

void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {}

void injectNewSeed() {
    uint32_t seed = esp_random() & 0xFFFF;
    char seedCmd[15]; sprintf(seedCmd, "!I%04X", seed);
    for(int i=0; seedCmd[i] != '\0'; i++) {
      Serial2.print(seedCmd[i]);
      delay(5);
    }
}

void pushCodesToFPGA() {
  char cmd[15]; sprintf(cmd, "!P%s", masterEmergencyCode.c_str());
  for(int i=0; cmd[i] != '\0'; i++) { Serial2.print(cmd[i]); delay(5); }
}

void addTokenAsPeer(const uint8_t *mac) {
    esp_now_peer_info_t peerInfo;
    memset(&peerInfo, 0, sizeof(peerInfo));
    memcpy(peerInfo.peer_addr, mac, 6);
    peerInfo.channel = 0; 
    peerInfo.encrypt = false;
    // Remove if already exists to avoid errors on re-pairing
    esp_now_del_peer(mac);
    if (esp_now_add_peer(&peerInfo) == ESP_OK) {
        secureSerialPrint("TOKEN PHYSICALLY PAIRED & REGISTERED.");
    }
}

void saveTokenMAC(const uint8_t *mac) {
    prefs.begin("lock", false);
    prefs.putBytes("tmac", mac, 6);
    prefs.end();
    memcpy(tokenAddress, mac, 6);
    addTokenAsPeer(mac); // Register peer immediately
}

void OnDataRecv(const uint8_t * mac, const uint8_t *incoming, int len) {
  // Allow MAC learning during boot-pairing OR search mode
  if (bootPairing || currentState == STATE_SEARCHING) {
      if (len >= sizeof(struct_message)) {
          struct_message *msg = (struct_message*)incoming;
          if (msg->signature == 0x2716BACE) {
              saveTokenMAC(mac);
              bootPairing = false;
              currentState = STATE_FOUND;
              stateTimer = millis();
              redraw = true;
              secureSerialPrint("PAIRING SUCCESSFUL: MAC LEARNED.");
              return;
          }
      }
  }

  bool match = true;
  for(int i=0; i<6; i++) if(mac[i] != tokenAddress[i]) match = false;
  
  if (match || bootPairing || currentState == STATE_SEARCHING) {
    if (len >= sizeof(struct_message)) {
      struct_message *msg = (struct_message*)incoming;
      // VERIFY HARDWARE SIGNATURE
      if (msg->signature != 0x2716BACE) {
          secureSerialPrint("UNAUTHORIZED DEVICE DETECTED! INVALID SIGNATURE.");
          return;
      }
      
      // If we are in searching/pairing and match is false, we found a NEW token
      if (!match) {
        saveTokenMAC(mac);
      }

      lastRecvTime = millis();
      tokenPresent = true;
      memcpy(&outgoingData, incoming, sizeof(outgoingData)); // Sync internal state
      adminTokenReq = (msg->flags & 0x02);
      
      // Transition to FOUND only if we aren't already progressing through the handshake
      if (currentState == STATE_SEARCHING || bootPairing) {
        currentState = STATE_FOUND;
        stateTimer = millis(); 
        redraw = true;
      }
    }
  }
}

void secureSerialPrint(String msg) {
  if (secureSerialActive && (millis() - lastSerialActivity < 120000)) {
    Serial.println("[DEB] " + msg);
  } else if (secureSerialActive) {
    secureSerialActive = false;
    Serial.println("\n[SECURITY] DEBUG SESSION TIMED OUT. RE-ENTER PIN (2716).");
  } else {
    static unsigned long lastNag = 0;
    if (millis() - lastNag > 10000) {
      Serial.println("CREDENTIALS REQUIRED: TYPE PASSWORD (4 DIGIT) TO VIEW DEBUG STREAM.");
      lastNag = millis();
    }
  }
}

void drawRow(int row, String text) {
  static String rows[2] = {"", ""};
  while(text.length() < 16) text += " ";
  if (text.length() > 16) text = text.substring(0, 16);
  if (rows[row] != text) {
    lcd.setCursor(0, row); lcd.print(text);
    rows[row] = text;
    secureSerialPrint("LCD R" + String(row) + ": [" + text + "]");
  }
}

void runStartupSequence() {
  drawRow(0, "SYSTEM INITIALIZE");
  delay(2000);
  drawRow(0, "COMMUNICATING..."); drawRow(1, "WITH FPGA       ");
  unsigned long start = millis(); bool found = false;
  while(millis() - start < 5000) { if (Serial2.available()) { found = true; break; } delay(10); }
  if (!found) {
    drawRow(0, "WAITING FOR FPGA"); 
    drawRow(1, "CHECK WIRING/RST");
    delay(2000);
    return; // Non-blocking exit
  }
  drawRow(0, "CONNECTION SUCCES"); drawRow(1, "GENERATING SEED..");
  delay(1500);
  drawRow(0, "SENDING SEED    "); drawRow(1, "TO FPGA...      ");
  injectNewSeed();
  delay(1500);
  drawRow(0, "FPGA WORKING    ");
  delay(1500);
}

bool idleTog = false;
unsigned long lastTog = 0;

void updateLCD() {
  String L1 = "", L2 = "";
  
  // HIGHEST PRIORITY - Emergency Mode override
  if (current_status == 'X') {
    L1 = "EMERGENCY INPUT "; 
    L2 = "KEY: " + current_keys;
    drawRow(0, L1); drawRow(1, L2);
    return;
  }

  if (millis() < msgTimer) { L1 = persistentMsg; L2 = pLine2; } 
  else if (currentState == STATE_SEARCHING) { 
    L1 = "SEARCHING...    "; 
    int rem = (SESSION_DURATION - (millis() - stateTimer))/1000;
    L2 = "T: " + String(rem) + "s SCAN... ";
  }
  else if (currentState == STATE_FOUND) { L1 = "DEVICE FOUND    "; L2 = "TRYING TO CONNECT"; }
  else if (currentState == STATE_PAIRING) { L1 = "MAC MATCHED     "; L2 = "CONNECTING...   "; }

  // Malfunction Alert Sequence (Status 'M')
  else if (current_status == 'M') {
    static int malStep = 0;
    static unsigned long lastMalTog = 0;
    if (millis() - lastMalTog > 3000) { lastMalTog = millis(); malStep = (malStep + 1) % 6; }
    
    L1 = "!!MALFUNCTION!! ";
    if (malStep == 0) L2 = "CHECK SOLENOID  ";
    else if (malStep == 1) L2 = "CHECK LMT SWITCH";
    else if (malStep == 2) L2 = "CHECK REAL STATE";
    else if (malStep == 3) L2 = "IF WRONG->RESET ";
    else if (malStep == 4) L2 = "ENTER CODE @KPD ";
    else L2 = "!!CHECK NOW!!   ";
    
    drawRow(0, L1); drawRow(1, L2);
    return;
  }

  else if (currentState == STATE_IDLE) { 
    if (!fpgaLive) {
      L1 = "FPGA: OFFLINE   ";
      L2 = "WAITING FOR LINK";
    } else {
      // Alternating Idle Screen only if FPGA is live
      if (idleTog) {
        L1 = "FPGA: OK        "; L2 = "PRESS BTN TO PAIR";
      } else {
        L1 = "DOOR STATUS:    ";
        L2 = (current_status == 'U' ? "UNLOCKED        " : "LOCKED          ");
      }
    }
  }
  else if (currentState == STATE_SEARCHING) { 
    L1 = "SEARCHING...    "; 
    int rem = (SESSION_DURATION - (millis() - stateTimer))/1000;
    L2 = "T: " + String(rem) + "s SCAN... ";
  }
  else if (currentState == STATE_FOUND) { L1 = "DEVICE FOUND    "; L2 = "TRYING TO CONNECT"; }
  else if (currentState == STATE_PAIRING) { L1 = "MAC MATCHED     "; L2 = "CONNECTING...   "; }
  else if (currentState == STATE_CONNECTED) {
      if (current_status == 'B') { L1 = "FPGA: RESETTING "; L2 = "PLEASE WAIT...  "; }
      else if (current_status == 'W' || current_status == 'I') { L1 = "FPGA: SYNC REQ  "; L2 = "INJECTING SEED.."; }
      else if (current_status == 'R') { L1 = "FPGA: SYNCING.. "; L2 = "BUTTON 48 (S1)  "; }
      else if (current_status == 'U') { L1 = "CODE CORRECT!   "; L2 = "UNLOCKED! D=LOCK"; }
      else if (current_status == 'E') { L1 = "WRONG CODE!!    "; L2 = "TRY AGAIN...    "; }
      else {
        char buf1[17]; sprintf(buf1, "CODE:**** %c T:%s", (hb_dot ? '!' : '.'), current_countdown.c_str());
        L1 = String(buf1); L2 = "KEY:" + current_keys;
      }
  }
  else if (currentState == STATE_LOST) { L1 = "DEVICE LOST!    "; L2 = "TRY AGAIN...    "; }
  
  // Persistent FPGA Link Status & Raw State (Top Right)
  L1[14] = (current_status == 0) ? '#' : current_status; // Raw State Char
  L1[15] = fpgaLive ? (hb_dot ? '*' : '.') : '?'; // Heartbeat
  
  drawRow(0, L1); drawRow(1, L2);
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, 16, 17); 
  pinMode(4, INPUT_PULLUP);
  
  // Initialize Protocol Strings
  strcpy(outgoingData.token, "----");
  strcpy(outgoingData.countdown, "60");

  // SECURE DYNAMIC PAIRING (Hold Button 4 at Boot)
  if (digitalRead(4) == LOW) {
      bootPairing = true;
  }
  
  prefs.begin("lock", true);
  if (prefs.getBytesLength("tmac") == 6) {
      prefs.getBytes("tmac", tokenAddress, 6);
  }
  prefs.end();

  lcd.init(); lcd.backlight();
  if (bootPairing) {
      drawRow(0, "!!PAIRING MODE!!");
      drawRow(1, "HOLD TOKEN NEAR ");
      delay(2000);
  } else {
      runStartupSequence();
  }
  
  WiFi.mode(WIFI_STA); 
  // FORCE CHANNEL 1
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(1, WIFI_SECOND_CHAN_NONE);
  esp_wifi_set_promiscuous(false);
  
  WiFi.disconnect();
  esp_now_init();
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(OnDataRecv);
  
  // Add Broadcast Peer for Discovery
  esp_now_peer_info_t bInfo;
  memset(&bInfo, 0, sizeof(bInfo));
  memcpy(bInfo.peer_addr, broadcastAddress, 6);
  bInfo.channel = 0; bInfo.encrypt = false;
  esp_now_add_peer(&bInfo);

  // Add saved peer if valid
  bool allZero = true;
  for(int i=0; i<6; i++) if(tokenAddress[i] != 0) allZero = false;
  if (!allZero) {
      addTokenAsPeer(tokenAddress);
  }
  
  sleepTimerStart = millis();
}

void loop() {
  if (digitalRead(4) == LOW) {
    if (adminHoldStart == 0) adminHoldStart = millis();
    if (currentState == STATE_CONNECTED && adminTokenReq && (millis() - adminHoldStart > 5000)) {
       currentState = STATE_ADMIN; redraw = true; adminHoldStart = 0; delay(500);
    }
  } else {
    if (adminHoldStart != 0 && (millis() - adminHoldStart < 5000)) {
      if (currentState == STATE_IDLE || currentState == STATE_LOST) {
        currentState = STATE_SEARCHING; stateTimer = millis(); redraw = true;
      }
    }
    adminHoldStart = 0;
  }

  // Alternating Idle Toggle
  if (currentState == STATE_IDLE) {
    if (millis() - lastTog > 3000) {
      lastTog = millis();
      idleTog = !idleTog;
      redraw = true;
    }
  }

  if (currentState == STATE_SEARCHING) {
    redraw = true; 
    if (millis() - stateTimer > SESSION_DURATION) { currentState = STATE_IDLE; redraw = true; }
  }
  if (currentState == STATE_FOUND && millis() - stateTimer > 1500) { currentState = STATE_PAIRING; stateTimer = millis(); redraw = true; }
  if (currentState == STATE_PAIRING && millis() - stateTimer > 1500) {
    currentState = STATE_CONNECTED; redraw = true; sessionStart = millis();
    pushCodesToFPGA(); injectNewSeed(); lastAutoSync = millis();
  }

  // UART Parsing
  while (Serial2.available() > 0) {
    char c = Serial2.read();
    static int p_st=0; static char p_cm=0; static String p_dt=""; static int p_tg=0;
    if (p_st == 0) { if (c == '!') p_st = 1; }
    else if (p_st == 1) { 
      p_cm = c; p_dt = "";
      if (c == 'R') { delay(50); ESP.restart(); }
      if (c == 'X') { if(currentState == STATE_SEARCHING) { currentState = STATE_IDLE; redraw = true; } p_st = 0; }
      if (c == 'S') hb_dot = !hb_dot;
      if (c == 'T') p_tg = 4; else if (c == 'C') p_tg = 2; else if (c == 'K') p_tg = 8; else if (c == 'S') p_tg = 1; else p_st = 0;
      if (p_st == 1) p_st = 2;
    } else if (p_st == 2) { p_dt += c;
      if (p_dt.length() == p_tg) {
        if (p_cm == 'T') current_token = p_dt; else if (p_cm == 'C') current_countdown = p_dt;
        else if (p_cm == 'K') current_keys = p_dt;
        else if (p_cm == 'S') {
          last_status = current_status; current_status = p_dt[0];
          if (last_status == 'U' && current_status == 'L') {
            injectNewSeed();
            persistentMsg = "DOOR IS LOCKED  "; pLine2 = "CODE RE-INJECTED"; msgTimer = millis() + 3000;
          }
        }
        lastUARTTime = millis(); fpgaLive = true; // Activity Seen
        p_st = 0; redraw = true; // Global reality sync (not just connected)
      }
    }
  }

  // Secure Serial Parsing
  while (Serial.available() > 0) {
    char sChar = Serial.read();
    lastSerialActivity = millis();
    if (sChar == '\n' || sChar == '\r') {
      if (serialInput == "2716") {
        secureSerialActive = true;
        Serial.println("****************************************");
        Serial.println("* STEALTH DEBUG UNLOCKED - SESSION OK  *");
        Serial.println("****************************************");
      } else if (serialInput.length() > 0) {
        Serial.println("ACCESS DENIED: INVALID CREDENTIALS.");
      }
      serialInput = "";
    } else {
      serialInput += sChar;
      if (serialInput.length() > 4) serialInput = ""; 
    }
  }

  // FPGA Watchdog (2.5s Timeout)
  if (millis() - lastUARTTime > 2500) {
    if (fpgaLive) { fpgaLive = false; redraw = true; }
  }

  // Autonomous Malfunction Rotation
  if (current_status == 'M') {
    static unsigned long lastMalRedraw = 0;
    if (millis() - lastMalRedraw > 3000) { lastMalRedraw = millis(); redraw = true; }
    sleepTimerStart = millis(); // Prevent sleep during tamper
  }

  if (currentState == STATE_CONNECTED) {
    // TOKEN LOSS WATCHDOG (60s Re-Search)
    if (millis() - lastRecvTime > 10000) { 
        unsigned long lostTime = millis() - lastRecvTime;
        if (lostTime < 60000) {
            persistentMsg = "TOKEN LOST      ";
            pLine2 = "RE-SEARCHING... ";
            msgTimer = millis() + 500;
        } else {
            drawRow(0, "DEVICE CON LOST ");
            drawRow(1, "PERMANENTLY     ");
            delay(3000);
            currentState = STATE_IDLE; // Immediate Idle
            redraw = true;
        }
    }

    if (current_status == 'U') { sessionStart = millis(); sleepTimerStart = millis(); } 
    if (millis() - sessionStart > SESSION_DURATION) { currentState = STATE_IDLE; redraw = true; }
    
    if (current_status == 'L' && (millis() - sleepTimerStart > MASTER_SLEEP_LIMIT)) {
      drawRow(0, "MASTER SYSTEM   "); drawRow(1, "SLEEPING...     ");
      delay(2000); lcd.noBacklight();
      esp_deep_sleep_start(); 
    }
  } else { sleepTimerStart = millis(); } 

  // Broadcast (Intentional Sync Only)
  static unsigned long lastSend = 0;
  bool shouldSend = false;
  uint8_t* target = tokenAddress;

  if (currentState == STATE_CONNECTED && millis() - lastSend > 1000) {
    shouldSend = true;
  } 

  if (shouldSend) {
    lastSend = millis();
    // Dynamically update the payload before sending
    strcpy(outgoingData.token, current_token.c_str());
    strcpy(outgoingData.countdown, current_countdown.c_str());
    
    outgoingData.status = current_status;
    outgoingData.flags = hb_dot ? 1 : 0;
    outgoingData.signature = 0x2716BACE; // Inject Graduation Key
    esp_now_send(target, (uint8_t *) &outgoingData, sizeof(outgoingData));
    if (target == broadcastAddress) secureSerialPrint("Self-Healing Broadcast Sent...");
  }
  if (redraw) { updateLCD(); redraw = false; }
}
