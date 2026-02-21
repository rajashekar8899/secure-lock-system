# **HARDWARE IMPLEMENTATION GUIDE (V1.0): SECURE LOCK SYSTEM**
## **Detailed Pinout, Connectivity, and Integration Strategy**

---

### **1. Keypad Interface (Full 4x4 Hexadecimal Matrix)**
In **V1.0**, I have mapped the entire 4x4 matrix for **Hexadecimal entry (0-F)**. 
- **Digits 1-9 & 0**: Numeric Entry.
- **A, B, C, D**: High Hex Digits.
- **`*` (E) & `#` (F)**: Extended Hex Digits.

**Important Note:** The keypad is now used *strictly* for entering the security code. Control functions like "Enter" and "Clear" have been moved to dedicated push-buttons for high reliability.

| Keypad Pin | Logic Name | FPGA Pin | Hex Value |
| :--- | :--- | :--- | :--- |
| **Pin 1** | **Col 0** | **76** | - |
| **Pin 2** | **Col 1** | **80** | - |
| **Pin 3** | **Col 2** | **72** | - |
| **Pin 4** | **Col 3** | **71** | - |
| **Pin 5** | **Row 0** | **73** | - |
| **Pin 6** | **Row 1** | **74** | - |
| **Pin 7** | **Row 2** | **75** | - |
| **Pin 8** | **Row 3** | **85** | - |

---

### **2. Control & Sensor Pins**
The following pins drive my security state machine and monitor the door status.

| Component | Signal | FPGA Pin | Type |
| :--- | :--- | :--- | :--- |
| **Reset Button (S1)** | `ext_sync_btn`| **77** | Input (Pull-up) |
| **Emergency Button** | `em_btn` | **49** | Input (Pull-up) |
| **Back Button** | `btn_back` | **48** | Input (Pull-up) |
| **Enter Button** | `btn_enter` | **41** | Input (Pull-up) |
| **Door Reed Switch** | `door_sense` | **42** | Input (Pull-up) |
| **Solenoid Relay** | `relay_out` | **86** | Output (Active Low)|

---

### **3. Bridge-to-FPGA UART Link**
I use a cross-over UART connection to allow my ESP32 Bridge to inject seeds and receive system status updates.

| FPGA Signal | FPGA Pin | ESP32 Pin | Logic Direction |
| :--- | :--- | :--- | :--- |
| **FPGA TX** | **28** | **GPIO 16 (RX2)** | Status to Bridge |
| **FPGA RX** | **27** | **GPIO 17 (TX2)** | Seed to FPGA |

---

### **4. Bridge Unit Peripherals**
The Bridge unit I implemented also manages the primary status display and the system pairing function.

| Component | ESP32 Pin | Purpose |
| :--- | :--- | :--- |
| **I2C SDA** | **GPIO 21** | Data for the primary 16x2 LCD |
| **I2C SCL** | **GPIO 22** | Clock for the primary 16x2 LCD |
| **Pairing Button**| **GPIO 4** | Initiates Token synchronization |

---

### **5. Diagnostic LED Map**
I programmed the onboard LEDs of the Tang Nano 20K to provide instant visual feedback on the system's internal state.

- **LED 0**: Pulses when I hit the Sync/Reset Button.
- **LED 1**: Solid ON when the Emergency Button is pressed.
- **LED 2**: Solid ON when the Back Button is active.
- **LED 3**: Solid ON when the Enter Button is pressed.
- **LED 4**: Solid ON when my **Door Sense** detects an open door.
- **LED 5**: System Heartbeat (Blinks to show logic is running).

---

### **6. The Handheld Token Unit**
I designed the Token to be a compact, portable device. The wiring I used for its internal components is focused on low-power consumption and clarity.

| Component | ESP32 Pin | Purpose |
| :--- | :--- | :--- |
| **I2C SDA** | **GPIO 21** | Data for the handheld LCD |
| **I2C SCL** | **GPIO 22** | Clock for the handheld LCD |
| **Wake Button** | **GPIO 4** | Interrupt trigger to wake from Deep Sleep |

---

### **7. Power Delivery**
- My Solenoid Lock requires a separate **12V DC Adapter** to provide enough current for the latch.
- The FPGA and ESP32 units are powered via **USB-C** or a shared 5V rail.
- My handheld Token is optimized for portable use with a **9V battery**.

---

**Certified Technical Documentation (V1.0)**
**Lead Designer:** T. Rajashekar (24J25A0424 - LE)
**Department of ECE, Joginpally Baskar Rao Engineering College (JBREC)**
**Submission Date:** February 19, 2026
