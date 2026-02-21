# **ANALYSIS OF IEEE BASE PAPERS AND IMPLEMENTED NOVELTY**
## **Comparative Study & Technical Enhancements**

---

### **1. CORE LOGIC ARCHITECTURE**
#### **Referenced Paper:**
*   **Title:** *Digital (Electronic) Locker*
*   **Source:** IEEE Xplore
*   **Authors:** Hitesh Prasad, et al. (2020)

#### **Technical Analysis:**
Prasad et al. demonstrated the superior reliability of Field Programmable Gate Arrays (FPGAs) over microcontrollers for security applications. Their design utilized a Finite State Machine (FSM) to handle keypad inputs and lock control logic in parallel hardware. However, their specific implementation relied on a **static password** (e.g., fixed key entry), which remains vulnerable to observation and replay attacks.

#### **Project Implementation & Novelty:**
This project adopts the **FPGA-based FSM** architecture for its zero-latency response and immunity to software crashes. The critical enhancement is the replacement of the static password system with a **Dynamic Rolling Code** protocol. While the core state machine logic is derived from this base paper, the authentication mechanism has been upgraded to reject any code that is older than 60 seconds.

---

### **2. HARDWARE SECURITY & ISOLATION**
#### **Referenced Paper:**
*   **Title:** *HISA: Hardware Isolation-based Secure Architecture*
*   **Source:** IEEE/ACM International Conference on Computer-Aided Design (ICCAD)
*   **Authors:** Mengmei Ye, et al. (2018)

#### **Technical Analysis:**
Ye et al. proposed an architecture where critical security functions are physically isolated from potentially compromised software layers. Their research highlights that networked processors (like those in IoT devices) are inherently vulnerable to remote execution attacks, and thus, a "Hardware Root of Trust" is required.

#### **Project Implementation & Novelty:**
This project utilizes the **Hardware Isolation** principle by physically separating the **Network Layer (ESP32)** from the **Control Layer (FPGA)**. The innovation lies in the **Simplex UART Interface**: the ESP32 can transmit status updates to the FPGA, but it has no physical pathway to force the FPGA to unlock or reset. This ensures that even a total compromise of the wireless bridge cannot result in an unauthorized physical entry.

---

### **3. WIRELESS COMMUNICATION PROTOCOL**
#### **Referenced Paper:**
*   **Title:** *Secure Home Automation System Based on ESP-NOW*
*   **Source:** IEEE Latin America Transactions
*   **Authors:** J. Cujilema, et al. (2023)

#### **Technical Analysis:**
Cujilema et al. explored the use of **ESP-NOW**, a connectionless Wi-Fi protocol, for secure local automation. Their research validated that direct device-to-device communication is faster and more secure than routing traffic through a central Wi-Fi Access Point (AP), which is a common attack vector.

#### **Project Implementation & Novelty:**
The project implements **ESP-NOW** to create an **Air-Gapped** authentication link. Unlike the base paper's implementation where devices were constantly listening, this project enhances security by implementing a **Deep Sleep "Ghost" Mode**. The handheld token remains powered down and radio-silent until manually triggered, rendering it invisible to standard Wi-Fi scanning tools used by attackers.

---

### **4. ALGORITHMIC RANDOMIZATION (LFSR)**
#### **Referenced Paper:**
*   **Title:** *Programmable Pseudorandom Pattern Generator Based on LFSR*
*   **Source:** IEEE
*   **Authors:** Madhav (2024)

#### **Technical Analysis:**
Madhav's research focused on using **Linear Feedback Shift Registers (LFSR)** within FPGAs to generate pseudorandom bit sequences for Built-In Self-Test (BIST) applications. The paper proved that LFSRs can generate deterministic yet statistically random sequences with minimal hardware resources.

#### **Project Implementation & Novelty:**
This project repurposes the **16-bit LFSR algorithm** from a testing tool into a **Security Cryptographic Primitive**. By checking the LFSR state against a synchronized timer, the system transforms the random number generator into a **Time-Based One-Time Password (TOTP)** engine. This application of LFSR for rolling code authentication in an FPGA environment represents a novel adaptation of the original testing-focused research.

---

### **5. FPGA RESOURCE OPTIMIZATION**
#### **Referenced Paper:**
*   **Title:** *A Proposal for Programmable Pattern Generator and its FPGA Implementation*
*   **Source:** IEEE
*   **Authors:** Somanathan (2022)

#### **Technical Analysis:**
Somanathan provided methodologies for implementing efficient pattern generators on low-cost FPGA fabrics. The research focused on optimizing lookup tables (LUTs) and flip-flops to reduce power consumption while maintaining signal integrity.

#### **Project Implementation & Novelty:**
Using Somanathan’s optimization techniques, this project fits the entire dual-core logic (Keypad Scanner + Rolling Code Engine + UART Controller) onto a **Sipeed Tang Nano 20K** with high efficiency. The design ensures that the security logic occupies less than 20% of the available LUTs, leaving room for future expansion such as biometric hashing.
