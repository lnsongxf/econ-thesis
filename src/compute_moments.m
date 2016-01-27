function [ Et_c_tp1, Et_c_tp2, Et_pi_tp1, Et_l_tp1, Et_l_tp2, Vt_c_tp1, ...
    Vt_c_tp2, Vt_pi_tp1, Vt_l_tp1, Ct_c_pi_tp1, Ct_c_l_tp1, ...
    Ct_pi_l_tp1, Ct_c_l_tp2, Ct_c_tp1_tp2, Ct_c_tp1_l_tp2, ...
    Ct_pi_tp1_c_tp2, Ct_pi_tp1_l_tp2 ] ...
    = compute_moments( A0, A1, Sigma, Y_t )

[~, T] = size(Y_t);
A0s = repmat(A0, 1, T);
A1t = transpose(A1);

Et_Y_tp1 = A0s + A1*Y_t;              % E_t(Y_{t+1})
Et_Y_tp2 = A0s + A1*A0s + A1^2*Y_t;
Vt_Y_tp1 = Sigma;                     % Var_t(Y_{t+1})
Vt_Y_tp2 = A1*Sigma*A1t + Sigma;
Ct_Y_tp1_tp2 = Sigma*A1t;             % Cov(Y_{t+1}, Y_{t+2})

Et_c_tp1 = Et_Y_tp1(1, :);            % E_t(c_{t+1})
Et_c_tp2 = Et_Y_tp2(1, :);
Et_pi_tp1 = Et_Y_tp1(2, :);
Et_l_tp1 = Et_Y_tp1(3, :);
Et_l_tp2 = Et_Y_tp2(3, :);

Vt_c_tp1 = Vt_Y_tp1(1, 1);            % Var_t(c_{t+1})
Vt_c_tp2 = Vt_Y_tp2(1, 1);
Vt_pi_tp1 = Vt_Y_tp1(2, 2);
Vt_l_tp1 = Vt_Y_tp1(3, 3);

Ct_c_pi_tp1 = Vt_Y_tp1(1, 2);         % Cov_t(c_{t+1}, pi_{t+1})
Ct_c_l_tp1 = Vt_Y_tp1(1, 3);
Ct_pi_l_tp1 = Vt_Y_tp1(2, 3);

Ct_c_l_tp2 = Vt_Y_tp2(1, 3);

Ct_c_tp1_tp2 = Ct_Y_tp1_tp2(1, 1);    % Cov_t(c_{t+1}, c_{t+2})
Ct_c_tp1_l_tp2 = Ct_Y_tp1_tp2(1, 3);
Ct_pi_tp1_c_tp2 = Ct_Y_tp1_tp2(2, 1);
Ct_pi_tp1_l_tp2 = Ct_Y_tp1_tp2(2, 3);

end