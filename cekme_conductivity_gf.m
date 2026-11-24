%% ============================================================
%% TPU Stretch Test - Conductivity & Gauge Factor Analysis
%%
%% Option 1 : True conductivity at unstretched state
%% Option 2 : Effective conductivity vs elongation
%% GF       : Gauge Factor vs elongation
%% ============================================================

clear; clc; close all;
%% ── 1. Manual Inputs ─────────────────────────────────────────
fprintf('========================================\n');
fprintf('   TPU Stretch Test Analysis\n');
fprintf('========================================\n\n');
W0 = input('Enter initial width         W0 (mm): ');
T0 = input('Enter initial thickness     T0 (mm): ');
L0 = input('Enter initial gauge length  L0 (mm): ');
fprintf('\n');

%% ── 2. Load Data ─────────────────────────────────────────────
data = readtable('archive_2026_05_22_14_55_00.csv');
R = data.Resis_K;    % Resistance  (kΩ)
E = data.movem_mm;   % Elongation  (mm)

%% ── 3. Auto Detect Max Elongation & Cycle Count ──────────────
max_elong = max(E);
tol_peak  = max_elong * 0.02;   % 2% tolerance for peak detection
tol_zero  = 0.05;               % 0.05 mm tolerance for zero detection

% Valley indices: first point of each consecutive group near 0
is_valley  = E <= tol_zero;
valley_idx = find(is_valley & [true; ~is_valley(1:end-1)]);

% Peak indices: first point of each consecutive group near max
is_peak  = E >= max_elong - tol_peak;
peak_idx = find(is_peak & [true; ~is_peak(1:end-1)]);

% Number of complete cycles
num_cycles = min(length(valley_idx) - 1, length(peak_idx));
fprintf('----------------------------------------\n');
fprintf('Auto Detection Results:\n');
fprintf('  Max elongation  : %.2f mm\n',  max_elong);
fprintf('  Cycles detected : %d\n',       num_cycles);
fprintf('  Zero crossings  : %d\n',       length(valley_idx));
fprintf('----------------------------------------\n\n');

%% ── 4. Assign Cycle ID and Phase to Each Data Point ──────────
% phase:   1 = stretching,  2 = releasing,  0 = unassigned
phase   = zeros(length(E), 1);
cyc_num = zeros(length(E), 1);
for k = 1:num_cycles
    v_start = valley_idx(k);
    v_end   = valley_idx(k + 1);
    p       = peak_idx(k);
    phase(v_start:p)     = 1;   % stretching
    cyc_num(v_start:p)   = k;

    phase(p+1:v_end)     = 2;   % releasing
    cyc_num(p+1:v_end)   = k;
end

%% ── 5. Common Style Settings ─────────────────────────────────
lw  = 1.5;
fs  = 12;
tfs = 13;

% Gradient colors: light orange → dark brown  (same as your bend sensor code)
start_color = [1.0, 0.75, 0.45];
end_color   = [0.5, 0.15, 0.0];
grad = [linspace(start_color(1), end_color(1), num_cycles)', ...
        linspace(start_color(2), end_color(2), num_cycles)', ...
        linspace(start_color(3), end_color(3), num_cycles)'];

% Elongation bins for average curves
E_steps = (0.1 : 0.1 : max_elong)';
n_steps = length(E_steps);
e_tol   = 0.05;   % ±0.05 mm bin window

%% ══════════════════════════════════════════════════════════════
%% OPTION 1 — True Conductivity at Unstretched State
%%
%% Formula  : σ₀ [S/m] = L0[mm] / (R[kΩ] × W0[mm] × T0[mm])
%% Unit proof: mm / (kΩ × mm × mm)
%%           = 10⁻³m / (10³Ω × 10⁻⁶m²) = 1/(Ω·m) = S/m  ✓
%% ══════════════════════════════════════════════════════════════
R_zero  = R(valley_idx);
sigma_0 = L0 ./ (R_zero .* W0 .* T0);   % S/m
fprintf('--- Option 1: True Conductivity ---\n');
fprintf('  Mean σ₀ : %.6f S/m\n', mean(sigma_0));
fprintf('  Std  σ₀ : %.6f S/m\n', std(sigma_0));
fprintf('  Min  σ₀ : %.6f S/m\n', min(sigma_0));
fprintf('  Max  σ₀ : %.6f S/m\n\n', max(sigma_0));
n_zeros = length(valley_idx);   % = num_cycles + 1
figure('Name','Option 1 – True Conductivity at Unstretched State','NumberTitle','off');
plot(1:n_zeros, sigma_0, 'o-', ...
    'Color', [0.2 0.4 0.8], 'LineWidth', lw, ...
    'MarkerSize', 6, 'MarkerFaceColor', [0.2 0.4 0.8]);
yline(mean(sigma_0), 'r--', 'LineWidth', 2.0, ...
    'Label', sprintf('Mean = %.6f S/m', mean(sigma_0)), ...
    'LabelHorizontalAlignment', 'left');
xlabel('Measurement Index  (1 = start,  N+1 = end of last cycle)', 'FontSize', fs);
ylabel('\sigma_0  (S/m)',           'FontSize', fs);
title('True Conductivity at Unstretched State', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);

%% ══════════════════════════════════════════════════════════════
%% GAUGE FACTOR
%%
%% Formula : GF = (ΔR / R₀) / ε
%%           ΔR = R − R₀       (R₀ = resistance at START of each cycle)
%%           ε  = ΔL / L0      (dimensionless strain)
%% ══════════════════════════════════════════════════════════════
GF = NaN(length(E), 1);

for k = 1:num_cycles
    R0_k   = R(valley_idx(k));              % R₀ for this cycle (kΩ)
    mask_k = cyc_num == k & E > tol_zero;   % all non-zero points in cycle k
    eps_k       = E(mask_k) ./ L0;                          % strain
    GF(mask_k)  = ((R(mask_k) - R0_k) ./ R0_k) ./ eps_k;  % dimensionless
end

% Average GF per elongation step, stretch and release separately
avg_GF_s = NaN(n_steps, 1);
avg_GF_r = NaN(n_steps, 1);
for i = 1:n_steps
    mask_s       = abs(E - E_steps(i)) < e_tol & phase == 1 & ~isnan(GF);
    mask_r       = abs(E - E_steps(i)) < e_tol & phase == 2 & ~isnan(GF);
    avg_GF_s(i)  = mean(GF(mask_s), 'omitnan');
    avg_GF_r(i)  = mean(GF(mask_r), 'omitnan');
end
fprintf('--- Gauge Factor ---\n');
fprintf('  Mean GF (stretching) : %.4f\n',   mean(avg_GF_s, 'omitnan'));
fprintf('  Mean GF (releasing)  : %.4f\n\n', mean(avg_GF_r, 'omitnan'));
figure('Name','Gauge Factor – All Cycles','NumberTitle','off');
hold on;

% All individual cycle lines (semi-transparent, gradient color)
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

% Bold average curves on top
h_s = plot(E_steps, avg_GF_s, 'b-',  'LineWidth', 2.5);
h_r = plot(E_steps, avg_GF_r, 'r--', 'LineWidth', 2.5);
colormap(grad);
cb = colorbar;
cb.Label.String = 'Cycle Number';
clim([1 num_cycles]);
legend([h_s, h_r], {'Avg Stretching (0 \rightarrow max)', ...
                    'Avg Releasing  (max \rightarrow 0)'}, 'Location', 'best');
xlabel('Elongation (mm)',      'FontSize', fs);
ylabel('Gauge Factor',         'FontSize', fs);
title('Gauge Factor vs Elongation – All Cycles', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;

%% ══════════════════════════════════════════════════════════════
%% OPTION 2 — Effective Conductivity
%%
%% Formula  : σ_eff [S/m] = (L0+ΔL)² / (R[kΩ] × L0[mm] × W0[mm] × T0[mm])
%% Unit proof: mm² / (kΩ × mm³)
%%           = 10⁻⁶m² / (10³Ω × 10⁻⁹m³) = 1/(Ω·m) = S/m  ✓
%% (Assumes volume conservation: A = W0·T0·L0 / (L0+ΔL))
%% ══════════════════════════════════════════════════════════════
L_curr    = L0 + E;
sigma_eff = (L_curr .^ 2) ./ (R .* L0 .* W0 .* T0);   % S/m
sigma_eff(E <= tol_zero) = NaN;   % exclude zero-elongation points

% Average σ_eff per elongation step
avg_seff_s = NaN(n_steps, 1);
avg_seff_r = NaN(n_steps, 1);
for i = 1:n_steps
    mask_s        = abs(E - E_steps(i)) < e_tol & phase == 1 & ~isnan(sigma_eff);
    mask_r        = abs(E - E_steps(i)) < e_tol & phase == 2 & ~isnan(sigma_eff);
    avg_seff_s(i) = mean(sigma_eff(mask_s), 'omitnan');
    avg_seff_r(i) = mean(sigma_eff(mask_r), 'omitnan');
end
fprintf('--- Option 2: Effective Conductivity ---\n');
fprintf('  Mean σ_eff (stretching) : %.6f S/m\n',   mean(avg_seff_s, 'omitnan'));
fprintf('  Mean σ_eff (releasing)  : %.6f S/m\n\n', mean(avg_seff_r, 'omitnan'));
figure('Name','Option 2 – Effective Conductivity','NumberTitle','off');
hold on;

% All individual cycle lines
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

% Bold average curves on top
h_s2 = plot(E_steps, avg_seff_s, 'b-',  'LineWidth', 2.5);
h_r2 = plot(E_steps, avg_seff_r, 'r--', 'LineWidth', 2.5);
colormap(grad);
cb2 = colorbar;
cb2.Label.String = 'Cycle Number';
clim([1 num_cycles]);
legend([h_s2, h_r2], {'Avg Stretching (0 \rightarrow max)', ...
                      'Avg Releasing  (max \rightarrow 0)'}, 'Location', 'best');
xlabel('Elongation (mm)',           'FontSize', fs);
ylabel('\sigma_{eff}  (S/m)',       'FontSize', fs);
title('Effective Conductivity vs Elongation – All Cycles', 'FontSize', tfs);
grid on;
set(gca, 'FontSize', fs);
hold off;