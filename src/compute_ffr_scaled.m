function [ FFR_t_scaled, FFR_real_t_scaled ] = compute_ffr_scaled( Y_t )

pi_t = Y_t(2, :);
ffr_t = Y_t(6, :);
FFR_t = exp(ffr_t); % quarterly gross nominal FFR
FFR_t_ann = FFR_t .^ 4; % annualized gross nominal FFR
FFR_t_scaled = log(FFR_t_ann) .* 100;

ffr_real_t = ffr_t - pi_t; % quarterly net real FFR
FFR_real_t = exp(ffr_real_t); % quarterly gross real FFR
FFR_real_t_ann = FFR_real_t .^4; % annualized gross real FFR
FFR_real_t_scaled = log(FFR_real_t_ann) .* 100;

end

