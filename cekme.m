%% TPU Stretch Test - Data Visualization
% Columns: Verino, Time_s, Force_g, Resis_K, movem_mm

clear; clc; close all;

%% ── Load Data ─────────────────────────────────────────────────────────────
data = readtable('archive_2026_05_22_14_55_00.csv');
data = rmmissing(data);
data = sortrows(data, 'Verino');

t  = data.Verino;       % Data Number
F  = data.Force_g;      % Force (g)
R  = data.Resis_K;      % Resistance (kΩ)
E  = data.movem_mm;     % Elongation (mm)


%% ── Common style settings ─────────────────────────────────────────────────
lw  = 1.5;   % line width
fs  = 12;    % font size for labels and ticks
tfs = 13;    % font size for title


%% ── Figure 1: Force vs Time ───────────────────────────────────────────────
figure('Name','Force vs Time','NumberTitle','off');
plot(t, F, 'b-', 'LineWidth', lw);
xlabel('Time (s)',          'FontSize', fs);
ylabel('Force (g)',         'FontSize', fs);
title('Force vs Time',      'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 2: Resistance vs Time ─────────────────────────────────────────
figure('Name','Resistance vs Time','NumberTitle','off');
plot(t, R, 'r-', 'LineWidth', lw);
xlabel('Time (s)',           'FontSize', fs);
ylabel('Resistance (k\Omega)', 'FontSize', fs);
title('Resistance vs Time',  'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 3: Elongation vs Time ─────────────────────────────────────────
figure('Name','Elongation vs Time','NumberTitle','off');
plot(t, E, 'g-', 'LineWidth', lw);
xlabel('Time (s)',            'FontSize', fs);
ylabel('Elongation (mm)',     'FontSize', fs);
title('Elongation vs Time',   'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 4: Force AND Resistance vs Time (dual y-axis) ─────────────────
figure('Name','Force & Resistance vs Time','NumberTitle','off');

yyaxis left;
plot(t, F, 'b-', 'LineWidth', lw);
ylabel('Force (g)', 'FontSize', fs);

yyaxis right;
plot(t, R, 'r-', 'LineWidth', lw);
ylabel('Resistance (k\Omega)', 'FontSize', fs);

xlabel('Time (s)',                       'FontSize', fs);
title('Force and Resistance vs Time',    'FontSize', tfs);
legend('Force (g)', 'Resistance (k\Omega)', 'Location', 'best');
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 5: Force vs Elongation (gradient color) ───────────────────────
figure('Name','Force vs Elongation','NumberTitle','off');

% Same gradient: light orange → dark brown
start_color = [1.0, 0.75, 0.45];
end_color   = [0.5, 0.15, 0.0];

n = length(E);

gradient_colors = [linspace(start_color(1), end_color(1), n)', ...
                   linspace(start_color(2), end_color(2), n)', ...
                   linspace(start_color(3), end_color(3), n)'];

X = [E(:), E(:)];
Y = [F(:), F(:)];
Z = zeros(n, 2);
C = [(1:n)', (1:n)'];

surface(X, Y, Z, C, ...
    'EdgeColor', 'flat', ...
    'FaceColor', 'none', ...
    'LineWidth', 1.2);

colormap(gradient_colors);
cb = colorbar;
cb.Label.String = 'Measurement Number';
clim([1, n]);

xlabel('Elongation (mm)',       'FontSize', fs);
ylabel('Force (g)',             'FontSize', fs);
title('Force vs Elongation',    'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 6: Resistance vs Elongation (gradient color) ──────────────────
figure('Name','Resistance vs Elongation','NumberTitle','off');

% Start color (light orange) → End color (dark brown), same style as your bend code
start_color = [1.0, 0.75, 0.45];
end_color   = [0.5, 0.15, 0.0];

n = length(E);  % total number of data points (4001)

% Build the custom gradient colormap
gradient_colors = [linspace(start_color(1), end_color(1), n)', ...
                   linspace(start_color(2), end_color(2), n)', ...
                   linspace(start_color(3), end_color(3), n)'];

% surface() trick: colors a single continuous line by index
% We need 2-column matrices for X, Y, Z and color (C)
X = [E(:), E(:)];
Y = [R(:), R(:)];
Z = zeros(n, 2);
C = [(1:n)', (1:n)'];   % color index, goes from 1 to n

surface(X, Y, Z, C, ...
    'EdgeColor', 'flat', ...   % color the edges (= the line)
    'FaceColor', 'none', ...   % no face fill
    'LineWidth', 1.2);

colormap(gradient_colors);
cb = colorbar;
cb.Label.String = 'Measurement Number';
clim([1, n]);

xlabel('Elongation (mm)',           'FontSize', fs);
ylabel('Resistance (k\Omega)',      'FontSize', fs);
title('Resistance vs Elongation',   'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);


%% ── Figure 7: Average Resistance vs Elongation (Hysteresis loop) ─────────
figure('Name','Avg Resistance vs Elongation - Hysteresis','NumberTitle','off');

% Detect phase direction using diff
dE = diff(E);
dE = [dE(1); dE];          % pad first point (assume stretching at start)

stretch_mask = dE >= 0;    % elongation increasing → stretching
release_mask = dE <  0;    % elongation decreasing → releasing

% Round elongation to 1 decimal to group into bins (0.0, 0.1, 0.2 ... 10.0)
E_rounded = round(E, 1);
E_unique  = unique(E_rounded);

avg_R_stretch = zeros(length(E_unique), 1);
avg_R_release = zeros(length(E_unique), 1);

for i = 1:length(E_unique)
    e_val = E_unique(i);

    idx_s = E_rounded == e_val & stretch_mask;
    if any(idx_s)
        avg_R_stretch(i) = mean(R(idx_s));
    else
        avg_R_stretch(i) = NaN;
    end

    idx_r = E_rounded == e_val & release_mask;
    if any(idx_r)
        avg_R_release(i) = mean(R(idx_r));
    else
        avg_R_release(i) = NaN;
    end
end

plot(E_unique, avg_R_stretch, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 3);
hold on;
plot(E_unique, avg_R_release, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 3);

xlabel('Elongation (mm)',                              'FontSize', fs);
ylabel('Resistance (k\Omega)',                         'FontSize', fs);
title('Average Resistance vs Elongation (Hysteresis)', 'FontSize', tfs);
legend('Stretching (0 \rightarrow 5mm)', ...
       'Releasing (5 \rightarrow 0mm)', 'Location', 'best');
grid on;
set(gca, 'FontSize', fs);