# **MY ESP32 WORKFLOW: SOFTWARE SETUP & FLASHING**
## **Firmware Configuration for Bridge and Token Units (V1.0)**

---

### **1. My Toolchain Setup**
To build the firmware for my ESP32 units, I used the following configuration:

1.  **Arduino IDE**: I used version 2.0 or newer. [Download Here](https://www.arduino.cc/en/software)
2.  **ESP32 Board Manager**: Add this URL in `Preferences`:
    `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3.  **Required Libraries**: Search for **"LiquidCrystal I2C"** in the Library Manager.

---

### **2. My Flashing Procedure (Windows/Linux/WSL)**
I've designed two ways to flash the firmware: through the standard IDE or via the command line for automation.

#### **Option A: Manual Flashing (Arduino IDE)**
1.  Connect your ESP32 via USB-C.
2.  Select **"DOIT ESP32 DEVKIT V1"** and the correct **COM/tty** Port.
3.  Click **"Upload"**. If it fails to connect, hold the **BOOT** button on the module.

#### **Option B: Automated/CLI Flashing (esptool)**
I use `esptool.py` for headless or automated deployment across all platforms.
1.  **Install Tool**: `pip install esptool`
2.  **Export Binary**: In Arduino IDE, go to `Sketch -> Export Compiled Binary`.
3.  **Flash Command**:
    ```bash
    # Replace [PORT] with COMx or /dev/ttyUSBx
    esptool.py --chip esp32 --port [PORT] --baud 921600 write_flash -z 0x10000 [YOUR_BINARY].bin
    ```

---

### **3. My Serial Diagnostics**
After flashing, I use a terminal at **115200 Baud** to verify system health.
- **Bridge**: Look for the rolling seed injection messages.
- **Token**: Verify that it successfully connects to the handshake protocol I designed.

---

### **4. My Pairing Workflow**
I implemented a dynamic bonding mechanism to avoid hardcoding MAC addresses.
1.  **Flash Token**: Note its MAC address from the Serial Monitor.
2.  **Enter Pairing Mode**: Power ON both units.
3.  **Initiate Sync**: Press **Button 4** on **BOTH** the Bridge and Token at the same time.
4.  **Bonding**: The Bridge will capture the Token's signature and store it in non-volatile memory (NVS).

---

**Developer: T. Rajashekar (24J25A0424 - LE)**
**Institution: Joginpally Baskar Rao Engineering College (JBREC)**
**Batch: 2023-2027 (3-2 B.Tech ECE)**
