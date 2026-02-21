:: --- SECURE DUAL-HARDWARE LOCKING SYSTEM: AUTOMATION SUITE (V1.0) ---
:: AUTHORS: T. Rajashekar (24J25A0424 - LE), M. Shailusha (23J21A0424), G. Krithin (24J25A0407 - LE) | JBREC ECE
:: My Customized FPGA Simulation Automation Tool
@echo off
setlocal enabledelayedexpansion

:: --- PATH DISCOVERY ---
:: 1. Check if tools are already in the system PATH
where iverilog >nul 2>&1
if !errorlevel! equ 0 (
    set "IV_CMD=iverilog"
) else (
    :: 2. Fallback to common hardcoded paths
    if exist "C:\iverilog\bin\iverilog.exe" (
        set "IV_CMD=C:\iverilog\bin\iverilog"
    ) else (
        echo [ERROR] iverilog not found in PATH or C:\iverilog\bin.
        pause & exit /b 1
    )
)

where vvp >nul 2>&1
if !errorlevel! equ 0 (
    set "VVP_CMD=vvp"
) else (
    if exist "C:\iverilog\bin\vvp.exe" (
        set "VVP_CMD=C:\iverilog\bin\vvp"
    ) else (
        set "VVP_CMD="
    )
)

:: 3. GTKWave Discovery
where gtkwave >nul 2>&1
if !errorlevel! equ 0 (
    set "GTK_CMD=gtkwave"
) else (
    if exist "C:\iverilog\gtkwave\bin\gtkwave.exe" (
        set "GTK_CMD=C:\iverilog\gtkwave\bin\gtkwave"
    ) else if exist "C:\iverilog\bin\gtkwave.exe" (
        set "GTK_CMD=C:\iverilog\bin\gtkwave"
    ) else (
        set "GTK_CMD="
    )
)

echo ========================================

:: Create build directory if it doesn't exist
if not exist build mkdir build

echo [1/3] Compiling Verilog files...
"!IV_CMD!" -DSIMULATION -o build/sim.vvp -s tb_secure_lock -I rtl tb/tb_secure_lock.v rtl/*.v
if !errorlevel! neq 0 (
    echo.
    echo ❌ Error during compilation!
    pause & exit /b !errorlevel!
)

echo [2/3] Running Simulation...
"!VVP_CMD!" build/sim.vvp
if !errorlevel! neq 0 (
    echo.
    echo ❌ Error during simulation!
    pause & exit /b !errorlevel!
)

echo [3/3] Launching GTKWave...
if exist build/simulation.vcd (
    echo ✅ Simulation successful.
    if defined GTK_CMD (
        echo Opening waveforms...
        "!GTK_CMD!" build/simulation.vcd
    ) else (
        echo [WARN] GTKWave not found. Please view build/simulation.vcd manually.
        pause
    )
) else (
    echo.
    echo ❌ VCD file not found! Check testbench $dumpfile path.
    pause
)
