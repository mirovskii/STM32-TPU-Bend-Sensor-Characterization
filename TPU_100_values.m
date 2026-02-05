%% Configuration
clear; clc; close all;

% 1. SETUP SERIAL PORT
portName = "COM3";  % <--- CHECK YOUR PORT
baudRate = 115200;

try
    s = serialport(portName, baudRate);
    configureTerminator(s, "LF"); 
    flush(s);
    disp("Connected to STM32 successfully!");
catch ME
    error("Failed to connect. Check 'portName' and close other Serial apps.");
end

%% 2. SETUP DASHBOARD LAYOUT
% Create figure
f = figure('Name', 'Smart Glove Dashboard', 'NumberTitle', 'off', 'Color', 'w');

% A. Create Tabs for Graphs (Occupies Top 75% of screen)
tabGroup = uitabgroup(f, 'Position', [0, 0.25, 1, 0.75]);

% --- TAB 1: RESISTANCE ---
t1 = uitab(tabGroup, 'Title', 'Resistance');
ax1 = axes('Parent', t1);
hLine_R = plot(ax1, 0, 0, '-r', 'LineWidth', 1.5);
title(ax1, 'Sensor Resistance (R1)');
grid(ax1, 'on');
ylabel(ax1, 'Resistance (k\Omega)');
xlabel(ax1, 'Sample Number');
ylim(ax1, [0, 70]); % Fixed range: 0 to 70 kOhms
yticks(ax1, 0:5:70); % Grid lines every 5 kOhms

% --- TAB 2: RHO ---
t2 = uitab(tabGroup, 'Title', 'Resistivity (Rho)');
ax2 = axes('Parent', t2);
hLine_Rho = plot(ax2, 0, 0, '-b', 'LineWidth', 1.5);
title(ax2, 'Resistivity (Rho)');
grid(ax2, 'on');
ylabel(ax2, 'Rho (\Omega\cdotm)');
xlabel(ax2, 'Sample Number');
ylim(ax2, [0, 1]); % Fixed range: 0 to 1 Ω·m
yticks(ax2, 0:0.1:1); % Grid lines every 0.1 Ω·m

% --- TAB 3: VOLTAGE (Vtpu) ---
t3 = uitab(tabGroup, 'Title', 'Sensor Voltage');
ax3 = axes('Parent', t3);
hLine_Vtpu = plot(ax3, 0, 0, '-g', 'LineWidth', 1.5);
title(ax3, 'TPU Sensor Voltage (Vtpu)');
grid(ax3, 'on');
ylabel(ax3, 'Voltage (V)');
xlabel(ax3, 'Sample Number');
ylim(ax3, [0 3.5]);

% B. Create Live Table (Occupies Bottom 25% of screen)
columnNames = {'Variable', 'Current Value', 'Window Average (100 samples)'};
rowNames = {};

% Initial data placeholder
initialData = {
    'Vtpu (V)', 0, 0; 
    'Resistance R1 (kΩ)', 0, 0; 
    'Resistivity Rho (Ω·m)', 0, 0
    };

statTable = uitable(f, 'Data', initialData, ...
    'ColumnName', columnNames, ...
    'RowName', rowNames, ...
    'ColumnWidth', {180, 120, 200}, ...
    'Position', [20, 20, 500, 100]); 

% Make table resize automatically with window
statTable.Units = 'normalized';
statTable.Position = [0.05, 0.02, 0.9, 0.2]; 
statTable.FontSize = 12;

%% 3. DATA BUFFERS
windowSize = 100; 
Vtpu_Buffer = zeros(1, windowSize);
R_Buffer    = zeros(1, windowSize);
Rho_Buffer  = zeros(1, windowSize);

%% 4. REAL-TIME LOOP
disp("Starting Stream... Watch the table for averages.");

try
    while true
        % A. Read & Parse
        dataLine = readline(s);
        
        % Parse format: "Vtpu:0.3879, R1: 744.68, Rho:0.229133"
        vals = sscanf(dataLine, "Vtpu:%f, R1: %f, Rho:%f");
        
        if length(vals) == 3
            val_Vtpu = vals(1); 
            val_R    = vals(2) / 1000; % Convert to kOhms
            val_Rho  = vals(3); 
            
            % B. Update Buffers (FIFO Shift)
            Vtpu_Buffer = [Vtpu_Buffer(2:end), val_Vtpu];
            R_Buffer    = [R_Buffer(2:end), val_R];
            Rho_Buffer  = [Rho_Buffer(2:end), val_Rho];
            
            % C. Update Graphs
            set(hLine_Vtpu, 'YData', Vtpu_Buffer, 'XData', 1:windowSize);
            set(hLine_R,    'YData', R_Buffer,    'XData', 1:windowSize);
            set(hLine_Rho,  'YData', Rho_Buffer,  'XData', 1:windowSize);
            
            % Dynamic Y-Axis Scaling (only for Vtpu, R and Rho are fixed)
            
            % Keep Vtpu voltage axis reasonable
            if max(Vtpu_Buffer) > 0.1
                ylim(ax3, [0, max(Vtpu_Buffer)*1.2]);
            end
            
            % --- D. CALCULATE AVERAGES ---
            avg_Vtpu = mean(Vtpu_Buffer);
            avg_R    = mean(R_Buffer);
            avg_Rho  = mean(Rho_Buffer);
            
            % --- E. UPDATE TABLE ---
            tableData = {
                'Vtpu (V)',            sprintf('%.4f', val_Vtpu), sprintf('%.4f', avg_Vtpu);
                'R1 (kΩ)',             sprintf('%.2f', val_R),    sprintf('%.2f', avg_R);
                'Rho (Ω·m)',           sprintf('%.6f', val_Rho),  sprintf('%.6f', avg_Rho)
            };
            
            set(statTable, 'Data', tableData);
            
            drawnow limitrate;
        else
            % Display unparsed data for debugging
            fprintf('Could not parse: %s\n', dataLine);
        end
    end
catch ME
    clear s;
    disp("Stream Stopped.");
    rethrow(ME);
end