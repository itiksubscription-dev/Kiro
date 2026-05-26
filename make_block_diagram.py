"""
System Architecture / Block Diagram
Smart Automated Fruit & Plant Fermentation System for Liquid Organic Fertilizer
Format mirrors the LPR reference diagram (HARDWARE | SOFTWARE split).
"""

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle
from matplotlib.lines import Line2D


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def box(ax, x, y, w, h, text, fontsize=8, lw=1.2, fc="white"):
    """Draw a rectangle with centered text."""
    rect = Rectangle((x, y), w, h, linewidth=lw, edgecolor="black",
                     facecolor=fc, zorder=2)
    ax.add_patch(rect)
    ax.text(x + w / 2, y + h / 2, text,
            ha="center", va="center", fontsize=fontsize, zorder=3,
            wrap=True)


def list_box(ax, x, y, w, h, title, items, fontsize=7.5):
    """Draw a rectangle with a title and a bulleted list."""
    rect = Rectangle((x, y), w, h, linewidth=1.2, edgecolor="black",
                     facecolor="white", zorder=2)
    ax.add_patch(rect)
    ax.text(x + w / 2, y + h - 0.35, title,
            ha="center", va="top", fontsize=fontsize + 0.5,
            fontweight="bold", zorder=3)
    for i, item in enumerate(items):
        ax.text(x + 0.25, y + h - 0.95 - i * 0.45,
                f"• {item}",
                ha="left", va="top", fontsize=fontsize, zorder=3)


def arrow(ax, x1, y1, x2, y2, lw=1.1):
    """Draw an arrow from (x1,y1) to (x2,y2)."""
    a = FancyArrowPatch((x1, y1), (x2, y2),
                        arrowstyle="-|>", mutation_scale=10,
                        color="black", lw=lw, zorder=4)
    ax.add_patch(a)


def line(ax, x1, y1, x2, y2, lw=1.1):
    """Draw a plain line (no arrowhead)."""
    ax.add_line(Line2D([x1, x2], [y1, y2], color="black", lw=lw, zorder=4))


# -----------------------------------------------------------------------------
# Figure setup
# -----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(16, 10))
ax.set_xlim(0, 32)
ax.set_ylim(0, 20)
ax.set_aspect("equal")
ax.axis("off")

# -----------------------------------------------------------------------------
# Title bar
# -----------------------------------------------------------------------------
title_text = ("LOFP-ML: Machine-Learning Integrated Extraction and Fermentation\n"
              "System for Liquid Organic Fertilizer Production")
title_box = FancyBboxPatch((6, 18.2), 20, 1.4,
                           boxstyle="round,pad=0.05",
                           linewidth=1.4, edgecolor="black",
                           facecolor="white", zorder=2)
ax.add_patch(title_box)
ax.text(16, 18.9, title_text, ha="center", va="center",
        fontsize=11, fontweight="bold")

# -----------------------------------------------------------------------------
# HARDWARE container (left)
# -----------------------------------------------------------------------------
hw_x, hw_y, hw_w, hw_h = 0.5, 0.5, 15.0, 17.2
ax.add_patch(Rectangle((hw_x, hw_y), hw_w, hw_h, fill=False,
                       linewidth=1.5, edgecolor="black", zorder=1))
ax.text(hw_x + hw_w / 2, hw_y + 0.25, "HARDWARE",
        ha="center", va="bottom", fontsize=11, fontweight="bold")

# --- Power subsystem (top of hardware panel) ---------------------------------
pwr_x, pwr_y, pwr_w, pwr_h = 1.0, 14.5, 14.0, 2.7
ax.add_patch(Rectangle((pwr_x, pwr_y), pwr_w, pwr_h, fill=False,
                       linewidth=1.0, edgecolor="black", zorder=1))
ax.text(pwr_x + pwr_w / 2, pwr_y + 0.15, "POWER SUBSYSTEM",
        ha="center", va="bottom", fontsize=8.5, fontweight="bold")

box(ax, 1.4, 15.7, 2.2, 1.0, "220V AC")
arrow(ax, 3.6, 16.2, 4.4, 16.2)
box(ax, 4.4, 15.7, 2.4, 1.0, "SMPS\n12V DC")
arrow(ax, 6.8, 16.2, 7.6, 16.2)
box(ax, 7.6, 15.7, 3.0, 1.0, "LM2596\nBuck Converter")
arrow(ax, 10.6, 16.2, 11.4, 16.2)
box(ax, 11.4, 15.7, 3.2, 1.0, "5V / 3.3V Rails\nto MCU & Sensors")

# --- Extraction subsystem ----------------------------------------------------
ex_x, ex_y, ex_w, ex_h = 1.0, 10.5, 14.0, 3.7
ax.add_patch(Rectangle((ex_x, ex_y), ex_w, ex_h, fill=False,
                       linewidth=1.0, edgecolor="black", zorder=1))
ax.text(ex_x + ex_w / 2, ex_y + 0.15, "EXTRACTION SUBSYSTEM",
        ha="center", va="bottom", fontsize=8.5, fontweight="bold")

box(ax, 1.4, 12.7, 2.8, 1.0, "Load Cell\n+ HX711")
arrow(ax, 4.2, 13.2, 6.0, 13.2)
box(ax, 6.0, 12.7, 3.0, 1.0, "ESP32\n(Central MCU)", fc="#f2f2f2")
arrow(ax, 9.0, 13.2, 10.4, 13.2)
box(ax, 10.4, 12.7, 3.2, 1.0, "BTS7960\nMotor Driver")

box(ax, 6.0, 11.0, 3.0, 1.0, "DC Gear Motor\n(12-24V)")
arrow(ax, 12.0, 12.7, 9.0, 11.5)             # BTS7960 -> motor
box(ax, 1.4, 11.0, 3.5, 1.0, "Industrial Grinder\n/ Shredder")
arrow(ax, 6.0, 11.5, 4.9, 11.5)               # motor -> grinder

# --- Fermentation chamber subsystem ------------------------------------------
fc_x, fc_y, fc_w, fc_h = 1.0, 1.2, 14.0, 9.0
ax.add_patch(Rectangle((fc_x, fc_y), fc_w, fc_h, fill=False,
                       linewidth=1.0, edgecolor="black", zorder=1))
ax.text(fc_x + fc_w / 2, fc_y + 0.15, "FERMENTATION CHAMBER",
        ha="center", va="bottom", fontsize=8.5, fontweight="bold")

# Sensor cluster (left column inside fermentation box)
box(ax, 1.4, 8.6, 3.4, 0.9, "pH Sensor\n(SEN0161)")
box(ax, 1.4, 7.5, 3.4, 0.9, "MQ-135\nGas Sensor (CO2)")
box(ax, 1.4, 6.4, 3.4, 0.9, "DHT11 / DHT22\nTemp & Humidity")
box(ax, 1.4, 5.3, 3.4, 0.9, "DS18B20\nLiquid Temp")
box(ax, 1.4, 4.2, 3.4, 0.9, "DS3231 RTC\nTimestamp")

# ESP32 hub inside fermentation chamber
box(ax, 6.0, 6.4, 3.5, 1.5, "ESP32\nSensor Hub", fc="#f2f2f2")
for sy in (9.05, 7.95, 6.85, 5.75, 4.65):
    arrow(ax, 4.8, sy, 6.0, 7.15)

# Actuators (right column)
box(ax, 11.0, 8.6, 3.5, 0.9, "MIX-4045\nDual Relay")
arrow(ax, 9.5, 7.7, 11.0, 9.0)
box(ax, 11.0, 7.5, 3.5, 0.9, "Stirrer Motor")
arrow(ax, 12.75, 8.6, 12.75, 8.4)

box(ax, 11.0, 6.0, 3.5, 0.9, "ITC-308\nTemp Controller")
arrow(ax, 9.5, 7.0, 11.0, 6.5)
box(ax, 11.0, 4.9, 3.5, 0.9, "12V Heating Pad")
box(ax, 11.0, 3.8, 3.5, 0.9, "12V Cooling Fan")
arrow(ax, 12.75, 6.0, 12.75, 5.8)
arrow(ax, 12.75, 6.0, 12.75, 4.7)

# Output of fermentation chamber
box(ax, 6.0, 2.3, 3.5, 1.0, "Mechanical Filter\n(Solids -> Liquid)")
arrow(ax, 7.75, 4.2, 7.75, 3.3)
box(ax, 11.0, 2.3, 3.5, 1.0, "Liquid Organic\nFertilizer Output")
arrow(ax, 9.5, 2.8, 11.0, 2.8)

# -----------------------------------------------------------------------------
# Bridge between hardware and software
# -----------------------------------------------------------------------------
arrow(ax, 9.5, 7.15, 16.5, 7.15, lw=1.4)
arrow(ax, 16.5, 7.5, 9.5, 7.5, lw=1.4)
ax.text(13.0, 7.85, "Wi-Fi / HTTP REST",
        ha="center", va="bottom", fontsize=8, style="italic")

# -----------------------------------------------------------------------------
# SOFTWARE container (right)
# -----------------------------------------------------------------------------
sw_x, sw_y, sw_w, sw_h = 16.5, 0.5, 15.0, 17.2
ax.add_patch(Rectangle((sw_x, sw_y), sw_w, sw_h, fill=False,
                       linewidth=1.5, edgecolor="black", zorder=1))
ax.text(sw_x + sw_w / 2, sw_y + 0.25, "SOFTWARE",
        ha="center", va="bottom", fontsize=11, fontweight="bold")

# --- Raspberry Pi pipeline (top) ---------------------------------------------
box(ax, 17.0, 15.7, 4.0, 1.4, "Raspberry Pi 5\n(Central Server)", fc="#f2f2f2")
arrow(ax, 21.0, 16.4, 22.0, 16.4)
box(ax, 22.0, 15.7, 4.0, 1.4, "Python Pipeline\n(pandas / NumPy)")
arrow(ax, 26.0, 16.4, 27.0, 16.4)
box(ax, 27.0, 15.7, 4.0, 1.4, "Data Pre-Processing\nNorm. / Outliers / NaN")

# --- Machine Learning models -------------------------------------------------
ml_x, ml_y, ml_w, ml_h = 17.0, 11.5, 14.0, 3.7
ax.add_patch(Rectangle((ml_x, ml_y), ml_w, ml_h, fill=False,
                       linewidth=1.0, edgecolor="black", zorder=1))
ax.text(ml_x + ml_w / 2, ml_y + 0.15, "MACHINE LEARNING ENGINE",
        ha="center", va="bottom", fontsize=8.5, fontweight="bold")

box(ax, 17.4, 12.7, 6.2, 2.0,
    "Isolation Forest\n(Unsupervised)\nAnomaly Detection\non sensor stream")
box(ax, 24.4, 12.7, 6.2, 2.0,
    "Random Forest\n(Supervised)\nStage Classification:\nEarly / Active /\nNear-Ready / Ready")

arrow(ax, 29.0, 15.7, 27.5, 14.7)
arrow(ax, 29.0, 15.7, 20.5, 14.7)

# --- Database ----------------------------------------------------------------
box(ax, 17.0, 9.6, 6.5, 1.4,
    "InfluxDB\nTime-Series Database\n(timestamped sensor logs)")
arrow(ax, 20.5, 12.7, 20.25, 11.0)
arrow(ax, 27.5, 12.7, 23.5, 11.0)

# --- Communication / API -----------------------------------------------------
box(ax, 24.0, 9.6, 7.0, 1.4,
    "HTTP / REST API\n(ESP32 <-> Raspberry Pi)")

# --- User-facing interfaces (bottom) -----------------------------------------
list_box(ax, 17.0, 4.8, 6.5, 4.2,
         "BLYNK IoT MOBILE APP",
         ["Live sensor graphs",
          "pH / Temp / CO2 readouts",
          "Stage classification alerts",
          "Anomaly notifications",
          "Manual actuator override",
          "Remote Wi-Fi access"])

list_box(ax, 24.0, 4.8, 7.0, 4.2,
         "LOCAL ON-DEVICE DISPLAY",
         ["16x2 LCD (I2C)",
          "Real-time pH / Temp / CO2",
          "Current fermentation stage",
          "System status indicators",
          "SD Card backup logging",
          "Offline operation support"])

# --- Researcher / Admin block ------------------------------------------------
list_box(ax, 17.0, 1.0, 14.0, 3.5,
         "RESEARCHER / ADMIN INTERFACE",
         ["Training data export from InfluxDB (CSV)",
          "Model retraining and evaluation (scikit-learn)",
          "Performance metrics: accuracy, precision, recall, F1",
          "System throughput & fermentation duration analysis",
          "Comparison: automated vs traditional fermentation"])

# Connect Blynk/LCD to RPi
arrow(ax, 19.0, 9.6, 19.0, 9.0)
arrow(ax, 27.5, 9.6, 27.5, 9.0)

# -----------------------------------------------------------------------------
# Save figure
# -----------------------------------------------------------------------------
plt.tight_layout()
plt.savefig("system_architecture.png", dpi=200, bbox_inches="tight",
            facecolor="white")
print("Saved: system_architecture.png")
