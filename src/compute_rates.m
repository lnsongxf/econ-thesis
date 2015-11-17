% read in data
data = csvread('data/clean/aggregate-series.csv', 4, 0);
date = transpose(datetime(data(:, 1:3)));
y_t = transpose(data(:, 4:31));
[kp, T] = size(y_t); % number of variables plus lags, number of periods
p = 4; % number of lags
k = kp/p; % number of covariates

c_t = y_t(1, :); % log consumption
pi_t = y_t(2, :); % inflation

% read in VAR estimates
A0 = csvread('data/ests/A0.csv', 0, 0, [0 0 6 0]);
A1 = csvread('data/ests/A1.csv', 0, 0, [0 0 6 27]);
Sigma = csvread('data/ests/Sigma.csv', 0, 0, [0 0 6 6]);
assert(all(size(A0) == [k, 1]));
assert(all(size(A1) == [k, k*p]));
assert(all(size(Sigma) == [k, k]));

% compute conditional moments
A0s = repmat(A0, 1, T);
Et_y_tp1 = A0s + A1*y_t; % conditional expectation
Vt_y_tp1 = Sigma; % conditional variance

Et_c_tp1 = Et_y_tp1(1, :); % expected log consumption
Et_pi_tp1 = Et_y_tp1(2, :); % expected inflation
Vt_c_tp1 = Vt_y_tp1(1, 1); % conditional variance
Vt_pi_tp1 = Vt_y_tp1(2, 2);
Ct_c_pi_tp1 = Vt_y_tp1(1, 2); % conditional covariance

% set parameters
beta = 0.9926; % discount rate
sigma = 2; % coefficient of relative risk aversion

% compute implied real rates
R_t_inv = beta * exp(-sigma*(Et_c_tp1 - c_t) + sigma^2/2*Vt_c_tp1);
R_t = 1 ./ R_t_inv; % gross real rate
r_t = log(R_t); % net real rate (quarterly)

% plot implied rates over time
plot(date, r_t);

% compute annualized rates
years = floor(T/4);
R_t_annual = zeros(years, 1);
for t = 1:years
    R_t_annual(t) = R_t(4*t-3) * R_t(4*t-2) * R_t(4*t-1) * R_t(4*t);
end
r_t_annual = log(R_t_annual);
canzoneri_sample = r_t_annual(7:45); % 1966 to 2004 inclusive