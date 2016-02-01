function [] = impulse_response()

% settings
beta = 0.9926; % discount rate
alpha = 2; % coefficient of relative risk aversion
[nom, real] = set_params();

% initialize matrices
period = 0:20;
y_t = zeros(21, 7);
y_lower_t = zeros(21, 7);
y_upper_t = zeros(21, 7);

% read in impulse response tables
[y_t(:, 1), y_lower_t(:, 1), y_upper_t(:, 1)] = import_irf('data/ests/irf/log_consumption.txt');
[y_t(:, 2), y_lower_t(:, 2), y_upper_t(:, 2)] = import_irf('data/ests/irf/inflation.txt');
[y_t(:, 3), y_lower_t(:, 3), y_upper_t(:, 3)] = import_irf('data/ests/irf/scaled_leisure_pct.txt');
[y_t(:, 4), y_lower_t(:, 4), y_upper_t(:, 4)] = import_irf('data/ests/irf/log_rdi.txt');
[y_t(:, 5), y_lower_t(:, 5), y_upper_t(:, 5)] = import_irf('data/ests/irf/log_nonconsumption.txt');
[y_t(:, 6), y_lower_t(:, 6), y_upper_t(:, 6)] = import_irf('data/ests/irf/ffr.txt');
[y_t(:, 7), y_lower_t(:, 7), y_upper_t(:, 7)] = import_irf('data/ests/irf/cci.txt');

% generate lags
Y_t = transpose(lagmatrix(y_t, 0:3));
Y_t(isnan(Y_t)) = [0];

% get data series
c_t = Y_t(1, :); % log consumption
pi_t = Y_t(2, :); % net quarterly inflation
l_t = Y_t(3, :); % leisure
ffr_t = Y_t(6, :); % net quarterly nominal FFR
c_tm1 = Y_t(8, :);

% read in VAR estimates
[~, A1, ~] = read_var_ests();

% compute moments
Et_Y_tp1 = A1*Y_t; % E_t(Y_{t+1})
Et_Y_tp2 = A1^2*Y_t;

Et_c_tp1 = Et_Y_tp1(1, :); % E_t(c_{t+1})
Et_c_tp2 = Et_Y_tp2(1, :);
Et_pi_tp1 = Et_Y_tp1(2, :);
Et_l_tp1 = Et_Y_tp1(3, :);
Et_l_tp2 = Et_Y_tp2(3, :);

% plot real FFR impulse response
ffr_real_t = ffr_t - pi_t; % net quarterly real FFR
plot(period, ffr_real_t);
title('Real FFR');
xlabel('Quarter');
print('figs/irf/real_ffr.png', '-dpng');


%% IMPLIED NOMINAL RATES
for i = 1:4
    nu = nom(i).nu;
    phi = nom(i).phi;
    
    chi_1t = (nu*(1-alpha) - 1)*Et_c_tp1 - phi*nu*(1-alpha)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1 - Et_pi_tp1;
    chi_2t = nu*(1-alpha)*Et_c_tp2 - (phi*nu*(1-alpha) + 1)*Et_c_tp1 ...
        + (1-nu)*(1-alpha)*Et_l_tp2 - Et_pi_tp1;
    chi_3t = (nu*(1-alpha) - 1)*c_t - phi*nu*(1-alpha)*c_tm1 ...
        + (1-nu)*(1-alpha)*l_t;
    chi_4t = nu*(1-alpha)*Et_c_tp1 - (phi*nu*(1-alpha) + 1)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1;
    
    I_t_inv = (exp(chi_1t) - beta*phi*exp(chi_2t)) ./ (exp(chi_3t) - beta*phi*exp(chi_4t));
    i_t = -log(I_t_inv);
    
    plot(period, i_t);
    title(['Implied Nominal Rate: \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    xlabel('Quarter');
    file = ['figs/irf/nominal_implied_', int2str(i), '.png'];
    print(file, '-dpng');
end


%% IMPLIED REAL RATES
for i = 1:4
    nu = real(i).nu;
    phi = real(i).phi;
    
    chi_1t = (nu*(1-alpha) - 1)*Et_c_tp1 - phi*nu*(1-alpha)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1;
    chi_2t = nu*(1-alpha)*Et_c_tp2 - (phi*nu*(1-alpha) + 1)*Et_c_tp1 ...
        + (1-nu)*(1-alpha)*Et_l_tp2;
    chi_3t = (nu*(1-alpha) - 1)*c_t - phi*nu*(1-alpha)*c_tm1 ...
        + (1-nu)*(1-alpha)*l_t;
    chi_4t = nu*(1-alpha)*Et_c_tp1 - (phi*nu*(1-alpha) + 1)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1;
    
    I_t_inv = (exp(chi_1t) - beta*phi*exp(chi_2t)) ./ (exp(chi_3t) - beta*phi*exp(chi_4t));
    i_t = -log(I_t_inv);
    
    plot(period, i_t);
    title(['Implied Real Rate: \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    xlabel('Quarter');
    file = ['figs/irf/real_implied_', int2str(i), '.png'];
    print(file, '-dpng');
end

end

