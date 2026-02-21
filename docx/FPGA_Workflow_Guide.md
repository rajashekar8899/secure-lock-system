# **MY FPGA WORKFLOW: SYNTHESIS & MULTI-PLATFORM VERIFICATION**
## **Technical Manual for Tang Nano 20K Development (V1.0)**

---

### **1. My Development Environment**
To implement my security logic, I use two primary software layers. I have designed my project to be portable across Windows, Linux, and WSL.

1.  **Gowin EDA (Standard Edition)**: My primary tool for synthesis and hardware deployment.
2.  **Simulation Engine**: I use **Icarus Verilog** and **GTKWave** for logic verification.

#### **Setup Links for All Platforms**
- **Gowin EDA**: [Official Download](https://www.gowinsemi.com/en/support/download_eda/) (License required).
- **Icarus Verilog**:
    - **Windows**: [Bleecker Street Builds](http://bleyer.org/icarus/).
    - **Linux/WSL**: `sudo apt-get install iverilog`.
- **GTKWave**:
    - **Windows**: [Download Page](http://gtkwave.sourceforge.net/).
    - **Linux/WSL**: `sudo apt-get install gtkwave`.

---

### **2. My Verification Workflow (Step-by-Step)**
I've provided two ways to verify my Verilog logic: an automated script for Windows and a manual process for Linux/WSL.

#### **Option A: Automated Simulation (Windows)**
I created a specialized batch script to automate the entire logic verification process. There are two ways to use it:
1.  **One-Click Method**: Simply **Double-Click** the `simple_run.bat` file in your project folder.
2.  **CLI Method**: Open a Command Prompt or PowerShell in the project root and run:
    ```bash
    .\simple_run.bat
    ```
3.  **Result**: My script will automatically compile the source files, run the simulation, and launch **GTKWave** to show my waveforms.

#### **Option B: Makefile Method (Linux / MacOS / WSL)**
For professional environments or Linux users, I have included a dedicated **Makefile**. This allows for one-word commands to manage the entire build cycle.
1.  **To Simulate**: `make sim` (Compiles and runs the simulation).
2.  **To View Waves**: `make wave` (Launches GTKWave with my VCD file).
3.  **To Clean**: `make clean` (Removes the build directory).

#### **Option C: Manual CLI Method (Any Platform)**
If you prefer to run the raw commands manually, here is my recommended sequence:
1.  **Create Build Directory**: `mkdir -p build`
2.  **Compile My Modules**: 
    ```bash
    iverilog -o build/sim.vvp -s tb_secure_lock -I rtl tb/tb_secure_lock.v rtl/*.v
    ```
3.  **Execute Simulation**: `vvp build/sim.vvp`
4.  **View Waveforms**: `gtkwave build/simulation.vcd`

---

### **3. My Synthesis Workflow (Gowin EDA)**
Once we have verified the simulation results, let me walk you through the steps I take for the hardware synthesis stage.


1.  **Open My Project**: Launch Gowin EDA and open **`secure_lock_system.gprj`**.
2.  **Assign Constraints**: I have already mapped my physical pins in **`constraints/secure_lock_system.cst`**. Ensure this file is enabled in the FileList.
3.  **Process Details**:
    - Right-click **"Synthesize"** to convert Verilog to a gate-level netlist.
    - Run **"Place & Route"** to generate the final bitstream (`.fs`).

---

### **4. My Hardware Deployment**
To flash the logic onto my Tang Nano 20K, I use the **Gowin Programmer**:

1.  **Connect Hardware**: Plug in the board via USB-C.
2.  **Scan Device**: Click "Scan Device" to identify the `GW2AR-18C`.
3.  **Configuration**:
    - **Access Mode**: Select **"Embedded Flash Mode"**.
    - **Operation**: Select **"embFlash Erase, Program, Verify"**.
4.  **Execute**: Click the **"Program/Configure"** button.

---

### **5. My Verification Results**
After flashing, I check my onboard diagnostic LEDs:
- **Heartbeat (LED 5)**: This blinks every second to show my logic is alive.
- **Door Monitor (LED 4)**: I use this to visually verify the magnetic sensor state.
- **Sync/Reset (LED 0)**: I programmed this to pulse/flicker when the Reset Button (S1) is pressed.
---

**Designed & Verified by: T. Rajashekar (24J25A0424 - LE)**
**Institution: Joginpally Baskar Rao Engineering College (JBREC)**
**Batch: 2023-2027 (3-2 B.Tech ECE)**
