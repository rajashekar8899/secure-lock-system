# **PROJECT ABSTRACT**
## **Dual-Hardware Secure Locking System Using FPGA & ESP32**

The ubiquity of Internet of Things (IoT) devices has introduced critical vulnerabilities in smart home security, particularly regarding static password theft and remote network exploitation. This project addresses these challenges by developing a **Dual-Hardware Secure Locking System** that utilizes a physically **Air-Gapped Architecture** to eliminate common attack vectors.

Unlike traditional microcontroller-based locks, this system decouples the communication layer from the security logic. A **Gowin Tang Nano 20K FPGA** serves as the 'Hardware Root of Trust,' executing critical Finite State Machine (FSM) operations in parallel hardware to ensure zero-latency response and immunity to software-based buffer overflow attacks. Wireless communication is managed by two **ESP32 transceivers** using the router-less **ESP-NOW** protocol, creating a private, invisible network that operates independently of local Wi-Fi infrastructure.

The core innovation lies in the implementation of a **Time-Synchronized Rolling Code Algorithm** based on a 16-bit Linear Feedback Shift Register (LFSR). This mechanism generates a unique, non-repeating 4-digit token every 60 seconds, rendering intercepted codes useless after a single minute. The system also integrates **Deep Sleep Power Management** for the handheld token (achieving <10µA standby current) and a **Hardware-Latched Tamper Detection** circuit. Experimental results demonstrate a verification speed of under 10ms and 100% rejection of replay attacks, proving the efficacy of FPGA-based hardware isolation for high-security applications.

**Keywords:** FPGA, ESP32, ESP-NOW, Rolling Code, LFSR, Air-Gapped Architecture, Hardware Security, IoT Security, Tang Nano 20K, Tamper Detection.
