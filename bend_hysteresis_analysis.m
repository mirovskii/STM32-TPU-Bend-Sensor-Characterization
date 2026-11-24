% ----------------Read the txt file----------------------------------------
fid = fopen('data2_90.txt', 'r');
data = [];

while ~feof(fid)
    line = fgetl(fid);
    if ischar(line)
        values = str2double(strsplit(strtrim(line)));
        if length(values) == 3 && ~any(isnan(values))
            data = [data; values];
        end
    end
end

fclose(fid);
disp(['Total lines read: ' num2str(size(data, 1))]);

% Extract columns
trial      = data(:, 1);
angle      = data(:, 2);
resistance = data(:, 3);

% ----------------Plot Trials 50-700 (GRADIENT VERSION)-------------------
all_bend_resistance    = zeros(651, 91);
all_release_resistance = zeros(651, 91);

% First pass: count valid trials
num_trials = 0;
for t = 50:700
    mask = trial == t;
    trial_data = data(mask, :);
    if size(trial_data, 1) >= 182
        num_trials = num_trials + 1;
    end
end

% --- Create a custom light-to-dark gradient ---
% This creates an RGB matrix transitioning from Light Blue to Dark Blue.
start_color = [1.0, 0.75, 0.45]; % Light Blue (Early trials)
end_color   = [0.5, 0.15, 0.0]; % Dark Blue  (Late trials)

gradient_colors = [linspace(start_color(1), end_color(1), num_trials)', ...
                   linspace(start_color(2), end_color(2), num_trials)', ...
                   linspace(start_color(3), end_color(3), num_trials)'];

% Second pass: plot with gradient color
figure;
hold on;
trial_count = 0;
for t = 50:700
    mask = trial == t;
    trial_data = data(mask, :);
    if size(trial_data, 1) >= 182
        trial_count = trial_count + 1;
        
        bend_resistance_t    = trial_data(1:91, 3);
        release_resistance_t = trial_data(92:182, 3);
        
        all_bend_resistance(t-49, :)    = bend_resistance_t;
        all_release_resistance(t-49, :) = release_resistance_t;
        
        % --- Apply the pre-calculated gradient colors ---
        plot(0:90,    bend_resistance_t,    '-', 'Color', [gradient_colors(trial_count,:), 0.3], 'LineWidth', 0.5);
        plot(90:-1:0, release_resistance_t, '-', 'Color', [gradient_colors(trial_count,:), 0.3], 'LineWidth', 0.5);
    else
        disp(['Warning: Trial ' num2str(t) ' has ' num2str(size(trial_data,1)) ' rows, skipping']);
    end
end

xlabel('Bend Angle (degrees)');
ylabel('Resistance (\Omega)');
title('TPU Sensor Hysteresis for 0-90 degree - 700 Trials ');
grid on;

% --- Update the colorbar to match our custom gradient ---
colormap(gradient_colors);
cb = colorbar;
cb.Label.String = 'Trial Number';
clim([50 700]);
% ----------------Plot Average of Trials 50-700----------------------------
all_bend_resistance(all_bend_resistance == 0)       = NaN;
all_release_resistance(all_release_resistance == 0) = NaN;

avg_bend    = mean(all_bend_resistance, 1, 'omitnan');
avg_release = mean(all_release_resistance, 1, 'omitnan');

figure;
plot(0:90,    avg_bend,    'b-', 'LineWidth', 0.8);
hold on;
plot(90:-1:0, avg_release, 'r-', 'LineWidth', 0.8);
xlabel('Bend Angle (degrees)');
ylabel('Resistance (Ω)');
title('TPU Sensor Hysteresis for 0-90 degree - Average of 700 Trials ');
legend('Bending (0→90)', 'Releasing (90→0)');
grid on;

% ----------------Hysteresis Coefficient Calculation----------------------
avg_release_aligned = fliplr(avg_release);
diff_per_angle = abs(avg_bend - avg_release_aligned);

R_max = avg_bend(91);
R_min = avg_bend(1);

H_max = (max(diff_per_angle) / abs(R_max - R_min)) * 100;

fprintf('\n--- Hysteresis Coefficient Results ---\n');
fprintf('R_min  (0°)  : %.1f Ω\n', R_min);
fprintf('R_max  (90°) : %.1f Ω\n', R_max);
fprintf('Max |ΔR|     : %.1f Ω  at angle %d°\n', ...
        max(diff_per_angle), find(diff_per_angle == max(diff_per_angle)) - 1);
fprintf('H_max        : %.2f %%\n', H_max);

% ----------------Per-Trial Hysteresis Coefficients-----------------------
H_per_trial = zeros(651, 1);

for k = 1:651
    bend_k    = all_bend_resistance(k, :);
    release_k = fliplr(all_release_resistance(k, :));

    if any(isnan(bend_k)) || any(isnan(release_k))
        H_per_trial(k) = NaN;
        continue;
    end

    r_max_k = bend_k(91);
    r_min_k = bend_k(1);

    if (r_max_k - r_min_k) == 0
        H_per_trial(k) = NaN;
        continue;
    end

    H_per_trial(k) = (max(abs(bend_k - release_k)) / abs(r_max_k - r_min_k)) * 100;
end

fprintf('Mean H per trial : %.2f %%\n', mean(H_per_trial, 'omitnan'));
fprintf('Std  H per trial : %.2f %%\n', std(H_per_trial,  'omitnan'));

% ----------------Plot H_max per trial------------------------------------
figure;
plot(50:700, H_per_trial, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);
yline(mean(H_per_trial,'omitnan'), 'r--', 'LineWidth', 2.0, ...
      'Label', sprintf('Mean = %.2f%%', mean(H_per_trial,'omitnan')));
xlabel('Trial Number');
ylabel('H_{max} (%)');
title('Hysteresis Coefficient per Trial for 700 Trials');
grid on;

% ----------------Plot diff per angle (average curve)---------------------
figure;
plot(0:90, diff_per_angle, 'm-', 'LineWidth', 1.2);
xlabel('Bend Angle (degrees)');
ylabel('|R_{bend} - R_{release}| (Ω)');
title('Average Hysteresis Gap vs Angle for 700 Trials');
grid on;