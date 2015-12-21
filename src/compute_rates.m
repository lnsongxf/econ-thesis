% read in data
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

ffr_real_t = ffr_t - pi_t; % quarterly net real FFR
FFR_t = exp(ffr_t); % quarterly gross nominal FFR
FFR_real_t = exp(ffr_real_t); % quarterly gross real FFR

% read in VAR estimates
A0 = csvread('data/ests/A0.csv', 0, 0, [0 0 27 0]);
A1 = csvread('data/ests/A1.csv', 0, 0, [0 0 27 27]);
Sigma = csvread('data/ests/Sigma.csv', 0, 0, [0 0 27 27]);
assert(all(size(A0) == [kp, 1]));
assert(all(size(A1) == [kp, kp]));
assert(all(size(Sigma) == [kp, kp]));

% clean up values that should be zero
A0(abs(A0) < 1e-9) = [0];
A1(abs(A1) < 1e-9) = [0];
Sigma(abs(Sigma) < 1e-9) = [0];

% compute conditional moments
A0s = repmat(A0, 1, T);
A1t = transpose(A1);

Et_Y_tp1 = A0s + A1*Y_t; % E_t(Y_{t+1})
Et_Y_tp2 = A0s + A1*A0s + A1^2*Y_t; % E_t(Y_{t+2})
Vt_Y_tp1 = Sigma; % Var_t(Y_{t+1})
Vt_Y_tp2 = A1*Sigma*A1t + Sigma; % Var_t(Y_{t+2})
Ct_Y_tp1_tp2 = Sigma*A1t; % Cov(Y_{t+1}, Y_{t+2})

Et_c_tp1 = Et_Y_tp1(1, :); % expected log consumption
Et_c_tp2 = Et_Y_tp2(1, :);
Et_pi_tp1 = Et_Y_tp1(2, :); % expected inflation
Et_l_tp1 = Et_Y_tp1(3, :); % expected leisure
Et_l_tp2 = Et_Y_tp2(3, :);

Vt_c_tp1 = Vt_Y_tp1(1, 1); % conditional variance
Vt_c_tp2 = Vt_Y_tp2(1, 1);
Vt_pi_tp1 = Vt_Y_tp1(2, 2);
Vt_l_tp1 = Vt_Y_tp1(3, 3);

Ct_c_pi_tp1 = Vt_Y_tp1(1, 2); % conditional covariance
Ct_c_l_tp1 = Vt_Y_tp1(1, 3);
Ct_pi_l_tp1 = Vt_Y_tp1(2, 3);

Ct_c_l_tp2 = Vt_Y_tp2(1, 3);

Ct_c_tp1_tp2 = Ct_Y_tp1_tp2(1, 1);
Ct_c_tp1_l_tp2 = Ct_Y_tp1_tp2(1, 3);
Ct_pi_tp1_c_tp2 = Ct_Y_tp1_tp2(2, 1);
Ct_pi_tp1_l_tp2 = Ct_Y_tp1_tp2(2, 3);


% set parameters
beta = 0.9926; % discount rate
alpha = 2; % coefficient of relative risk aversion
nu = 1; % weight of consumption (vs leisure)
phi = 0; % habit formation parameter

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

%% here goes nothing
chi_1t = (nu*(1-alpha) - 1)*Et_c_tp1 - phi*nu*(1-alpha)*c_t + (1-nu)*(1-alpha)*Et_l_tp1 - Et_pi_tp1 + 1/2*(nu*(1-alpha) - 1)^2*Vt_c_tp1 + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 + 1/2*Vt_pi_tp1 - (1-nu)*(1-alpha)*Ct_pi_l_tp1 + (nu*(1-alpha) - 1)*(1-nu)*(1-alpha)*Ct_c_l_tp1 - (nu*(1-alpha) - 1)*Ct_c_pi_tp1;
chi_2t = nu*(1-alpha)*Et_c_tp2 - (phi*nu*(1-alpha) + 1)*Et_c_tp1 + (1-nu)*(1-alpha)*Et_l_tp2 - Et_pi_tp1 + 1/2*(nu*(1-alpha))^2*Vt_c_tp2 + 1/2*(phi*nu*(1-alpha) + 1)^2*Vt_c_tp1 + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 + 1/2*Vt_pi_tp1 - nu*(1-alpha)*Ct_pi_tp1_c_tp2 + (phi*nu*(1-alpha) + 1)*Ct_c_pi_tp1 - (1-nu)*(1-alpha)*Ct_pi_tp1_l_tp2 - nu*(1-alpha)*(phi*nu*(1-alpha) + 1)*Ct_c_tp1_tp2 + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp2 - (phi*nu*(1-alpha) + 1)*(1-nu)*(1-alpha)*Ct_c_tp1_l_tp2;
chi_3t = (nu*(1-alpha) - 1)*c_t - phi*nu*(1-alpha)*c_tm1 + (1-nu)*(1-alpha)*l_t;
chi_4t = nu*(1-alpha)*Et_c_tp1 - (phi*nu*(1-alpha) + 1)*c_t + (1-nu)*(1-alpha)*Et_l_tp1 + 1/2*(nu*(1-alpha))^2*Vt_c_tp1 + 1/2*((1-nu)*(1-alpha))^2*Vt_l_tp1 + nu*(1-nu)*(1-alpha)^2*Ct_c_l_tp1;

I_t_inv = beta * (exp(chi_1t) - beta*phi*exp(chi_2t)) / (exp(chi_3t) - beta*phi*exp(chi_4t));
I_t = 1 ./ I_t_inv; % quarterly gross nominal rate

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