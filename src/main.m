%% READ DATA
data = csvread('data/clean/aggregate-series.csv', 4, 0);
date = transpose(datetime(data(:, 1:3)));
Y_t = transpose(data(:, 4:31)); % [ y_t, ..., y_{t-3} ]'
[kp, T] = size(Y_t); % number of variables plus lags, number of periods
p = 4; % number of lags
k = kp/p; % number of covariates

c_t = Y_t(1, :); % log consumption
pi_t = Y_t(2, :); % quarterly net inflation
l_t = Y_t(3, :); % leisure
ffr_t = Y_t(6, :); % quarterly net nominal FFR
c_tm1 = Y_t(8, :);

FFR_t = exp(ffr_t); % quarterly gross nominal FFR
FFR_t_ann = FFR_t .^ 4; % annualized gross nominal FFR
FFR_t_scaled = log(FFR_t_ann) .* 100;

ffr_real_t = ffr_t - pi_t; % quarterly net real FFR
FFR_real_t = exp(ffr_real_t); % quarterly gross real FFR
FFR_real_t_ann = FFR_real_t .^4; % annualized gross real FFR
FFR_real_t_scaled = log(FFR_real_t_ann) .* 100;

% read in VAR estimates
A0 = csvread('data/ests/var/A0.csv', 0, 0, [0 0 27 0]);
A1 = csvread('data/ests/var/A1.csv', 0, 0, [0 0 27 27]);
Sigma = csvread('data/ests/var/Sigma.csv', 0, 0, [0 0 27 27]);
assert(all(size(A0) == [kp, 1]));
assert(all(size(A1) == [kp, kp]));
assert(all(size(Sigma) == [kp, kp]));

% clean up values that should be zero
A0(abs(A0) < 1e-9) = [0];
A1(abs(A1) < 1e-9) = [0];
Sigma(abs(Sigma) < 1e-9) = [0];

%% COMPUTE CONDITIONAL MOMENTS
[ Et_c_tp1, Et_c_tp2, Et_pi_tp1, Et_l_tp1, Et_l_tp2, Vt_c_tp1, ...
    Vt_c_tp2, Vt_pi_tp1, Vt_l_tp1, Ct_c_pi_tp1, Ct_c_l_tp1, ...
    Ct_pi_l_tp1, Ct_c_l_tp2, Ct_c_tp1_tp2, Ct_c_tp1_l_tp2, ...
    Ct_pi_tp1_c_tp2, Ct_pi_tp1_l_tp2 ] = ...
    compute_moments(A0, A1, Sigma, Y_t);

%% SET PARAMETERS
beta = 0.9926; % discount rate
alpha = 2; % coefficient of relative risk aversion

[nom, real] = get_params();

% Collard & Dellas sample: 1960:Q1 to 2006:Q4
collard = 1;
if collard == 1
    range = 1:188;
else
    range = 1:T;
end

%% NOMINAL RATES
for i = 1:4
    nu = nom(i).nu;
    phi = nom(i).phi;
    ymin = nom(i).ymin;
    ymax = nom(i).ymax;
    
        chi_1t = (nu*(1-alpha) - 1)*Et_c_tp1 - phi*nu*(1-alpha)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1 - Et_pi_tp1 ...
        + 1/2*(nu*(1-alpha) - 1)^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 + 1/2*Vt_pi_tp1 ...
        - (1-nu)*(1-alpha)*Ct_pi_l_tp1 ...
        + (nu*(1-alpha) - 1)*(1-nu)*(1-alpha)*Ct_c_l_tp1 ...
        - (nu*(1-alpha) - 1)*Ct_c_pi_tp1;
    
    chi_2t = nu*(1-alpha)*Et_c_tp2 - (phi*nu*(1-alpha) + 1)*Et_c_tp1 ...
        + (1-nu)*(1-alpha)*Et_l_tp2 - Et_pi_tp1 ...
        + 1/2*(nu*(1-alpha))^2*Vt_c_tp2 ...
        + 1/2*(phi*nu*(1-alpha) + 1)^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 + 1/2*Vt_pi_tp1 ...
        - nu*(1-alpha)*Ct_pi_tp1_c_tp2 ...
        + (phi*nu*(1-alpha) + 1)*Ct_c_pi_tp1 ...
        - (1-nu)*(1-alpha)*Ct_pi_tp1_l_tp2 ...
        - nu*(1-alpha)*(phi*nu*(1-alpha) + 1)*Ct_c_tp1_tp2 ...
        + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp2 ...
        - (phi*nu*(1-alpha) + 1)*(1-nu)*(1-alpha)*Ct_c_tp1_l_tp2;
    
    chi_3t = (nu*(1-alpha) - 1)*c_t - phi*nu*(1-alpha)*c_tm1 ...
        + (1-nu)*(1-alpha)*l_t;
    
    chi_4t = nu*(1-alpha)*Et_c_tp1 - (phi*nu*(1-alpha) + 1)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1 + 1/2*(nu*(1-alpha))^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 ...
        + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp1;
    
    I_t_inv = beta * (exp(chi_1t) - beta*phi*exp(chi_2t)) ./ (exp(chi_3t) - beta*phi*exp(chi_4t));
    I_t = 1 ./ I_t_inv; % quarterly gross nominal rate
    I_t_ann = I_t .^ 4; % annualized gross nominal rate
    I_t_scaled = log(I_t_ann) .* 100;

    plot(date(range), I_t_scaled(range), date(range), FFR_t_scaled(range));
    title('Annualized Nominal Interest Rate');
    legend('Implied', 'FFR');
    xlim([datenum(1960, 1, 1) datenum(2006, 10, 1)]);
    ylim([ymin ymax])
    file = strcat('figs/crra-nominal_', int2str(i), '.png');
    print(file, '-dpng');
    
    nom(i).mean = mean(I_t_scaled(range));
    nom(i).std = std(I_t_scaled(range));
    nom(i).min = min(I_t_scaled(range));
    nom(i).max = max(I_t_scaled(range));
    corr_matrix = corrcoef(I_t_scaled(range), FFR_t_scaled(range));
    nom(i).corr = corr_matrix(1, 2);
    
    spread_t = I_t_scaled - FFR_t_scaled;
    spread_lags_t = transpose(lagmatrix(spread_t, 1:4));
    FFR_spread_lags_t = [FFR_t_scaled; spread_lags_t];
    model = fitlm(transpose(FFR_spread_lags_t(:, range)), spread_t(range));
    nom(i).coef = model.Coefficients.Estimate(2); % FFR coefficient
    nom(i).se = model.Coefficients.SE(2); % FFR standard error
end

%% REAL RATES
for i = 1:4
    nu = real(i).nu;
    phi = real(i).phi;
    ymin = real(i).ymin;
    ymax = real(i).ymax;
    
    chi_real_1t = (nu*(1-alpha) - 1)*Et_c_tp1 - phi*nu*(1-alpha)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1 + 1/2*(nu*(1-alpha) - 1)^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 ...
        + (nu*(1-alpha) - 1)*(1-nu)*(1-alpha)*Ct_c_l_tp1;
    
    chi_real_2t = nu*(1-alpha)*Et_c_tp2 - (phi*nu*(1-alpha) + 1)*Et_c_tp1 ...
        + (1-nu)*(1-alpha)*Et_l_tp2 + 1/2*(nu*(1-alpha))^2*Vt_c_tp2 ...
        + 1/2*(phi*nu*(1-alpha) + 1)^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 ...
        - nu*(1-alpha)*(phi*nu*(1-alpha) + 1)*Ct_c_tp1_tp2 ...
        + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp2 ...
        - (phi*nu*(1-alpha) + 1)*(1-nu)*(1-alpha)*Ct_c_tp1_l_tp2;
    
    chi_real_3t = (nu*(1-alpha) - 1)*c_t - phi*nu*(1-alpha)*c_tm1 ...
        + (1-nu)*(1-alpha)*l_t;
    
    chi_real_4t = nu*(1-alpha)*Et_c_tp1 - (phi*nu*(1-alpha) + 1)*c_t ...
        + (1-nu)*(1-alpha)*Et_l_tp1 + 1/2*(nu*(1-alpha))^2*Vt_c_tp1 ...
        + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 ...
        + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp1;
    
    R_t_inv = beta * (exp(chi_real_1t) - beta*phi*exp(chi_real_2t)) ./ (exp(chi_real_3t) - beta*phi*exp(chi_real_4t));
    R_t = 1 ./ R_t_inv; % quarterly gross real rate
    R_t_ann = R_t .^ 4; % annualized gross real rate
    R_t_scaled = log(R_t_ann) .* 100;

    plot(date(range), R_t_scaled(range), date(range), FFR_real_t_scaled(range));
    title('Annualized Real Interest Rate');
    legend('Implied', 'FFR');
    xlim([datenum(1960, 1, 1) datenum(2006, 10, 1)]);
    ylim([ymin ymax])
    file = strcat('figs/crra-real_', int2str(i), '.png');
    print(file, '-dpng');
    
    real(i).mean = mean(R_t_scaled(range));
    real(i).std = std(R_t_scaled(range));
    real(i).min = min(R_t_scaled(range));
    real(i).max = max(R_t_scaled(range));
    corr_matrix = corrcoef(R_t_scaled(range), FFR_real_t_scaled(range));
    real(i).corr = corr_matrix(1, 2);
    
    spread_t = R_t_scaled - FFR_real_t_scaled;
    spread_lags_t = transpose(lagmatrix(spread_t, 1:4));
    FFR_spread_lags_t = [FFR_t_scaled; spread_lags_t];
    model = fitlm(transpose(FFR_spread_lags_t(:, range)), spread_t(range));
    real(i).coef = model.Coefficients.Estimate(2); % FFR coefficient
    real(i).se = model.Coefficients.SE(2); % FFR standard error
end

%% WRITE RESULTS TO FILE
writetable(struct2table(nom), 'data/ests/implied_rates/nominal.csv');
writetable(struct2table(real), 'data/ests/implied_rates/real.csv');