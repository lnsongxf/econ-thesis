function [ A0, A1, Sigma ] = read_var_ests()

A0 = csvread('data/ests/var/A0.csv', 0, 0, [0 0 27 0]);
A1 = csvread('data/ests/var/A1.csv', 0, 0, [0 0 27 27]);
Sigma = csvread('data/ests/var/Sigma.csv', 0, 0, [0 0 27 27]);

% clean up values that should be zero
A0(abs(A0) < 1e-9) = [0];
A1(abs(A1) < 1e-9) = [0];
Sigma(abs(Sigma) < 1e-9) = [0];

end

