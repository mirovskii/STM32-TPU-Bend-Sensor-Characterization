%% ============================================================
%% TPU Stretch Test - Hybrid Shape (Chain + Bar in Series)
%%
%% Shape: segmented chain (squares + bridges) connected in series
%%        with a straight bar at the top. Current path:
%%        [LEFT PAD] -> [chain: sq-br-sq-br-...] -> [corner] -> [bar] -> [RIGHT PAD]
%%
%% Option 1 : True conductivity at unstretched state (sigma_0)
%% Option 2 : Effective conductivity vs elongation (sigma_eff)
%% GF       : Gauge Factor vs elongation
%% ============================================================

clear; clc; close all;

%% ── 1. Manual Inputs ─────────────────────────────────────────
fprintf('========================================\n');
fprintf('   TPU Hybrid Shape Stretch Analysis\n');
fprintf('   (Segmented Chain + Straight Bar)\n');
fprintf('========================================\n\n');

fprintf('--- Chain Section: Square Segments ---\n');
L_sq = input('Square side length    L_sq (mm): ');
W_sq = input('Square side width     W_sq (mm): ');
N_sq = input('Number of squares     N_sq     : ');

fprintf('\n--- Chain Section: Bridge Segments ---\n');
L_br = input('Bridge length         L_br (mm): ');
W_br = input('Bridge width          W_br (mm): ');
N_br = input('Number of bridges     N_br     : ');

fprintf('\n--- Straight Bar Section ---\n');
L_bar = input('Bar length            L_bar (mm): ');
W_bar = input('Bar width             W_bar (mm): ');

fprintf('\n--- Common Dimension ---\n');
T0 = input('Sample thickness      T0    (mm): ');

fprintf('\n--- Gauge Length ---\n');
L0 = input('Initial gauge length  L0    (mm): ');

fprintf('\n');

%% ── 2. Geometric Factor Calculation ─────────────────────────
%% Each section contributes its own geometric factor G = L/A (mm^-1)
%% All sections are in series so G_total = G_chain + G_bar

A_sq  = W_sq  * T0;   % cross-section of one square  (mm^2)
A_br  = W_br  * T0;   % cross-section of one bridge  (mm^2)
A_bar = W_bar * T0;   % cross-section of the bar     (mm^2)

G_sq_total  = N_sq * (L_sq / A_sq);    % geometric factor: all squares  (mm^-1)
G_br_total  = N_br * (L_br / A_br);    % geometric factor: all bridges  (mm^-1)
G_chain     = G_sq_total + G_br_total; % geometric factor: chain section (mm^-1)
G_bar       = L_bar / A_bar;           % geometric factor: bar section   (mm^-1)
G_total     = G_chain + G_bar;         % total geometric factor          (mm^-1)

% Total physical path length
L_path = N_sq * L_sq + N_br * L_br + L_bar;

fprintf('----------------------------------------\n');
fprintf('Geometry Summary:\n');
fprintf('  A_sq           : %.4f mm^2\n', A_sq);
fprintf('  A_br           : %.4f mm^2\n', A_br);
fprintf('  A_bar          : %.4f mm^2\n', A_bar);
fprintf('  G_chain (sq)   : %.4f mm^-1\n', G_sq_total);
fprintf('  G_chain (br)   : %.4f mm^-1\n', G_br_total);
fprintf('  G_chain total  : %.4f mm^-1\n', G_chain);
fprintf('  G_bar          : %.4f mm^-1\n', G_bar);
fprintf('  G_total        : %.4f mm^-1\n', G_total);
fprintf('  Total path L   : %.2f  mm\n',   L_path);
fprintf('----------------------------------------\n\n');

% Resistance share of each section (proportional to G)
pct_chain = (G_chain / G_total) * 100;
pct_bar   = (G_bar   / G_total) * 100;
fprintf('Resistance share:\n');
fprintf('  Chain section  : %.1f %%\n', pct_chain);
fprintf('    Squares only : %.1f %%\n', (G_sq_total/G_total)*100);
fprintf('    Bridges only : %.1f %%\n', (G_br_total/G_total)*100);
fprintf('  Bar section    : %.1f %%\n', pct_bar);
fprintf('----------------------------------------\n\n');

%% ── 3. Load Data ─────────────────────────────────────────────
data = readtable('archive_2026_05_22_14_38_23.csv');

R = data.Resis_K;    % Resistance  (kOhm)
E = data.movem_mm;   % Elongation  (mm)

%% ── 4. Auto Detect Cycles ────────────────────────────────────
max_elong = max(E);
tol_peak  = max_elong * 0.02;
tol_zero  = 0.05;

is_valley  = E <= tol_zero;
valley_idx = find(is_valley & [true; ~is_valley(1:end-1)]);

is_peak  = E >= max_elong - tol_peak;
peak_idx = find(is_peak & [true; ~is_peak(1:end-1)]);

num_cycles = min(length(valley_idx) - 1, length(peak_idx));

fprintf('----------------------------------------\n');
fprintf('Auto Detection Results:\n');
fprintf('  Max elongation  : %.2f mm\n',  max_elong);
fprintf('  Cycles detected : %d\n',       num_cycles);
fprintf('  Zero crossings  : %d\n',       length(valley_idx));
fprintf('----------------------------------------\n\n');

%% ── 5. Assign Cycle ID and Phase ─────────────────────────────
phase   = zeros(length(E), 1);
cyc_num = zeros(length(E), 1);

for k = 1:num_cycles
    v_start = valley_idx(k);
    v_end   = valley_idx(k + 1);
    p       = peak_idx(k);

    phase(v_start:p)   = 1;   % stretching
    cyc_num(v_start:p) = k;

    phase(p+1:v_end)   = 2;   % releasing
    cyc_num(p+1:v_end) = k;
end

%% ── 6. Style Settings ────────────────────────────────────────
lw  = 1.5;
fs  = 12;
tfs = 13;

start_color = [1.0, 0.75, 0.45];
end_color   = [0.5, 0.15, 0.0];
grad = [linspace(start_color(1), end_color(1), num_cycles)', ...
        linspace(start_color(2), end_color(2), num_cycles)', ...
        linspace(start_color(3), end_color(3), num_cycles)'];

E_steps = (0.1 : 0.1 : max_elong)';
n_steps = length(E_steps);
e_tol   = 0.05;

%% ══════════════════════════════════════════════════════════════
%% OPTION 1 — True Conductivity (sigma_0) at Unstretched State
%%
%% At delta_L = 0, geometry is unchanged.
%% R_total = rho * G_total
%% sigma_0 = 1/rho = G_total / R_measured
%%
%% G_total unit: mm^-1 = 10^3 m^-1
%% R unit:       kOhm  = 10^3 Ohm
%% sigma_0 [S/m] = (10^3 m^-1) / (10^3 Ohm) = S/m  (check OK)
%% ══════════════════════════════════════════════════════════════

R_zero  = R(valley_idx);
sigma_0 = G_total ./ R_zero;   % S/m

fprintf('--- Option 1: True Conductivity ---\n');
fprintf('  Mean sigma_0 : %.6f S/m\n', mean(sigma_0));
fprintf('  Std  sigma_0 : %.6f S/m\n', std(sigma_0));
fprintf('  Min  sigma_0 : %.6f S/m\n', min(sigma_0));
fprintf('  Max  sigma_0 : %.6f S/m\n\n', max(sigma_0));

n_zeros = length(valley_idx);

figure('Name','Option 1 - True Conductivity','NumberTitle','off');
plot(1:n_zeros, sigma_0, 'o-', ...
    'Color', [0.2 0.4 0.8], 'LineWidth', lw, ...
    'MarkerSize', 6, 'MarkerFaceColor', [0.2 0.4 0.8]);
yline(mean(sigma_0), 'r--', 'LineWidth', 2.0, ...
    'Label', sprintf('Mean = %.6f S/m', mean(sigma_0)), ...
    'LabelHorizontalAlignment', 'left');
xlabel('Measurement Index  (1 = start,  N+1 = end of last cycle)', 'FontSize', fs);
ylabel('\sigma_0  (S/m)', 'FontSize', fs);
title('True Conductivity at Unstretched State - Hybrid Shape', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);

%% ══════════════════════════════════════════════════════════════
%% GAUGE FACTOR
%%
%% Strain: epsilon = delta_L / L0  (dimensionless)
%% GF = (delta_R / R_0) / epsilon
%%    = ((R - R_0) / R_0) / (delta_L / L0)
%%
%% R_0 = resistance at start of each cycle (at delta_L = 0)
%% Negative GF expected due to Negative Piezoresistive Effect
%% ══════════════════════════════════════════════════════════════

GF = NaN(length(E), 1);

for k = 1:num_cycles
    R0_k   = R(valley_idx(k));
    mask_k = cyc_num == k & E > tol_zero;

    eps_k      = E(mask_k) ./ L0;
    GF(mask_k) = ((R(mask_k) - R0_k) ./ R0_k) ./ eps_k;
end

avg_GF_s = NaN(n_steps, 1);
avg_GF_r = NaN(n_steps, 1);

for i = 1:n_steps
    mask_s      = abs(E - E_steps(i)) < e_tol & phase == 1 & ~isnan(GF);
    mask_r      = abs(E - E_steps(i)) < e_tol & phase == 2 & ~isnan(GF);
    avg_GF_s(i) = mean(GF(mask_s), 'omitnan');
    avg_GF_r(i) = mean(GF(mask_r), 'omitnan');
end

fprintf('--- Gauge Factor ---\n');
fprintf('  Mean GF (stretching) : %.4f\n',   mean(avg_GF_s, 'omitnan'));
fprintf('  Mean GF (releasing)  : %.4f\n\n', mean(avg_GF_r, 'omitnan'));

figure('Name','Gauge Factor - All Cycles','NumberTitle','off');
hold on;

for k = 1:num_cycles
    mask_s = cyc_num == k & phase == 1 & ~isnan(GF);
    mask_r = cyc_num == k & phase == 2 & ~isnan(GF);
    if any(mask_s)
        plot(E(mask_s), GF(mask_s), '-',  'Color', [grad(k,:), 0.30], 'LineWidth', 1.5);
    end
    if any(mask_r)
        plot(E(mask_r), GF(mask_r), '--', 'Color', [grad(k,:), 0.30], 'LineWidth', 1.5);
    end
end

h_s = plot(E_steps, avg_GF_s, 'b-',  'LineWidth', 2.5);
h_r = plot(E_steps, avg_GF_r, 'r--', 'LineWidth', 2.5);

colormap(grad);
cb = colorbar;
cb.Label.String = 'Cycle Number';
clim([1 num_cycles]);

legend([h_s, h_r], {'Avg Stretching (0 -> max)', ...
                    'Avg Releasing  (max -> 0)'}, 'Location', 'best');
xlabel('Elongation (mm)', 'FontSize', fs);
ylabel('Gauge Factor',    'FontSize', fs);
title('Gauge Factor vs Elongation - All Cycles (Hybrid Shape)', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;

%% ══════════════════════════════════════════════════════════════
%% OPTION 2 — Effective Conductivity (sigma_eff)
%%
%% During stretching with uniform strain epsilon = delta_L / L0:
%%   - Each segment length increases: Li -> Li*(1 + epsilon)
%%   - Each segment width decreases: Wi -> Wi/sqrt(1 + epsilon)
%%     (volume conservation: L*W*T = constant)
%%
%% Therefore each segment's L/A ratio scales as (1+epsilon)^(2):
%%   G_total_stretched = G_total * (1 + epsilon)^(2)
%%
%% sigma_eff = G_total_stretched / R
%%           = G_total * (1 + delta_L/L0)^(2) / R
%%
%% This applies to BOTH the chain section and the bar section equally
%% because we assume uniform strain across the whole sample.
%% ══════════════════════════════════════════════════════════════

eps_all   = E ./ L0;
G_str = G_total .* (1 + eps_all).^2;
sigma_eff = G_str ./ R;
sigma_eff(E <= tol_zero) = NaN;

avg_seff_s = NaN(n_steps, 1);
avg_seff_r = NaN(n_steps, 1);

for i = 1:n_steps
    mask_s        = abs(E - E_steps(i)) < e_tol & phase == 1 & ~isnan(sigma_eff);
    mask_r        = abs(E - E_steps(i)) < e_tol & phase == 2 & ~isnan(sigma_eff);
    avg_seff_s(i) = mean(sigma_eff(mask_s), 'omitnan');
    avg_seff_r(i) = mean(sigma_eff(mask_r), 'omitnan');
end

fprintf('--- Option 2: Effective Conductivity ---\n');
fprintf('  Mean sigma_eff (stretching) : %.6f S/m\n',   mean(avg_seff_s, 'omitnan'));
fprintf('  Mean sigma_eff (releasing)  : %.6f S/m\n\n', mean(avg_seff_r, 'omitnan'));

figure('Name','Option 2 - Effective Conductivity','NumberTitle','off');
hold on;

for k = 1:num_cycles
    mask_s = cyc_num == k & phase == 1 & ~isnan(sigma_eff);
    mask_r = cyc_num == k & phase == 2 & ~isnan(sigma_eff);
    if any(mask_s)
        plot(E(mask_s), sigma_eff(mask_s), '-',  'Color', [grad(k,:), 0.30], 'LineWidth', 1.5);
    end
    if any(mask_r)
        plot(E(mask_r), sigma_eff(mask_r), '--', 'Color', [grad(k,:), 0.30], 'LineWidth', 1.5);
    end
end

h_s2 = plot(E_steps, avg_seff_s, 'b-',  'LineWidth', 2.5);
h_r2 = plot(E_steps, avg_seff_r, 'r--', 'LineWidth', 2.5);

colormap(grad);
cb2 = colorbar;
cb2.Label.String = 'Cycle Number';
clim([1 num_cycles]);

legend([h_s2, h_r2], {'Avg Stretching (0 -> max)', ...
                      'Avg Releasing  (max -> 0)'}, 'Location', 'best');
xlabel('Elongation (mm)',      'FontSize', fs);
ylabel('\sigma_{eff}  (S/m)', 'FontSize', fs);
title('Effective Conductivity vs Elongation - All Cycles (Hybrid Shape)', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;
