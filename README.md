# 🔐 **DUAL HARDWARE LOCKING SYSTEM USING FPGA AND ESP32 WITH ROLLING CODES**
![Verilog](https://img.shields.io/badge/Language-Verilog-blue) ![Platform](https://img.shields.io/badge/Platform-Tang_Nano_20K-orange) ![Wireless](https://img.shields.io/badge/Wireless-ESP_NOW-green) ![Status](https://img.shields.io/badge/Status-V1.0_Certified-success)

## **Air-Gapped Authentication Architecture | B.Tech ECE Final Project**

In this project, I have designed and implemented a professional-grade secure locking system that utilizes a **Tang Nano 20K FPGA** for mission-critical logic and an **ESP32** for secure status orchestration. 

---

## 🌟 Security Features I Implemented
- 🕵️ **Stealth Serial Debug**: Password-locked (**2716**) console for secure remote monitoring with a **120s auto-lockout**.
- ⌨️ **Hexadecimal Interface**: Full **0-F** entry support on the 4x4 keypad.
- 🔘 **Dedicated Controls**: Hardware-isolated **Enter (Pin 41)** and **Back (Pin 48)** buttons for high-reliability command execution.
- 📡 **Intentional Wireless Sync**: Secure manual handshake (Button 4) replaces automatic broadcasting for zero-emission security.
- **Latching Tamper Memory**: My system detects unauthorized openings and traps the logic in `MALFUNCTION` mode until I authenticate with my **Master Override code (27168899)**.
- **Clean-Reset Validation**: I designed a physical interlock that requires a "Door Closed" state during hardware reset to prevent security overrides.
- **Rolling Code Protocol**: I built a 16-bit LFSR-based password rotation that generates a new code every 60 seconds to neutralize replay attacks.

---

## 📂 My Project Structure
- **/rtl**: My verified Verilog source (`secure_lock_system.v`).
- **/esp32**: My Arduino Bridge and Token firmware.
- **/docx**: My technical reports, hardware guides, novelty analysis, and manuals.
- **/constraints**: My final pin mapping and timing constraints.

---

## 🚀 How to Start My System
1.  **Wiring**: Follow my **[Hardware Guide](./docx/HARDWARE_GUIDE.md)** exactly. Quick Reference:
    | Signal | FPGA Pin | Description |
    | :--- | :--- | :--- |
    | **UART TX** | **28** | To ESP32 RX |
    | **UART RX** | **27** | To ESP32 TX |
    | **Emerg Btn** | **49** | Pull-Down |
    | **Door Sens** | **42** | Reed Switch |
2.  **Synthesis**: Compile my project using **Gowin EDA** to generate the bitstream and flash it to the Tang Nano 20k.
3.  **Bridge Setup**: Connect the ESP32 (Bridge) to the FPGA UART (Pins 27/28).
4.  **Pairing**: Press **Button 4** on both the Bridge and Token simultaneously to establish the encrypted link.
5.  **Entry**: Read the 4-digit token from your handheld device, type it on the hex-keypad, and press the **Dedicated Enter Button (Pin 41)**!

---

## 🛠️ Components I Used
- Sipeed Tang Nano 20K FPGA
- ESP32 Development Modules (x2)
- 4x4 Matrix Membrane Keypad
- 16x2 I2C LCD Displays
- 1-Channel 5V Relay + 12V Solenoid Lock

---

## ⚖️ License & Copyright
**© 2026 T. Rajashekar (24J25A0424 - LE)**
This project is open-sourced under the **CC BY-NC-SA 4.0** (Attribution-NonCommercial-ShareAlike) License.

### ✅ What You CAN Do:
- **View & Study**: You can read the code to learn how it works.
- **Modify**: You can edit the code for personal, educational, or research use.
- **Share**: You can share copies, provided you give full credit to the original author (T. Rajashekar).

### ❌ What You CANNOT Do (Strictly Prohibited):
- **No Profit**: You cannot use this code/design for any commercial product or sell it.
- **No Plagiarism**: You cannot remove the "LEAD LOGIC DESIGNER" headers or claim this work as your own.
- **No Closed Source**: If you modify this project, you must share your changes under the exact same license.

For commercial licensing or permission, please contact the author.

---

## 🌍 How to Upload to GitHub
1.  Create a **New Repository** on GitHub (e.g., `secure-lock-system-v1`).
2.  Do **NOT** initialize with a README, .gitignore, or License (we already have them).
3.  Run the following commands in your terminal:
    ```bash
    git remote add origin https://github.com/rajashekar8899/secure-lock-system-v1.git
    git branch -M main
    git push -u origin main
    ```

---
**Project Lead & Designer:** T. Rajashekar (24J25A0424 - LE)
**Institution:** Joginpally Baskar Rao Engineering College (JBREC)
**Batch:** 2023-2027 (3-2 B.Tech ECE)
**Certification ID:** V1.0-2026
