function [ dlog_I_t, dlog_R_t ] = compute_implied_irf( dy_t, Y_t, A0, A1, Sigma, phi, nu )

% generate lags
dY_t = transpose(lagmatrix(transpose(dy_t), 0:3));
dY_t(isnan(dY_t)) = [0];

% generate alternative timeline
Y_t_shock = Y_t + dY_t;

% nominal
options = struct('real', 0, 'nu', nu, 'phi', phi, 'irf', 1);
log_I_t = compute_implied_rate(A0, A1, Sigma, Y_t, options);
log_I_t_shock = compute_implied_rate(A0, A1, Sigma, Y_t_shock, options);
dlog_I_t = log_I_t_shock - log_I_t;

% real
options = struct('real', 1, 'nu', nu, 'phi', phi, 'irf', 1);
log_R_t = compute_implied_rate(A0, A1, Sigma, Y_t, options);
log_R_t_shock = compute_implied_rate(A0, A1, Sigma, Y_t_shock, options);
dlog_R_t = log_R_t_shock - log_R_t;

end

