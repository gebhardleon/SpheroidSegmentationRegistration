clear
%% load PIV data

addpath('/Users/leongebhard/Desktop/X/PRL/SpheroidSegmentationRegistration') % add path to folder of the PIV_analysis file
PathsFilePath = '/Users/leongebhard/Desktop/X/PRL/Relaxation/PIV/2024_02_09_Chip1/Chip1.mat' ;
output_path = '/Users/leongebhard/Desktop/X/PRL/Relaxation/figures/2024_02_09_Chip1/';

segment_length = 10;
frame_selection = []; % for example 1:200
save_heatmaps = 0;
radius_spheroid = 35;
sampling_freq = 0.05;
cbar_limits = [];%


function_storage = PIV_analysis;
[u,v, uv] = function_storage.load_pivs(PathsFilePath ) ;

if isempty(frame_selection) == 0 
    u = u(frame_selection);
    v = v(frame_selection);
    uv = uv(frame_selection);
end
t_ges = sampling_freq * length(u); %total time analysed in seconds



vel_x={};
vel_y={};
vel_abs = {};
labels = {};
avgs = {};
vel_profile = {};
segments = {};

for i =1:length(u) - segment_length
    segments{end+1} = [i i + segment_length];

end



for i=1:length(segments)
    % distribute the velocity information into the designated segments
    vel_x{end+1} = u(segments{i}(1):segments{i}(end));
    vel_y{end+1} = v(segments{i}(1):segments{i}(end));
    vel_abs{end+1} = uv(segments{i}(1):segments{i}(end));
    % in
    labels{end+1} = ['Time segment ' int2str(i)];
    avgs{end+1} = function_storage.get_heatmap(vel_abs{i}, labels{i}, cbar_limits, output_path, save_heatmaps);
    vel_profile{end+1} = function_storage.get_velocity_curve(avgs{i});


end




%% plot velocity profiles
figure
hold on
for i =1:length(vel_profile)
    %plot(log(vel_profile{i}))
    plot(vel_profile{i} ) %'Color',colors{i}, 'LineWidth',0.1

end
ylabel('Average velocity in m/s')
xlabel('distance to center in pixel')
legend(labels)
%ylim([0.4 * 10^-8 2 * 10^-8])
xlim([0 radius_spheroid])
% Choose or customize a colormap with a smooth transition
custom_colormap = parula(length(vel_profile)); % Example using Parula colormap

% Set the colormap for the current axes
colormap(custom_colormap);

% Set the color order of the axes to match the colormap
colorOrder = colormap;
set(gca, 'ColorOrder', colorOrder);
% Add color bar
c = colorbar;
c.Label.String = 'Time after relaxation'; % You can adjust the label as needed

hold off


%% peak vel
figure
[max_val, maxid] = max(vel_profile{1});
peak_vel = [];
time = [];
for i = 1:length(vel_profile)
    peak_vel = [peak_vel vel_profile{i}(maxid)*10^8];
    time = [time t_ges * i / length(vel_profile)];
end

% Define the exponential function to fit
exponential_fun = @(coeff, x) coeff(1) * exp(coeff(2) * x) +  coeff(3) * exp(coeff(4) * x) +coeff(5);
single_exp = @(coeff, x) coeff(1) * exp(coeff(2) * x)  +coeff(3);


% Initial guess for coefficients
initial_guess = [max(peak_vel), -0.01, max(peak_vel), -0.01, min(peak_vel)]; % Initial guess for coefficients


% Perform the fitting
coefficients = lsqcurvefit(exponential_fun, initial_guess, time, peak_vel);

% Plot the data
semilogy(time, peak_vel, 'o', 'DisplayName', 'Data');
hold on;

% Plot the fitted curve
fitted_curve = exponential_fun(coefficients, time);
fit_1 = single_exp(coefficients([1 2 5]), time);
fit_2 = single_exp(coefficients([3 4 5]), time);
semilogy(time, fitted_curve, 'r', 'DisplayName', 'Exponential Fit', 'LineWidth',2);
semilogy(time, fit_1,  '--', 'DisplayName', 'Contribution first exp','LineWidth',2);
semilogy(time, fit_2,  '-.', 'DisplayName', 'Contribution second exp','LineWidth',2);
title(['v(t) / [m/s] = ' num2str(coefficients(1)) ' exp(t/' num2str(coefficients(2)^-1) 's) + ' num2str(coefficients(3)) ' exp(t/' num2str(coefficients(4)^-1) 's) + ' num2str(coefficients(5)) ]);

xlabel('Time / s')
ylabel('Average peak velocity / 10^{-8} m/s')
legend('show');
hold off;


%% average velocity fit
figure
avg_vel = [];
std_vel = [];
for i = 1:length(vel_profile)
    avg_vel = [avg_vel mean(vel_profile{i}(1:radius_spheroid))*10^8];
    std_vel = [std_vel std(vel_profile{i}(1:radius_spheroid))*10^8];
end

% Initial guess for coefficients
initial_guess = [max(avg_vel), -0.01, max(avg_vel), -0.01, min(avg_vel)]; % Initial guess for coefficients


% Perform the fitting
coefficients = lsqcurvefit(exponential_fun, initial_guess, time, avg_vel);
% Plot the data with error bars
%errorbar(time, avg_vel, std_vel, 'o', 'DisplayName', 'Data');
scatter(time, avg_vel, 'DisplayName' ,  'Avg Velocity')
hold on;

% Plot the fitted curve
fitted_curve = exponential_fun(coefficients, time);
fit_1 = single_exp(coefficients([1 2 5]), time);
fit_2 = single_exp(coefficients([3 4 5]), time);
plot(time, fitted_curve, 'r', 'DisplayName', 'Exponential Fit', 'LineWidth',2);
plot(time, fit_1,  '--', 'DisplayName', 'Contribution first exp+C','LineWidth',2);
plot(time, fit_2,  '-.', 'DisplayName', 'Contribution second exp+C','LineWidth',2);
title(['v(t) / [m/s] = ' num2str(coefficients(1)) ' exp(t/' num2str(coefficients(2)^-1) 's) + ' num2str(coefficients(3)) ' exp(t/' num2str(coefficients(4)^-1) 's) + ' num2str(coefficients(5)) ]);

xlabel('Time / s')
ylabel('Average intra-spheroid velocity / 10^{-8} m/s')
legend('show');
hold off;


%% plot oscilating expontential

%constant_oscil_fun = @(coeff, x) coeff(1) * exp(coeff(2) * x) +  coeff(3) * exp(coeff(4) * x) +sin(coeff(6)*x+coeff(7)) * coeff(5);
exp_oscil_fun = @(coeff, x) coeff(1) * exp(coeff(2) * x) + coeff(3) * exp(coeff(4) * x)  + coeff(5).* sin(coeff(6) * x + coeff(7));
initial_guess_osc = [max(avg_vel), -1, max(avg_vel), -1, min(avg_vel),pi , 0]; % Initial guess for coefficients
%coefficients_osc_const = lsqcurvefit(exponential_fun, initial_guess_osc, time, avg_vel);
coefficients_osc = lsqcurvefit(exp_oscil_fun, initial_guess_osc, time, avg_vel);


figure

scatter(time, avg_vel, 'DisplayName' ,  'Avg Velocity')
hold on;
% Plot the fitted curve
fitted_osc_exp_curve = exp_oscil_fun(coefficients_osc, time);
%fit_1 = single_exp(coefficients([1 2 5]), time);
%fit_2 = single_exp(coefficients([3 4 5]), time);
plot(time, fitted_osc_exp_curve, 'r', 'DisplayName', 'Exponential Fit', 'LineWidth',2);
%plot(time, fit_1,  '--', 'DisplayName', 'Contribution first exp+C','LineWidth',2);
%plot(time, fit_2,  '-.', 'DisplayName', 'Contribution second exp+C','LineWidth',2);
title(['v(t) / [m/s] = ' num2str(coefficients_osc(1)) ' exp(t/' num2str(coefficients_osc(2)^-1) 's) + ' num2str(coefficients_osc(3)) ' exp(t/' num2str(coefficients_osc(4)^-1) 's) + ' num2str(coefficients_osc(5)) ]);

xlabel('Time / s')
ylabel('Average intra-spheroid velocity / 10^{-8} m/s')
legend('show');
hold off;
