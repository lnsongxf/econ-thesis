%% READ DATA
data = csvread('data/clean/aggregate-series.csv', 4, 0);
date = transpose(datetime(data(:, 1:3)));
Y_t = transpose(data(:, 4:31)); % [ y_t, ..., y_{t-3} ]'
[kp, T] = size(Y_t); % number of variables plus lags, number of periods
p = 4; % number of lags
k = kp/p; % number of covariates

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

% compute FFR
FFR_t = exp(ffr_t); % quarterly gross nominal FFR
FFR_t_ann = FFR_t .^ 4; % annualized gross nominal FFR
FFR_t_scaled = log(FFR_t_ann) .* 100;

ffr_real_t = ffr_t - pi_t; % quarterly net real FFR
FFR_real_t = exp(ffr_real_t); % quarterly gross real FFR
FFR_real_t_ann = FFR_real_t .^4; % annualized gross real FFR
FFR_real_t_scaled = log(FFR_real_t_ann) .* 100;


%% SET PARAMETERS
[nom, real] = set_params();

% Collard & Dellas sample: 1960:Q1 to 2006:Q4
collard = 1;
if collard == 1
    range = 1:188;
else
    range = 1:T;
end


%% NOMINAL RATES
for i = 1:4
    options = struct('i', i, 'real', 0, 'nu', nom(i).nu, 'phi', nom(i).phi, 'ymin', nom(i).ymin, 'ymax', nom(i).ymax);
    I_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    plot_implied_ffr(date(range), I_t_scaled(range), FFR_t_scaled(range), options);
    
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
    ymin = real(i).ymin;
    ymax = real(i).ymax;
    
    options = struct('i', i, 'real', 1, 'nu', real(i).nu, 'phi', real(i).phi, 'ymin', real(i).ymin, 'ymax', real(i).ymax);
    R_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    plot_implied_ffr(date(range), R_t_scaled(range), FFR_real_t_scaled(range), options);
    
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