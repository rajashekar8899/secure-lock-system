# --- SECURE DUAL-HARDWARE LOCKING SYSTEM: BUILD SYSTEM (V1.0) ---
# STRUCTURED BY: T. Rajashekar (24J25A0424 - LE), M. Shailusha (23J21A0424), G. Krithin (24J25A0407 - LE) | JBREC ECE

COMPILER = iverilog
RUNNER = vvp
VIEWER = gtkwave

SRC = rtl/*.v
TB = tb/tb_secure_lock.v
BUILD_DIR = build
TARGET = $(BUILD_DIR)/sim.vvp
VCD = $(BUILD_DIR)/simulation.vcd

all: sim

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) $(TB) | $(BUILD_DIR)
	$(COMPILER) -o $(TARGET) -s tb_secure_lock -I rtl $(TB) $(SRC)

sim: $(TARGET)
	$(RUNNER) $(TARGET)

wave: $(VCD)
	$(VIEWER) $(VCD)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all sim wave clean
