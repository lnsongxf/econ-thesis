% add Kilian code to path
addpath('C:\Users\owner\Google Drive\docs\16sp\econ-thesis\src\outside\kilian');

% read data
data = csvread('data/clean/aggregate-series.csv', 4, 0);
data = transpose(data(:, 4:31)); % [ y_t, ..., y_{t-3} ]'
Y_mean = mean(data, 2);
data_bootstrap = transpose(data(1:7, :));

% settings
[nom, real] = set_params();

% horizon = 20 quarters
period = 0:20;

% read in VAR estimates
[A0, A1, Sigma] = read_var_ests();

% generate point estimate for Y_t starting from Y_0 = Y_mean
Y_t = zeros(28, 21);
Y_t(:, 1) = Y_mean;
for t = 2:21
    Y_t(:, t) = A0 + A1*Y_t(:, t-1);
end

% generate alternative timeline
Y_t_shock = Y_t + dY_t;


%% COMPUTE IMPULSE RESPONSE
for i = 1:4
    % compute IRFs and confidence intervals
    [dffr_t_CI, dffr_real_t_CI, dlog_I_t_CI, dlog_R_t_CI] = point(data_bootstrap, A0, Y_t, i);
    
    if i == 1
        % nominal FFR
        dffr_t_5 = dffr_t_CI(1, :);
        dffr_t_50 = dffr_t_CI(2, :);
        dffr_t_95 = dffr_t_CI(3, :);

        plot(period, dffr_t_50, period, dffr_t_5, '--k', period, dffr_t_95, '--k');
        title('Nominal FFR');
        xlabel('Quarter');
        ylabel('Impulse Response');
        print('figs/irf/nominal_ffr.png', '-dpng');

        % real FFR
        dffr_real_t_5 = dffr_real_t_CI(1, :);
        dffr_real_t_50 = dffr_real_t_CI(2, :);
        dffr_real_t_95 = dffr_real_t_CI(3, :);

        plot(period, dffr_real_t_50, period, dffr_real_t_5, '--k', period, dffr_real_t_95, '--k');
        title('Real FFR');
        xlabel('Quarter');
        ylabel('Impulse Response');
        print('figs/irf/real_ffr.png', '-dpng');
    end
    
    % nominal implied rate
    dlog_I_t_5 = dlog_I_t_CI(1, :);
    dlog_I_t_50 = dlog_I_t_CI(2, :);
    dlog_I_t_95 = dlog_I_t_CI(3, :);
    
    plot(period, dlog_I_t_50, period, dlog_I_t_5, '--k', period, dlog_I_t_95, '--k');
    title(['Implied Nominal Rate: \nu = ', num2str(nom(i).nu), ', \phi = ', num2str(nom(i).phi)]);
    xlabel('Quarter');
    ylabel('Impulse Response');
    print(['figs/irf/nominal_implied_', int2str(i), '.png'], '-dpng');
    
    % real implied rate
    dlog_R_t_5 = dlog_R_t_CI(1, :);
    dlog_R_t_50 = dlog_R_t_CI(2, :);
    dlog_R_t_95 = dlog_R_t_CI(3, :);
    
    plot(period, dlog_R_t_50, period, dlog_R_t_5, '--k', period, dlog_R_t_95, '--k');
    title(['Implied Real Rate: \nu = ', num2str(real(i).nu), ', \phi = ', num2str(real(i).phi)]);
    xlabel('Quarter');
    ylabel('Impulse Response');
    print(['figs/irf/real_implied_', int2str(i), '.png'], '-dpng');
end