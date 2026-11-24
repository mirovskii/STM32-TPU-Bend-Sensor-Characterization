%% ============================================================
%% TPU Stretch Test - Segmented Shape Conductivity & Gauge Factor
%%
%% Shape: N_sq squares connected by N_br thin bridges (in series)
%%
%% Option 1 : True conductivity at unstretched state (sigma_0)
%% Option 2 : Effective conductivity vs elongation (sigma_eff)
%% GF       : Gauge Factor vs elongation
%% ============================================================

clear; clc; close all;

%% ── 1. Manual Inputs ─────────────────────────────────────────
fprintf('========================================\n');
fprintf('   TPU Segmented Shape Stretch Analysis\n');
fprintf('========================================\n\n');

fprintf('--- Square Segment Dimensions ---\n');
L_sq = input('Square side length    L_sq (mm): ');
W_sq = input('Square side width     W_sq (mm): ');  % same as L_sq if square
N_sq = input('Number of squares     N_sq     : ');

fprintf('\n--- Bridge Segment Dimensions ---\n');
L_br = input('Bridge length         L_br (mm): ');
W_br = input('Bridge width          W_br (mm): ');
N_br = input('Number of bridges     N_br     : ');

fprintf('\n--- Common Dimension ---\n');
T0   = input('Sample thickness      T0   (mm): ');

fprintf('\n--- Initial Gauge Length (between contact points) ---\n');
L0   = input('Initial gauge length  L0   (mm): ');

fprintf('\n');

%% ── 2. Geometric Factor Calculation ─────────────────────────
% Each segment group contributes its own geometric factor (1/m)
% A_sq = W_sq * T0,  A_br = W_br * T0

A_sq = W_sq * T0;   % cross-section of one square (mm^2)
A_br = W_br * T0;   % cross-section of one bridge (mm^2)

% Geometric factor for each segment type
geo_sq = N_sq * (L_sq / A_sq);   % mm / mm^2 = mm^-1
geo_br = N_br * (L_br / A_br);

geo_total = geo_sq + geo_br;     % total geometric factor (mm^-1)

% Total physical path length (mm)
L_path = N_sq * L_sq + N_br * L_br;

fprintf('----------------------------------------\n');
fprintf('Geometry Summary:\n');
fprintf('  A_sq          : %.4f mm^2\n', A_sq);
fprintf('  A_br          : %.4f mm^2\n', A_br);
fprintf('  Geo factor sq : %.4f mm^-1\n', geo_sq);
fprintf('  Geo factor br : %.4f mm^-1\n', geo_br);
fprintf('  Geo total     : %.4f mm^-1\n', geo_total);
fprintf('  Total path L  : %.2f  mm\n',   L_path);
fprintf('----------------------------------------\n\n');

% ── Segment contribution ratio ────────────────────────────────
pct_sq = (geo_sq / geo_total) * 100;
pct_br = (geo_br / geo_total) * 100;
fprintf('Resistance share:\n');
fprintf('  Squares  : %.1f %%\n', pct_sq);
fprintf('  Bridges  : %.1f %%\n', pct_br);
fprintf('----------------------------------------\n\n');

%% ── 3. Load Data ─────────────────────────────────────────────
data = readtable('archive_2026_05_22_14_46_17.csv');

R = data.Resis_K;    % Resistance  (kOhm)
E = data.movem_mm;   % Elongation  (mm)

%% ── 4. Auto Detect Max Elongation & Cycle Count ──────────────
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

%% ── 6. Common Style Settings ─────────────────────────────────
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
%% For segmented shape:
%%   sigma_0 is derived from the TOTAL geometric factor of the shape.
%%   R_total = rho * geo_total  =>  rho = R / geo_total
%%   sigma_0 = 1 / rho = geo_total / R
%%
%% geo_total has unit mm^-1 = 10^3 m^-1
%% R has unit kOhm = 10^3 Ohm
%%
%% sigma_0 [S/m] = geo_total[mm^-1] / R[kOhm]
%%               = (10^3 m^-1) / (10^3 Ohm) = 1/(Ohm*m) = S/m  (check OK)
%%
%% This is equivalent to the straight bar formula but uses the
%% total geometric factor instead of a single L/A ratio.
%% ══════════════════════════════════════════════════════════════

R_zero  = R(valley_idx);
sigma_0 = geo_total ./ R_zero;   % S/m  (geo_total in mm^-1, R in kOhm)

fprintf('--- Option 1: True Conductivity ---\n');
fprintf('  Mean sigma_0 : %.6f S/m\n', mean(sigma_0));
fprintf('  Std  sigma_0 : %.6f S/m\n', std(sigma_0));
fprintf('  Min  sigma_0 : %.6f S/m\n', min(sigma_0));
fprintf('  Max  sigma_0 : %.6f S/m\n\n', max(sigma_0));

n_zeros = length(valley_idx);

figure('Name','Option 1 - True Conductivity at Unstretched State','NumberTitle','off');
plot(1:n_zeros, sigma_0, 'o-', ...
    'Color', [0.2 0.4 0.8], 'LineWidth', lw, ...
    'MarkerSize', 6, 'MarkerFaceColor', [0.2 0.4 0.8]);
yline(mean(sigma_0), 'r--', 'LineWidth', 2.0, ...
    'Label', sprintf('Mean = %.6f S/m', mean(sigma_0)), ...
    'LabelHorizontalAlignment', 'left');
xlabel('Measurement Index  (1 = start,  N+1 = end of last cycle)', 'FontSize', fs);
ylabel('\sigma_0  (S/m)', 'FontSize', fs);
title('True Conductivity at Unstretched State - Segmented Shape', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);

%% ══════════════════════════════════════════════════════════════
%% GAUGE FACTOR
%%
%% During stretching, the gauge length L0 increases by delta_L.
%% We assume uniform strain distribution across ALL segments.
%% This means each segment stretches proportionally to its own length.
%%
%% Strain:  epsilon = delta_L / L0  (dimensionless)
%%
%% GF = (delta_R / R_0) / epsilon
%%    = ((R - R_0) / R_0) / (delta_L / L0)
%%
%% Here R_0 = resistance at the START of each cycle (at delta_L = 0)
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
title('Gauge Factor vs Elongation - All Cycles (Segmented Shape)', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;

%% ══════════════════════════════════════════════════════════════
%% OPTION 2 — Effective Conductivity (sigma_eff)
%%
%% During stretching, each segment gets longer and narrower.
%% We assume uniform strain (each segment stretches proportionally).
%%
%% For a single straight bar: sigma_eff = (L0 + dL)^2 / (R * L0 * W0 * T0)
%%
%% For our segmented shape, we replace L0*W0*T0 with the equivalent
%% volume term derived from the geometric factor:
%%   V_eff = L0 / geo_total  (mm^3, effective "equivalent volume")
%%
%% Then:
%%   sigma_eff = (L0 + dL)^2 / (R * L_path * (W0_eff * T0))
%%
%% Simplest correct approach: use the geometric factor directly.
%% At elongation dL, strain eps = dL/L0.
%% Each length Li -> Li*(1+eps), each width Wi -> Wi/sqrt(1+eps) [volume conserved].
%%
%% New geo_total_stretched = geo_total * (1 + eps)^(2)
%%
%% sigma_eff = geo_total_stretched / R
%%           = geo_total * (1 + E/L0)^(2) / R
%%
%% Unit: same as Option 1 => S/m
%% ══════════════════════════════════════════════════════════════

eps_all   = E ./ L0;                                        % strain at each point
geo_str   = geo_total .* (1 + eps_all).^2;                  % stretched geometric factor
sigma_eff = geo_str ./ R;                                   % S/m
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
title('Effective Conductivity vs Elongation - All Cycles (Segmented Shape)', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;
