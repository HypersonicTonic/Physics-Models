function [F, g,Power_loss, T_op, fill_factor] = SolenoidForceModel(N, V_source, A, AWG, L_coil,r_spool_max)
% SolenoidForceModel Calculates the force, thermal, and geometric properties of a
% solenoid
% usage: 
%    [F, g, Power_loss, T_op, fill_factor] = SolenoidForceModel(150, 3, 0.005,22, 0.05);
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
        V_source (1,1) double {mustBePositive} = 12    % Source Voltage (Volts)
        A (1,1) double {mustBePositive} = 0.005 % Core Cross section (m^2)
        AWG (1,1) double {mustBePositive} = 20 % Wire Gauge (AWG)
        L_coil (1,1) double {mustBePositive} = 0.050 % Axial length of wire coil (meters)
        r_spool_max (1,1) double {mustBePositive} = 0.025 % Max outer radius of bobbin flange (meters)
    end

    %% 1. Wire Geometry and Electrical properties 
    d_wire_mm = 0.127 * 92^((36-AWG)/39);
    d_wire_m = d_wire_mm / 1000;
    wire_area = pi * (d_wire_m / 2)^2;
    rho_copper = 1.68e-8;
    R_per_meter = rho_copper / wire_area;

    %% 2. coil Build & Length Estimation
    r_core = sqrt(A/pi);

    % Total physical space available on the spool
    winding_area_available = (r_spool_max - r_core) *  L_coil;
    
    copper_area_total = N * wire_area;
    eta_packing = 0.80;
    actual_winding_area = copper_area_total / eta_packing;
    build_thickness = actual_winding_area / L_coil;

    % Volumetric Fill factor check
    fill_factor = copper_area_total / winding_area_available;

    if fill_factor > 0.91
        warning('SolenoidModel:GeometricIncompressibility', ...
            'Calculated fill factor (%.2f) exceeds the physical nesting limits (0.91)! Bobbin is overstuffed.', fill_factor);
    elseif fill_factor > 0.75
        warning('SolenoidModel:TightWinding',...
            'Fill Factor (%.2f) is hih. Hand_winding may overflow.', fill_factor);
    end

    % Safety cap for wire length calc: if it physically overflows, max it
    % out at the flange
    if build_thickness > (r_spool_max - r_core)
        build_thickness = r_spool_max - r_core;
    end

    % Mean radius of the  actual wound core
   
    r_mean = r_core + (build_thickness / 2 );
    L_wire = N * (2 * pi * r_mean);
            
    % 3. Coupled Voltage - Thermal feedback model
    alpha = 0.0039;  % temp coefficient of copper (1/C)
    T_amb = 25;     % Ambient temperature (C)
    R_th = 5.0;      % Estimated Thermal resistance
    R_cold = R_per_meter * L_wire; % Base resistance at ambient

    % Derived for fixed voltage:
    % P = V^2 / R(T) -> dT = (V^2 * R_th) / (R_cold * ( 1 + alpha*dT))
    % Solved via quadratic formula to catch steady state operation
    a_quad = alpha;
    b_quad = 1;
    c_quad = -(V_source^2 * R_th) / R_cold;
    
    discriminant = (b_quad^2 - 4*a_quad*c_quad);
    
    delta_T = (-b_quad + sqrt(discriminant))/ (2*a_quad);
    T_op = T_amb + delta_T;

    % 4. Final hot resistance and power loss
    R_hot = R_cold * (1 + alpha * delta_T);
    I_hot = V_source / R_hot;
    I_cold = V_source / R_cold;
    Power_loss = V_source * I_hot;
    J_hot = I_hot / wire_area;

    % Safety check: Current Density
    J = I_hot / wire_area; % Amps/m^2
    
    if T_op > 180
        warning('SolenoidModel:ThermalDamage',...
            'Equilibrium temp is %g C. The copper enamel will melt and short!', T_op);
    end

    % 5. Magnetic Physics and Saturation
    mu_0 = 4 * pi * 1e-7; % Permeability of free space
    mu_r = 2000;          % Relative Permeability of standard electrical steel core
    B_sat = 1.6;          % Tesla (Saturation limit of standard electrical steel
    sig_leak = 1.15;      % Flux leakage factor 

    % air gap vector (0.1mm to 10mm)
    g = linspace(0.0001, 0.010, 200);

    % Calculate Magnetic Flux Density (B) in the gap
    B_gap = (mu_0 * N * I_hot) ./ ((g .* sig_leak) + (L_coil / mu_r));

    % Apply physical saturation limit
    B_actual = min(B_gap, B_sat);

    % Force calculation using Maxwell's stress tensor equation
    F = (B_actual.^2 .* A) ./ (2 * mu_0);
    % 6. Telemetry Output 
    fprintf('\n                           Solenoid Final Metrics                           \n');
    fprintf('Steady-State Temp:            %1.f C (Ambient: %g C)\n',T_op, T_amb);
    fprintf('Hot Operating Current:        %.2f A (Cold Current: %.2f A)\n', I_hot, I_cold);
    fprintf('Power Dissipation:            %.1f Watts\n', Power_loss);
    fprintf('Current Density (Hot):        %.2f A/mm^2\n', J_hot/1e6);
    fprintf('Volumetric Fill Factor:       %.1f%%\n.', fill_factor * 100);
    fprintf('Max Force Output:             %.1f Newtons\n', max(F));
    
    % 7. Plotting (only if no output variables are requested)
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
            sprintf('Copper Fill Factor: %.1f%%', fill_factor * 100),...
            sprintf('Est. Wire Length: %.2f m', L_wire)...
            };

        text(0.5, 0.5, dashboard_text, 'Units','normalized',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','middle',...
            'FontSize',14,'FontWeight','bold','Color','k');
            
    end
end







