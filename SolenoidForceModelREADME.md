# Physics-Models
A Repository for Physics models I make 
# Solenoid Force & Thermal Dynamics Model

**Author:** Harry Prince Thomas  
**Date:** September 20, 2026  
**Language:** MATLAB  

##  Overview
The **Solenoid Force Model** is a robust, preliminary design tool for electro-mechanical engineering. Unlike basic textbook formulas that assume infinite magnetic force and ideal wires, this MATLAB script factors in real-world physical limitations including **magnetic core saturation**, **multi-layer winding geometry**, and **steady-state thermal thermodynamics (heat loss)**.

It is designed to give engineers and hobbyists a rapid 1st-order approximation of a solenoid's performance before moving to expensive CAD or Finite Element Analysis (FEA) software.

##  Key Features
- **Real-World Magnetic Physics:** Uses Maxwell's stress tensor equation but applies a physical saturation limit ($B_{sat}$) to prevent the "infinite force" fallacy at a zero air gap.
- **Thermal Feedback Loop:** Calculates steady-state operating temperature by modeling how heat increases copper resistance, which in turn generates more heat ($I^2R$ loss).
- **Safety Overrides:** Includes automated warnings and error handling for dangerous current densities (e.g., thermal runaway/melting wire).
- **Built-in UI Dashboard:** Automatically generates a presentation-ready plot and a centered text-based dashboard if run without output variables.

##  Usage

Download `SolenoidForceModel.m` and place it in your active MATLAB directory. 

### 1. Quick Visualizer (Default Mode)
If you want to evaluate a default solenoid and view the dashboard, simply call the function with no arguments:

matlab
**SolenoidForceModel()

2. Custom Parameters (Backend Calculation)
You can pass specific parameters to optimize your design.
Syntax: [F, g, Power_loss, T_op] = SolenoidForceModel(N, I, A, AWG)
code
Matlab
% Example: 150 turns, 3 Amps, 0.005 m^2 core area, 22 AWG wire
[Force, Gap, Power, Temp] = SolenoidForceModel(150, 3, 0.005, 22);

% Find the maximum force generated
disp(['Max Force: ', num2str(max(Force)), ' N']);
disp(['Operating Temp: ', num2str(Temp), ' °C']);

Geometry: Winding thickness is estimated assuming square packing. Average wire length accounts for the thickness of the wound spool, not just the bare core.
Thermal: Uses the temperature coefficient of copper (
α
=
0.0039
α=0.0039
) and an estimated thermal resistance (
5.0
∘
C/W
5.0 
∘
 C/W
) to find steady-state operating temperature.
Magnetics: Caps magnetic flux density at 
1.6
 T
1.6 T
 (standard electrical steel) to provide realistic force approximations as the air gap approaches 
0
 mm
0 mm
.**
