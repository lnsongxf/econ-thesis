function [ results ] = implied_rates( source, alpha, phi, nu )
% ARGUMENT  DESCRIPTION
% source    one of 'aggregate', 'cex-bondholders', or 'cex-nonbondholders'
% alpha     risk aversion coefficient
% phi       habit persistence parameter
% nu        consumption weight in nonseparable consumption/leisure

%% READ DATA
data = csvread(['data/clean/', source, '-series.csv'], 4, 0);
date = transpose(datetime(data(:, 1:3)));
Y_t = transpose(data(:, 4:31)); % [ y_t, ..., y_{t-3} ]'
[kp, T] = size(Y_t); % number of variables plus lags, number of periods
p = 4; % number of lags
k = kp/p; % number of covariates

% read in VAR estimates
[A0, A1, Sigma] = read_var_ests(source);
assert(all(size(A0) == [kp, 1]));
assert(all(size(A1) == [kp, kp]));
assert(all(size(Sigma) == [kp, kp]));

% compute FFR
[FFR_t_scaled, FFR_real_t_scaled] = compute_ffr_scaled(Y_t);


%% SET UP
results = struct('source', {}, 'alpha', {}, 'phi', {}, 'nu', {}, 'real', {}, ...
    'mean', {}, 'std', {}, 'min', {}, 'max', {}, 'corr', {}, ...
    'coef', {}, 'se', {});

% Collard & Dellas sample: 1960:Q1 to 2006:Q4
collard = 0;
if collard == 1
    range = 1:188;
else
    range = 1:T;
end


%% NOMINAL RATES
% set parameters
results(1).source = source;
results(1).alpha  = alpha;
results(1).phi    = phi;
results(1).nu     = nu;
results(1).real   = 0;

% compute implied rates and plot
I_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, results(1), 0);
plot_implied_ffr(date(range), I_t_scaled(range), FFR_t_scaled(range), results(1));

% summary stats
results(1).mean = mean(I_t_scaled(range));
results(1).std = std(I_t_scaled(range));
results(1).min = min(I_t_scaled(range));
results(1).max = max(I_t_scaled(range));

% correlation between implied rate and FFR
corr_matrix = corrcoef(I_t_scaled(range), FFR_t_scaled(range));
results(1).corr = corr_matrix(1, 2);

% regress spread on FFR
spread_t = I_t_scaled - FFR_t_scaled;
spread_lags_t = transpose(lagmatrix(spread_t, 1:4));
FFR_spread_lags_t = [FFR_t_scaled; spread_lags_t];
model = fitlm(transpose(FFR_spread_lags_t(:, range)), spread_t(range));
results(1).coef = model.Coefficients.Estimate(2); % FFR coefficient
results(1).se = model.Coefficients.SE(2); % FFR standard error


%% REAL RATES
% set parameters
results(2).source = source;
results(2).alpha  = alpha;
results(2).phi    = phi;
results(2).nu     = nu;
results(2).real   = 1;

% compute implied rates and plot
R_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, results(2), 0);
plot_implied_ffr(date(range), R_t_scaled(range), FFR_t_scaled(range), results(2));
    
% summary stats
results(2).mean = mean(R_t_scaled(range));
results(2).std = std(R_t_scaled(range));
results(2).min = min(R_t_scaled(range));
results(2).max = max(R_t_scaled(range));
    
% correlation between implied rate and FFR
corr_matrix = corrcoef(R_t_scaled(range), FFR_real_t_scaled(range));
results(2).corr = corr_matrix(1, 2);

% regress spread on FFR
spread_t = R_t_scaled - FFR_real_t_scaled;
spread_lags_t = transpose(lagmatrix(spread_t, 1:4));
FFR_spread_lags_t = [FFR_t_scaled; spread_lags_t];
model = fitlm(transpose(FFR_spread_lags_t(:, range)), spread_t(range));
results(2).coef = model.Coefficients.Estimate(2); % FFR coefficient
results(2).se = model.Coefficients.SE(2); % FFR standard error

end