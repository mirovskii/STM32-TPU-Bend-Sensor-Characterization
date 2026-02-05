# STM32-TPU-Bend-Sensor-Characterization
Characterization and measurement system design for conductive TPU-based flexible bend sensors using STM32.

# STM32 Based Flexible Bend Sensor Characterization

This project focuses on designing a low-cost, 3D-printable flexible bend sensor using carbon-filled conductive TPU (Filaflex) and developing a high-precision measurement system.

## Key Features
- **Microcontroller:** STM32 Nucleo-G070RB (ARM Cortex-M0+).
- **Measurement Topology:** Custom **Differential Voltage Divider** to eliminate contact resistance instability.
- **Data Handling:** ADC data acquisition with **DMA (Circular Mode)** to minimize CPU overhead.
- **Signal Processing:** 1000-sample Moving Average Filter for noise reduction.
- **Visualization:** Real-time resistance and resistivity analysis via MATLAB.

## Hardware Design
The system solves the mechanical instability of the 4-Wire (Kelvin) method on flexible surfaces by using a dual-channel ADC approach.

## Experimental Results
- Confirmed **Negative Piezoresistive Effect** in TPU materials.
- Analyzed the impact of FDM printing parameters on material anisotropy.
