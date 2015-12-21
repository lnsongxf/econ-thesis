% read in data
data = csvread('data/clean/aggregate-series.csv', 4, 0);
date = transpose(datetime(data(:, 1:3)));
Y_t = transpose(data(:, 4:31)); % [ y_t, ..., y_{t-3} ]'
[kp, T] = size(Y_t); % number of variables plus lags, number of periods
p = 4; % number of lags
k = kp/p; % number of covariates

c_t = Y_t(1, :); % log consumption
pi_t = Y_t(2, :); % quarterly net inflation
ffr_t = Y_t(6, :); % quarterly net nominal FFR

ffr_real_t = ffr_t - pi_t; % quarterly net real FFR

FFR_t = exp(ffr_t); % quarterly gross nominal FFR
FFR_real_t = exp(ffr_real_t); % quarterly gross real FFR

% read in VAR estimates
A0 = csvread('data/ests/A0.csv', 0, 0, [0 0 6 0]);
A1 = csvread('data/ests/A1.csv', 0, 0, [0 0 6 27]);
Sigma = csvread('data/ests/Sigma.csv', 0, 0, [0 0 6 6]);
assert(all(size(A0) == [k, 1]));
assert(all(size(A1) == [k, k*p]));
assert(all(size(Sigma) == [k, k]));

% compute conditional moments
A0s = repmat(A0, 1, T);
Et_y_tp1 = A0s + A1*Y_t; % conditional expectation
Vt_y_tp1 = Sigma; % conditional variance

Et_c_tp1 = Et_y_tp1(1, :); % expected log consumption
Et_pi_tp1 = Et_y_tp1(2, :); % expected inflation
Vt_c_tp1 = Vt_y_tp1(1, 1); % conditional variance
Vt_pi_tp1 = Vt_y_tp1(2, 2);
Ct_c_pi_tp1 = Vt_y_tp1(1, 2); % conditional covariance

% set parameters
beta = 0.9926; % discount rate
alpha = 2; % coefficient of relative risk aversion

% compute implied rates
I_t_inv = beta * exp(-alpha*(Et_c_tp1 - c_t) - Et_pi_tp1 + alpha^2/2*Vt_c_tp1 + 1/2*Vt_pi_tp1 + alpha*Ct_c_pi_tp1);
I_t = 1 ./ I_t_inv; % quarterly gross nominal rate
R_t_inv = beta * exp(-alpha*(Et_c_tp1 - c_t) + alpha^2/2*Vt_c_tp1);
R_t = 1 ./ R_t_inv; % quarterly gross real rate

% annualize implied rate and FFR
I_t_ann = I_t .^ 4; % annualized gross nominal rate
R_t_ann = R_t .^ 4; % annualized gross real rate
FFR_t_ann = FFR_t .^ 4; % annualized gross nominal FFR
FFR_real_t_ann = FFR_real_t .^ 4; % annualized gross real FFR

% Collard & Dellas sample: 1960:Q1 to 2006:Q4
collard = 1:188;

%% plot real rates
x = log(R_t_ann(collard)) .* 100;
y = log(FFR_real_t_ann(collard)) .* 100;

plot(date(collard), x, date(collard), y);
title('Annualized Real Interest Rate');
legend('Implied', 'FFR');
xlim([datenum(1960, 1, 1) datenum(2006, 10, 1)]);
ylim([-5 15])
print('figs/crra-real.png', '-dpng');

corr_real = corrcoef(x, y);
xbar = mean(x);
ybar = mean(y);
xsig = std(x);
ysig = std(y);

%% plot nominal rates
x = log(I_t_ann(collard)) .* 100;
y = log(FFR_t_ann(collard)) .* 100;

plot(date(collard), x, date(collard), y);
title('Annualized Nominal Interest Rate');
legend('Implied', 'FFR');
xlim([datenum(1960, 1, 1) datenum(2006, 10, 1)]);
print('figs/crra-nominal.png', '-dpng');

corr_nominal = corrcoef(x, y);
xbar = mean(x);
ybar = mean(y);
xsig = std(x);
ysig = std(y);