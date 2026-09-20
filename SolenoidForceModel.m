function [F, g,Power_loss, T_op] = SolenoidForceModel(N, I, A, AWG)
% SolenoidForceModel Calculatest the force and thermal properties of a
% solenoid
% usage: 
%    [F, g, Power_loss, T_op] = SolenoidForceModel(150, 3, 0.005,22);
%    [F, g] = SolenoidForceModel(); % Runs with defaults and plots
%
% Author: Harry Prince Thomas
% Date: September 20, 2026
% Description: Evaluates a solenoid's force across varying air gaps,
% factoring in core saturation, flux leakage, multilayer winding geometry,
% and steady-state thermal temperature rise.

    % input validation and defaults arguments
    arguments
        N (1,1) double {mustBePositive} = 100  % number of turns 
        I (1,1) double {mustBePositive} = 5    % Current ( Amperes)
        A (1,1) double {mustBePositive} = 0.005 % Core Cross section (m^2)
        AWG (1,1) double {mustBePositive} = 20 % Wire Gauge (AWG)
    end

    %% 1. Wire Geometry and Electrical properties 
    d_wire_mm = 0.127 * 92^((36-AWG)/39);
    d_wire_m = d_wire_mm / 1000;
    wire_area = pi * (d_wire_m / 2)^2;
    rho_copper = 1.68e-8;
    R_per_meter = rho_copper / wire_area;

    % Safety check: Current Density
    J = I / wire_area; % Amps/m^2
    if J > 6e6
        warning('SolenoidModel:ThermalDamage',...
            'AWG %d is likely too thin for %g Amps. Current density exceeds 6A/mm^2', AWG,I);
    end

    %% 2. coil Build & Length Estimation
    r_core = sqrt(A/pi);

    %Estimate winding thickness assuming a square packing cross section
    winding_area = N * (d_wire_m^2);
    build_thickness = sqrt(winding_area);

    % Mean radius of the winding is larger than the core 
    r_mean = r_core + (build_thickness / 2 );
    L_wire = N * (2 * pi * r_mean);

    % thermal feedback model
    alpha = 0.0039;  % temp coefficient of copper (1/C)
    T_amb = 25;     % Ambient temperature (C)
    R_th = 5.0;      % Estimated Thermal resistance
    R_cold = R_per_meter * L_wire; % Base resistance at ambient

    % Calculate steady state temperature accounting for positive feedback
    % loop ( Heat increases R, which increases heat)
    % Formula derived from dT = I^2 * R0 * (1 + alpha*dT) * Rth
    denominator = 1 -(I^2 * R_cold * alpha * R_th);
    if denominator <= 0
        error('Thermal runaway! The coil will melt at this current and gauge.');
    end
    
    delta_T = (I^2 * R_cold * R_th) / denominator;
    T_op = T_amb + delta_T;

    % 3. Final hot resistance and power loss
    R_total = (R_cold * (1 + alpha * delta_T));
    Power_loss = I^2 * R_total;

    % 4. Magnetic Physics and Saturation
    mu_0 = 4 * pi * 1e-7; % Permeability of free space
    B_sat = 1.6;          % Tesla (Saturation limit of standard electrical steel
    sig_leak = 1.15;      % Flux leakage factor 

    % air gap vector (0.1mm to 10mm)
    g = linspace(0.0001, 0.010, 200);

    % Calculate Magnetic Flux Density (B) in the gap
    % B = mu_0 * N * I / (g * leakage)
    B_gap = (mu_0 * N * I) ./ (g .* sig_leak);

    % Apply physical saturation limit
    B_actual = min(B_gap, B_sat);

    % Force calculation using Maxwell's stress tensor equation
    F = (B_actual.^2 .* A) ./ (2 * mu_0);

    % 5. Plotting (only if no output variables are requested)
    if nargout == 0 
        figure('Name','Solenoid Force Model','Color','w');

        subplot(2,1,1)
        plot(g * 1000, F, 'b-','LineWidth',3);
        grid on;

        set(gca, 'FontSize', 12, 'FontWeight', 'bold');

        xlabel('Air gap (mm)','FontSize',14,'FontWeight','bold','Color','k');
        ylabel('Force (Newtons)','FontSize',14,'FontWeight','bold','Color','k');
        title(sprintf('Solenoid Force vs Gap (Max Force: %.1f N)', max(F)),'FontSize',16,'FontWeight','bold','Color','k');

        
        subplot(2,1,2)
        axis off;
        dashboard_text = { ...
            sprintf('Wire Gauge: AWG %d', AWG),...
            sprintf('Steady-State Temp: %.1f C', T_op),...
            sprintf('Power Loss (Heat): %.1f W', Power_loss),...
            sprintf('Est. Wire Length: %.2f m', L_wire)...
            };

        text(0.5, 0.5, dashboard_text, 'Units','normalized',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','middle',...
            'FontSize',14,'FontWeight','bold','Color','k');
            
    end
end






