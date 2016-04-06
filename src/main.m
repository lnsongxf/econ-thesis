% default parameters
alpha_d = 2;
phi_d   = 0;
nu_d    = 1;

% aggregate
results1 = implied_rates('aggregate', 2, phi_d, nu_d);   % SEP
results2 = implied_rates('aggregate', 2, 0.8,   nu_d);   % SEP + HP
results3 = implied_rates('aggregate', 2, phi_d, 0.34);   % NSEP
results4 = implied_rates('aggregate', 2, 0.8,   0.34);   % NSEP + HP
aggregate_results = [results1, results2, results3, results4];
writetable(struct2table(aggregate_results), 'results/implied-rate-summary/aggregate.csv');

% CEX bondholders
results5 = implied_rates('cex-bondholders', 2,   phi_d, nu_d);
results6 = implied_rates('cex-bondholders', 1,   phi_d, nu_d);
results7 = implied_rates('cex-bondholders', 0.5, phi_d, nu_d);
results8 = implied_rates('cex-bondholders', 0.1, phi_d, nu_d);
cex_bondholders_results = [results5, results6, results7, results8];
writetable(struct2table(cex_bondholders_results), 'results/implied-rate-summary/cex-bondholders.csv');

% CEX nonbondholders
results9 = implied_rates('cex-nonbondholders', 2,   phi_d, nu_d);
results10 = implied_rates('cex-nonbondholders', 1,   phi_d, nu_d);
results11 = implied_rates('cex-nonbondholders', 0.5, phi_d, nu_d);
results12 = implied_rates('cex-nonbondholders', 0.1, phi_d, nu_d);
cex_nonbondholders_results = [results9, results10, results11, results12];
writetable(struct2table(cex_nonbondholders_results), 'results/implied-rate-summary/cex-nonbondholders.csv');