// --- SECURE DUAL-HARDWARE LOCKING SYSTEM: HANDHELD TOKEN (V1.0) ---
// LEAD LOGIC DESIGNER: T. Rajashekar (24J25A0424 - LE)
// HARDWARE SYSTEMS INTEGRATION: M. Shailusha (23J21A0424)
// SYSTEM FIRMWARE & VERIFICATION: G. Krithin (24J25A0407 - LE)
// INSTITUTION: Joginpally Baskar Rao Engineering College (JBREC)
#include <esp_now.h>
#include <WiFi.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <esp_wifi.h>

// --- SECURE CONFIGURATION ---
uint8_t bridgeAddress[6] = {0, 0, 0, 0, 0, 0}; // Auto-Learned MAC
uint8_t broadcastAddress[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
bool bridgePeerAdded = false;

LiquidCrystal_I2C lcd(0x27, 16, 2);

enum SystemState { STATE_IDLE, STATE_SEARCHING, STATE_PAIRING, STATE_CONNECTED, STATE_LOST, STATE_FOUND, STATE_RECOVERING };
SystemState currentState = STATE_IDLE;

typedef struct struct_message {
    char token[5];
    char countdown[3];
    char status;
    uint8_t flags;
    uint32_t signature; // Secure Handshake ID
} struct_message;

struct_message incomingData;
bool dataReceived = false;
unsigned long lastRecvTime = 0;
unsigned long stateTimer = 0;
unsigned long wakeTime = 0;
bool redraw = true;
unsigned long lastSerialActivity = 0;
const unsigned long IDLE_SLEEP_TIMEOUT = 300000; // 5m Initial/Idle Sleep
const unsigned long RECOVERY_WINDOW = 60000;    // 60s Recover Window

void secureSerialPrint(String msg); // Forward Declaration

void addBridgeAsPeer(const uint8_t *mac) {
    if (bridgePeerAdded) return;
    esp_now_peer_info_t peerInfo;
    memset(&peerInfo, 0, sizeof(peerInfo));
    memcpy(peerInfo.peer_addr, mac, 6);
    memcpy(bridgeAddress, mac, 6);
    peerInfo.channel = 0; 
    peerInfo.encrypt = false;
    if (esp_now_add_peer(&peerInfo) == ESP_OK) {
        bridgePeerAdded = true;
        Serial.println("Bridge MAC Learned and Paired");
    }
}

void OnDataRecv(const uint8_t * mac, const uint8_t *incoming, int len) {
  if (len >= sizeof(struct_message)) {
    struct_message *msg = (struct_message*)incoming;
    
    // VERIFY HARDWARE SIGNATURE
    if (msg->signature != 0x2716BACE) {
        secureSerialPrint("ALERT: UNKNOWN SENDER! SIGNATURE ERROR.");
        return; 
    }
    
    // Auto-Add Peer (RAM Only)
    addBridgeAsPeer(mac);
    memcpy(&incomingData, incoming, sizeof(incomingData));
    
    // LCD Hardening: Ensure strings are safe for LCD printing
    incomingData.token[4] = '\0';
    incomingData.countdown[2] = '\0';
    
    lastRecvTime = millis();
    dataReceived = true;
    if (currentState == STATE_SEARCHING || currentState == STATE_LOST || currentState == STATE_RECOVERING) {
      if (currentState == STATE_RECOVERING) currentState = STATE_CONNECTED;
      else currentState = STATE_FOUND;
      stateTimer = millis(); redraw = true;
    }
  }
}

void goToSleep() {
  lcd.clear(); lcd.setCursor(0,0); lcd.print("SLEEPING...");
  delay(1000); lcd.noBacklight(); lcd.noDisplay();
  esp_sleep_enable_ext0_wakeup(GPIO_NUM_4, 0); 
  esp_deep_sleep_start();
}

// NO PREFERENCES - RAM ONLY

void setup() {
  Serial.begin(115200);
  pinMode(4, INPUT_PULLUP);
  lcd.init(); lcd.backlight();
  WiFi.mode(WIFI_STA); 
  
  // FORCE CHANNEL 1
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(1, WIFI_SECOND_CHAN_NONE);
  esp_wifi_set_promiscuous(false);

  esp_now_init();
  esp_now_register_recv_cb(OnDataRecv);

  // NO AUTO-LOAD. MUST MANUALLY PAIR.
  currentState = STATE_IDLE;

  // Manual Pairing Mode (Hold Button 4)
  if (digitalRead(4) == LOW) {
      currentState = STATE_PAIRING;
      lcd.setCursor(0,0); lcd.print("PAIRING MODE...");
  } else {
       lcd.setCursor(0,0); lcd.print("PRESS PAIR BTN");
  }

  // Add Broadcast Peer for Discovery
  esp_now_peer_info_t peerInfo;
  memset(&peerInfo, 0, sizeof(peerInfo));
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0; peerInfo.encrypt = false;
  esp_now_add_peer(&peerInfo);
  
  wakeTime = millis();
}

// --- SECURE DEBUG LOGIC ---
bool secureSerialActive = false;
String serialBuf = "";

void secureSerialPrint(String msg) {
  if (secureSerialActive && (millis() - lastSerialActivity < 120000)) {
    Serial.println("[TOKEN-V1.0] " + msg);
  } else if (secureSerialActive) {
    secureSerialActive = false;
    Serial.println("\n[SECURITY] TOKEN DEBUG TIMED OUT. RE-ENTER PIN (2716).");
  }
}

void checkSecureAccess() {
  while (Serial.available()) {
    char c = Serial.read();
    lastSerialActivity = millis();
    if (c == '\n' || c == '\r') {
      if (serialBuf == "2716") {
        secureSerialActive = true;
        Serial.println("\n******************************************");
        Serial.println("*  TOKEN STEALTH SERIAL DEBUG: ACTIVE    *");
        Serial.println("*  Project Lead: T. Rajashekar (JBREC)   *");
        Serial.println("******************************************\n");
      }
      serialBuf = "";
    } else {
      serialBuf += c;
    }
  }
}

void updateLCD() {
  lcd.clear();
  String top = "", bot = "";
  switch(currentState) {
    case STATE_IDLE:
      top = "TOKEN READY"; bot = "PRESS BTN TO PAIR";
      break;
    case STATE_SEARCHING: {
      top = "SEARCHING...";
      int remS = (IDLE_SLEEP_TIMEOUT - (millis() - wakeTime))/1000;
      if (remS < 0) remS = 0;
      bot = "T: " + String(remS) + "s SCAN...";
      break;
    }
    case STATE_FOUND:
      top = "DEVICE FOUND!"; bot = "ID MATCHING...";
      break;
    case STATE_PAIRING:
      top = "MAC MATCHED"; bot = "CONNECTING...";
      break;
    case STATE_RECOVERING: {
      top = "TOKEN LOST      ";
      int remR = (RECOVERY_WINDOW - (millis() - stateTimer))/1000;
      if (remR < 0) remR = 0;
      bot = "TRYING AGAIN:" + String(remR) + "s";
      break;
    }
    case STATE_CONNECTED: {
      char s = incomingData.status;
      if (s == 'U') { top = "DOOR UNLOCKED!"; bot = "CONNECTED OK    "; }
      else if (s == 'E') { top = "WRONG CODE!!"; bot = "TRY AGAIN...    "; }
      else if (s == 'R') { top = "FPGA: SYNCING.. "; bot = "BUTTON 48 (S1)  "; }
      else if (s == 'X') { top = "EMERGENCY MODE  "; bot = "ENTER 8-DIGIT KEY"; }
      else if (s == 'B') { top = "FPGA: RESETTING "; bot = "PLEASE WAIT...  "; }
      else if (s == 'W' || s == 'I') { top = "FPGA: SYNC REQ  "; bot = "INJECTING SEED.."; }
      else if (s == 'M') {
         top = "!!TAMPER ALERT!!";
         char buf_m[17]; sprintf(buf_m, "CODE:%c%c%c%c [OK]", incomingData.token[0], incomingData.token[1], incomingData.token[2], incomingData.token[3]);
         bot = String(buf_m);
      } else {
         char buf1[17]; sprintf(buf1, "CODE:%c%c%c%c [OK]", incomingData.token[0], incomingData.token[1], incomingData.token[2], incomingData.token[3]);
         char buf2[17]; sprintf(buf2, "T:%c%cs  CONNECTED", incomingData.countdown[0], incomingData.countdown[1]);
         top = String(buf1); bot = String(buf2);
      }
      break;
    }
    case STATE_LOST:
      top = "DEVICE LOST!"; bot = "TRY AGAIN...";
      break;
  }
  lcd.setCursor(0,0); lcd.print(top);
  lcd.setCursor(0,1); lcd.print(bot);
  secureSerialPrint("TOKEN-LCD: [" + top + "] / [" + bot + "]");
}

void loop() {
  if (digitalRead(4) == LOW) {
    if (currentState != STATE_CONNECTED && currentState != STATE_SEARCHING && currentState != STATE_FOUND && currentState != STATE_PAIRING && currentState != STATE_RECOVERING) {
      currentState = STATE_SEARCHING; wakeTime = millis(); redraw = true; delay(500);
    }
  }

  // IDLE SLEEP: 5 minutes of Searching
  if (currentState == STATE_SEARCHING && (millis() - wakeTime > IDLE_SLEEP_TIMEOUT)) {
      goToSleep();
  }

  if (currentState == STATE_SEARCHING) {
     if (millis() - wakeTime > IDLE_SLEEP_TIMEOUT) { currentState = STATE_IDLE; redraw = true; }
     else {
       // BROADCAST PRESENCE (Handshake)
       static unsigned long lastBroadcast = 0;
       if (millis() - lastBroadcast > 2000) {
         lastBroadcast = millis();
         struct_message handshake;
         strcpy(handshake.token, "HI!!");
         strcpy(handshake.countdown, "00");
         handshake.status = 'P'; // Pairing Request
         handshake.signature = 0x2716BACE;
         esp_now_send(broadcastAddress, (uint8_t *) &handshake, sizeof(handshake));
         secureSerialPrint("HANDSHAKE BROADCAST SENT [CH:1]...");
       }
       redraw = true; // For countdown frequency
     }
  }
  if (currentState == STATE_FOUND && millis() - stateTimer > 1500) { currentState = STATE_PAIRING; stateTimer = millis(); redraw = true; }
  if (currentState == STATE_PAIRING && millis() - stateTimer > 1500) { currentState = STATE_CONNECTED; redraw = true; }

  if (currentState == STATE_CONNECTED) {
    if (dataReceived) { wakeTime = millis(); dataReceived = false; redraw = true; }

    // SEND HEARTBEAT TO BRIDGE
    static unsigned long lastHB = 0;
    if (millis() - lastHB > 2000) {
      lastHB = millis();
      struct_message hb;
      hb.status = 'K'; // "Keep-alive"
      hb.signature = 0x2716BACE;
      
      bool bridgeValid = false;
      for(int i=0; i<6; i++) if(bridgeAddress[i] != 0) bridgeValid = true;
      
      if (bridgeValid) esp_now_send(bridgeAddress, (uint8_t *) &hb, sizeof(hb));
      // Removed automatic broadcast in IDLE to prevent auto-connection
    }

    // DETECT LOSS: If silence > 5s (more stable than 1.5s)
    if (millis() - lastRecvTime > 5000) {
      currentState = STATE_RECOVERING;
      stateTimer = millis(); redraw = true;
    }
  }

  if (currentState == STATE_RECOVERING) {
    redraw = true; // For countdown
    if (millis() - stateTimer > RECOVERY_WINDOW) {
      lcd.clear(); lcd.setCursor(0,0); lcd.print("MASTER SYS OFF");
      lcd.setCursor(0,1); lcd.print("SLEEPING...");
      delay(3000); goToSleep();
    }
  }

  checkSecureAccess();
  if (redraw) { updateLCD(); redraw = false; }
}
