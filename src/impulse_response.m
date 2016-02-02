function [] = impulse_response()

% settings
[nom, real] = set_params();

% initialize matrices
period = 0:20;
dy_t = zeros(21, 7);

% read in impulse response tables
[dy_t(:, 1), ~, ~] = import_irf('data/ests/irf/log_consumption.txt');
[dy_t(:, 2), ~, ~] = import_irf('data/ests/irf/inflation.txt');
[dy_t(:, 3), ~, ~] = import_irf('data/ests/irf/scaled_leisure_pct.txt');
[dy_t(:, 4), ~, ~] = import_irf('data/ests/irf/log_rdi.txt');
[dy_t(:, 5), ~, ~] = import_irf('data/ests/irf/log_nonconsumption.txt');
[dy_t(:, 6), ~, ~] = import_irf('data/ests/irf/ffr.txt');
[dy_t(:, 7), ~, ~] = import_irf('data/ests/irf/cci.txt');

% generate lags
dY_t = transpose(lagmatrix(dy_t, 0:3));
dY_t(isnan(dY_t)) = [0];
dy_t = transpose(dy_t);

% read in VAR estimates
[A0, A1, Sigma] = read_var_ests();

% generate point estimate for Y_t starting from Y_0 = Y_mean
Y_t = zeros(28, 21);
Y_t(:, 1) = csvread('data/ests/Y_mean.csv');
for t = 2:21
    Y_t(:, t) = A0 + A1*Y_t(:, t-1);
end

% generate alternative timeline
Y_t_shock = Y_t + dY_t;

% % plot real FFR impulse response
dpi_t = dY_t(2, :);
dffr_t = dY_t(6, :);
dffr_real_t = dffr_t - dpi_t; % net quarterly real FFR

plot(period, dffr_t);
title('Nominal FFR');
xlabel('Quarter');
ylabel('$FFR_t^{\rm{shock}} - FFR_t^{\rm{no shock}}$', 'Interpreter', 'latex');
print('figs/irf/nominal_ffr.png', '-dpng');

plot(period, dffr_real_t);
title('Real FFR');
xlabel('Quarter');
ylabel('$FFR_t^{\rm{shock}} - FFR_t^{\rm{no shock}}$', 'Interpreter', 'latex');
print('figs/irf/real_ffr.png', '-dpng');


%% IMPLIED NOMINAL RATES
for i = 1:4
    options = struct('i', i, 'real', 0, 'nu', nom(i).nu, 'phi', nom(i).phi, 'irf', 1);
    log_I_t = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    log_I_t_shock = compute_implied_rate(A0, A1, Sigma, Y_t_shock, options);
    dlog_I_t = log_I_t_shock - log_I_t;
    
    plot(period, dlog_I_t);
    title(['Implied Nominal Rate: \nu = ', num2str(nom(i).nu), ', \phi = ', num2str(nom(i).phi)]);
    xlabel('Quarter');
    ylabel('$\log(1 + i_t^{\rm{shock}}) - \log(1 + i_t^{\rm{no shock}})$', 'Interpreter', 'latex');
    file = ['figs/irf/nominal_implied_', int2str(i), '.png'];
    print(file, '-dpng');
end


%% IMPLIED REAL RATES
for i = 1:4
    options = struct('i', i, 'real', 1, 'nu', real(i).nu, 'phi', real(i).phi, 'irf', 1);
    log_R_t = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    log_R_t_shock = compute_implied_rate(A0, A1, Sigma, Y_t_shock, options);
    dlog_R_t = log_R_t_shock - log_R_t;
    
    plot(period, dlog_R_t);
    title(['Implied Real Rate: \nu = ', num2str(real(i).nu), ', \phi = ', num2str(real(i).phi)]);
    xlabel('Quarter');
    ylabel('$\log(1 + r_t^{\rm{shock}}) - \log(1 + r_t^{\rm{no shock}})$', 'Interpreter', 'latex');
    file = ['figs/irf/real_implied_', int2str(i), '.png'];
    print(file, '-dpng');
end

end

