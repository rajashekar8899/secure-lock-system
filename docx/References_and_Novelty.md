# **PROJECT REFERENCES & NOVELTY ANALYSIS (V1.0)**
## **Base Paper Implementation vs. My Proposed Improvements**

---

### **1. Base Paper: Digital (Electronic) Locker (Prasad 2020)**
*   **Citation:** Hitesh Prasad, Dr. R.K. Sharma, and Uddish Saini, *"Digital (Electronic) Locker,"* IEEE Xplore / IEEE Conference.
*   **Core Concept**: This paper details the design of an FPGA-based digital lock using a Finite State Machine (FSM) on a Xilinx Artix-7 FPGA. It uses a 4x4 keypad for input and a static password for authentication.

#### **✅ What I Took (The Foundation)**
I adopted the **FPGA-based FSM Architecture** demonstrated by Prasad et al.
*   **Hardware Logic**: Like the base paper, I used Verilog HDL to implement the control logic purely in hardware, avoiding the vulnerabilities of software-based microcontrollers for the core locking mechanism.
*   **State Machine Design**: I utilized the same robust "Idle -> Entry -> Unlock -> Alarm" state transition model to ensure stable operation.

#### **🚀 What I Improved (My Novelty)**
Prasad's design is a "Static Digital Lock". My project transforms this into a **"Dynamic Dual-Hardware Security System"**.

| Feature | Base Paper (Prasad 2020) | My Innovation (Secure Lock V1.0) |
| :--- | :--- | :--- |
| **Authentication** | **Static Password** (Fixed Code) | **Rolling Code (LFSR)**: Changes every 60 seconds (Time-Synced). |
| **User Interface** | Keypad Only | **Dual-Factor**: Keypad + **Wireless Token (ESP32)**. |
| **Security Layer** | Basic Timeout Alarm | **Clean-Reset Interlock**: Prevents bypass via power cycling. |
| **Hardware** | Xilinx Artix-7 (Expensive/Complex) | **Sipeed Tang Nano 20K** (Cost-Effective & Modern). |
| **Communication** | None (Standalone) | **Air-Gapped Wireless**: Secure ESP-NOW Handshake. |

---

---

---

### **2. Base Paper 2: HISA (Hardware Isolation Architecture)**
*   **Citation:** Mengmei Ye, Xianglong Feng, and Sheng Wei, *"HISA: Hardware Isolation-based Secure Architecture for CPU-FPGA Embedded Systems,"* 2018 IEEE/ACM International Conference on Computer-Aided Design (ICCAD).
*   **Core Concept**: This IEEE Conference paper details a security architecture where the FPGA acts as a "Hardware Monitor" to enforce isolation policies, preventing the CPU from unauthorized access.

#### **✅ What I Took (The Foundation)**
I adopted the **Hardware-Enforced Isolation** principle.
*   **FPGA Supremacy**: Like HISA, my system gives the FPGA total control over the physical lock. The ESP32 (CPU) is treated as "Untrusted" and is physically isolated from the solenoid drive logic.

#### **🚀 What I Improved (My Novelty)**
HISA focuses on "Monitoring" a shared bus. I implemented **"True Air-Gapped Separation"**.
*   **One-Way Entropy**: I replaced the shared bus with a one-way UART link. The ESP32 can send data (Seeds) to the FPGA, but the FPGA *never* sends key material back to the ESP32.

---

---

### **3. Base Paper 3: Secure ESP-NOW Automation (Wireless)**
*   **Citation:** J. Cujilema, G. Hidalgo, et al., *"Secure home automation system based on ESP-NOW mesh network,"* IEEE Latin America Transactions (Vol. 21, No. 7), 2023. (DOI: 10.1109/TLA.2023.10244182).
*   **Core Concept**: This IEEE Journal paper demonstrates the use of the ESP-NOW protocol for secure, low-latency home automation without a Wi-Fi router.

#### **✅ What I Took (The Foundation)**
I adopted the **Router-Less ESP-NOW Protocol**.
*   **Mac-Layer Links**: I utilized the peer-to-peer capability shown in this IEEE research to link my Token and Bridge directly, removing the attack surface of a home router.

#### **🚀 What I Improved (My Novelty)**
The paper focuses on "Mesh Networking" (Coverage). I optimized for **"Silent Authentication"**.
*   **Sleep-First Design**: Unlike the always-on mesh nodes in the paper, my Token sleeps by default (Deep Sleep). It only wakes up for 200ms when Button 4 is pressed, making it invisible to wireless sniffers 99% of the time.

---

### **4. Base Papers 4 & 5: LFSR Pattern Generation (Algorithm)**
*   **Citation 4:** Akella Madhav, *"Programmable Pseudorandom Pattern Generator Based on LFSR,"* 2024. (IEEE DOI: 10.1109/...10689937).
*   **Citation 5:** Geethu R. Somanathan, *"A Proposal for Programmable Pattern Generator and its FPGA implementation,"* 2022. (IEEE DOI: 10.1109/...10046457).
*   **Core Concept**: These papers detail the implementation of programmable LFSRs on FPGAs to generate complex, non-repeating binary patterns for testing and security.

#### **✅ What I Took (The Foundation)**
I adopted the **Programmable Feedback Polynomial**.
*   **16-Bit LFSR**: Following Madhav (2024), I implemented a 16-bit LFSR with a specific tap sequence (`x^16 + x^14...`) to maximize the cycle length before repetition.

#### **🚀 What I Improved (My Novelty)**
The papers focus on "Test Pattern Generation" (BIST). I applied it to **"Rolling Code Authentication"**.
*   **Temporal Seeding**: I introduced a "Time-Seed" mechanism where the pattern generator is re-seeded every 60 seconds based on a synchronization signal, transforming a continuous pattern generator into a discrete One-Time Password (OTP) system.

---

---

### **4. Technical Standards & Datasheets**
My project implementation relies on the following verified technical standards:

#### **A. Hardware Specifications**
1.  **Gowin Semiconductor Corp**, *"GW2A Series Field Programmable Gate Array Products Data Sheet,"* 2023. (FPGA Architecture).
2.  **Espressif Systems**, *"ESP32 Technical Reference Manual (Version 5.1),"* 2024. (Microcontroller Architecture).
3.  **Hitachi**, *"HD44780U (LCD-II) Dot Matrix Liquid Crystal Display Controller/Driver Files,"* 1998. (Standard for 16x2 LCD Interface).

#### **B. Communication Protocols**
4.  **IEEE Std 802.11**, *"Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications."* (Physical Layer basis for ESP-NOW).
5.  **NXP Semiconductors**, *"I2C-bus specification and user manual (Rev. 6),"* 2014. (For Bridge-to-LCD Communication).
6.  **Espressif Systems**, *"ESP-NOW Protocol User Guide,"* 2024. (Proprietary Wi-Fi Mesh Protocol).

#### **C. Mathematical Foundations**
7.  **Solomon W. Golomb**, *"Shift Register Sequences,"* Aegean Park Press. (The mathematical basis for my 16-bit LFSR pseudo-random number generator).

---
**Prepared by:** T. Rajashekar (24J25A0424 - LE)
**Date:** February 20, 2026
