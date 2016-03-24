function [] = implied_rates( source )
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


%% SET PARAMETERS
[nom, real] = set_params();

% Collard & Dellas sample: 1960:Q1 to 2006:Q4
collard = 0;
if collard == 1
    range = 1:188;
else
    range = 1:T;
end


%% NOMINAL RATES
for i = 1:4
    options = struct('i', i, 'real', 0, 'nu', nom(i).nu, 'phi', nom(i).phi, 'ymin', nom(i).ymin, 'ymax', nom(i).ymax, 'irf', 0);
    I_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    plot_implied_ffr(source, date(range), I_t_scaled(range), FFR_t_scaled(range), options);
    
    % summary stats
    nom(i).mean = mean(I_t_scaled(range));
    nom(i).std = std(I_t_scaled(range));
    nom(i).min = min(I_t_scaled(range));
    nom(i).max = max(I_t_scaled(range));
    
    % correlation between implied rate and FFR
    corr_matrix = corrcoef(I_t_scaled(range), FFR_t_scaled(range));
    nom(i).corr = corr_matrix(1, 2);
    
    % regress spread on FFR
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
    
    options = struct('i', i, 'real', 1, 'nu', real(i).nu, 'phi', real(i).phi, 'ymin', real(i).ymin, 'ymax', real(i).ymax, 'irf', 0);
    R_t_scaled = compute_implied_rate(A0, A1, Sigma, Y_t, options);
    plot_implied_ffr(source, date(range), R_t_scaled(range), FFR_real_t_scaled(range), options);
    
    % summary stats
    real(i).mean = mean(R_t_scaled(range));
    real(i).std = std(R_t_scaled(range));
    real(i).min = min(R_t_scaled(range));
    real(i).max = max(R_t_scaled(range));
    
    % correlation between implied rate and FFR
    corr_matrix = corrcoef(R_t_scaled(range), FFR_real_t_scaled(range));
    real(i).corr = corr_matrix(1, 2);
    
    % regress spread on FFR
    spread_t = R_t_scaled - FFR_real_t_scaled;
    spread_lags_t = transpose(lagmatrix(spread_t, 1:4));
    FFR_spread_lags_t = [FFR_t_scaled; spread_lags_t];
    model = fitlm(transpose(FFR_spread_lags_t(:, range)), spread_t(range));
    real(i).coef = model.Coefficients.Estimate(2); % FFR coefficient
    real(i).se = model.Coefficients.SE(2); % FFR standard error
end


%% WRITE RESULTS TO FILE
writetable(struct2table(nom), ['results/implied-rate-summary/', source, '/nominal.csv']);
writetable(struct2table(real), ['results/implied-rate-summary/', source, '/real.csv']);

end