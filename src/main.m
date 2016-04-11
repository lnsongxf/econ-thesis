% default parameters
alpha_d = 2;
phi_d   = 0;
nu_d    = 1;

% NIPA
[results1, data1] = implied_rates('nipa', 2, phi_d, nu_d);   % SEP
[results2, ~]     = implied_rates('nipa', 2, 0.8,   nu_d);   % SEP + HP
[results3, ~]     = implied_rates('nipa', 2, phi_d, 0.34);   % NSEP
[results4, ~]     = implied_rates('nipa', 2, 0.8,   0.34);   % NSEP + HP
nipa_results = [data1, results1, results2, results3, results4];
writetable(struct2table(nipa_results), 'results/implied-rate-summary/nipa.csv');

% NIPA, Collard & Dellas sample (1960:I to 2006:IV)
[results5, data2] = implied_rates('nipa-collard', 2, phi_d, nu_d);   % SEP
[results6, ~]     = implied_rates('nipa-collard', 2, 0.8,   nu_d);   % SEP + HP
[results7, ~]     = implied_rates('nipa-collard', 2, phi_d, 0.34);   % NSEP
[results8, ~]     = implied_rates('nipa-collard', 2, 0.8,   0.34);   % NSEP + HP
nipa_collard_results = [data2, results5, results6, results7, results8];
writetable(struct2table(nipa_collard_results), 'results/implied-rate-summary/nipa-collard.csv');

% NIPA, Canzoneri et al sample (1966:I to 2004:I)
[results5, data2] = implied_rates('nipa-canzoneri', 2, phi_d, nu_d);   % SEP
[results6, ~]     = implied_rates('nipa-canzoneri', 2, 0.8,   nu_d);   % SEP + HP
[results7, ~]     = implied_rates('nipa-canzoneri', 2, phi_d, 0.34);   % NSEP
[results8, ~]     = implied_rates('nipa-canzoneri', 2, 0.8,   0.34);   % NSEP + HP
nipa_canzoneri_results = [data2, results5, results6, results7, results8];
writetable(struct2table(nipa_canzoneri_results), 'results/implied-rate-summary/nipa-canzoneri.csv');

% CEX bondholders
[results9, data3] = implied_rates('cex-bondholders', 2,   phi_d, nu_d);
[results10, ~]    = implied_rates('cex-bondholders', 1,   phi_d, nu_d);
[results11, ~]    = implied_rates('cex-bondholders', 0.5, phi_d, nu_d);
[results12, ~]    = implied_rates('cex-bondholders', 0.2, phi_d, nu_d);
cex_bondholders_results = [data3, results9, results10, results11, results12];
writetable(struct2table(cex_bondholders_results), 'results/implied-rate-summary/cex-bondholders.csv');

% CEX nonbondholders
[results13, data4] = implied_rates('cex-nonbondholders', 2,   phi_d, nu_d);
[results14, ~]     = implied_rates('cex-nonbondholders', 1,   phi_d, nu_d);
[results15, ~]     = implied_rates('cex-nonbondholders', 0.5, phi_d, nu_d);
[results16, ~]     = implied_rates('cex-nonbondholders', 0.2, phi_d, nu_d);
cex_nonbondholders_results = [data4, results13, results14, results15, results16];
writetable(struct2table(cex_nonbondholders_results), 'results/implied-rate-summary/cex-nonbondholders.csv');