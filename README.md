# STM32 Based Flexible Bend Sensor Characterization & Measurement System

This project focuses on the development and characterization of low-cost, 3D-printable flexible bend sensors using carbon-filled conductive TPU (Filaflex). A high-precision measurement system was designed using an STM32 microcontroller to evaluate the piezoresistive properties of these materials for wearable HMI (Human-Machine Interface) applications.

## Key Engineering Highlights
- **Microcontroller:** STM32 Nucleo-G070RB (ARM Cortex-M0+).
- **Measurement Innovation:** Developed a **Differential Voltage Divider** topology to eliminate mechanical instability and contact resistance errors common in 4-Wire (Kelvin) methods on flexible surfaces.
- **Data Acquisition:** Implemented **ADC with DMA (Circular Mode)** to ensure high-speed, real-time data streaming with zero CPU overhead.
- **Signal Integrity:** 1000-sample Moving Average filter implemented on-chip for noise reduction.

## Hardware Architecture
The system uses a custom-designed voltage divider circuit to capture the resistance changes of the TPU sensor during bending.

[Differential Voltage Divider Circuit](differential_voltage_divider_circuit.svg)

## Software & Analysis
The firmware is written in C using STM32CubeIDE. Real-time data is transmitted via UART (115200 baud) to a custom MATLAB interface for live resistivity ($\rho$) and resistance ($R$) analysis.

- **Embedded:** HAL Drivers, DMA, Interrupts.
- **Signal Processing:** Moving Average Filter.
- **Analysis:** MATLAB Data Acquisition Toolbox.

[Flowchart od STM32 Code](stm32_code_flowchart.png)
[Flowchart od MATLAB Code](matlab_code_flowchart.png)

## Experimental Results
- **Negative Piezoresistive Effect:** Observed a decrease in resistance during stretching due to the Percolation Theory.
- **Anisotropy Analysis:** Analyzed how FDM printing parameters and layer orientation affect the material's bulk resistivity.

[Instrant Resistivity Measurement On MATLAB](instant_resistivity_measurement_from_matlab.png)

## Conclusion
The developed TPU-based sensors provide a 90% cost reduction compared to commercial alternatives while maintaining high sensitivity for smart glove and rehabilitation applications.
