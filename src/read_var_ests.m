function [ A0, A1, Sigma ] = read_var_ests( source )

A0 = csvread(['results/var-ests/', source, '/A0.csv'], 0, 0, [0 0 27 0]);
A1 = csvread(['results/var-ests/', source, '/A1.csv'], 0, 0, [0 0 27 27]);
Sigma = csvread(['results/var-ests/', source, '/Sigma.csv'], 0, 0, [0 0 27 27]);

% clean up values that should be zero
A0(abs(A0) < 1e-9) = [0];
A1(abs(A1) < 1e-9) = [0];
Sigma(abs(Sigma) < 1e-9) = [0];

end