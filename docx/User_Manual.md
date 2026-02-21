# **USER OPERATION MANUAL: SECURE LOCK SYSTEM**
## **Professional Air-Gapped Authentication**

---

### **1. System Operating Principle**
My system uses a rolling code authentication method. I've designed the handheld Token to display a 4-digit code that changes every 60 seconds. You must enter this code on the master keypad to unlock the door. The system is entirely air-gapped, meaning it does not rely on any internet or external networks for its security.

---

### **2. Setup and Pairing**
Before using the system, I designed a specialized pairing mode to link your handheld Token with the Bridge unit.

1.  **Enter Pairing Mode**: Both the Bridge and Token must be powered ON.
2.  **Initiate Sync**: Press **Button 4** on **BOTH** units simultaneously.
3.  **Confirm**: The Bridge will show `DEVICE FOUND`, and the units are now connected.

---

### **3. Daily Operation**

#### **Unlocking the Door**
1.  **Check Your Token**: Look at the 4-digit code currently shown on your handheld Token.
2.  **Enter Code**: Type the matching numbers or letters (A-F) into the FPGA keypad.
3.  **Authentication**: Press the dedicated **ENTER Button (Pin 41)** to confirm. If correct, the display shows `UNLOCKED!`.
4.  **Entry Window**: You have **10 seconds** to open the door before it relocks.

#### **Automatic Relocking**
As soon as the magnetic sensor detects that the door has been closed, my system automatically returns to the `LOCKED` state for maximum security.

---

### **4. FPGA Flashing (Permanent)**
To ensure the FPGA retains the code after power-off, you must flash the **internal flash memory**:
1.  Open **Gowin Programmer**.
2.  Select your device (Tang Nano 20K).
3.  Click under **Operation**.
4.  Change Access Mode to **"Embedded Flash Mode"** (or "External Flash Mode" depending on version).
5.  Select Operation: **"Program/Verify"**.
6.  Select the `.fs` file.
7.  Click **Save** and then **Run**.

> **Note:** This is **NOT** permanent forever. You can **re-flash** it as many times as you want (just like an Arduino). It simply means the code stays when the power is cut.

### **5. System Boot Sequence**
1.  Power ON the FPGA first (or both simultaneously).

---

### **6. Tamper Protection (Malfunction Mode)**
I have implemented a rigorous anti-tamper logic. If the door is forced open without a valid code, the system enters **`!!MALFUNCTION!!`** mode.
-   The LCD will flash a warning sequence.
-   The system will "lock out" the emergency button.
-   The alarm state will persist even if the door is closed or the power is reset.

---

### **5. Owner Recovery (Clearing Alarms)**
If your system enters a malfunction state, follow these steps that I've built into the logic:

1.  **Close the Door**: Ensure the magnetic sensor is engaged.
2.  **FPGA Reset**: Press the **Reset Button (S1)** on the FPGA board.
3.  **Master Override**: Enter the Master Code (**27168899**) to clear the alarm and return to the `LOCKED` state.

---

**Designed and Developed by: T. Rajashekar (24J25A0424 - LE)**
**Institution: Joginpally Baskar Rao Engineering College (JBREC)**
**Batch: 2023-2027 (3-2 B.Tech ECE)**
**Certification Date: February 20, 2026 (V1.0)**
