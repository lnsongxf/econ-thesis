function [] = plot_implied_ffr_scatter( implied, ffr, results )

% settings
source = results.source;
alpha  = results.alpha;
phi    = results.phi;
nu     = results.nu;
real   = results.real;

% plot
scatter(implied, ffr);
lsline;
xlabel('Implied');
ylabel('FFR');
if real == 0
    title(['Nominal: \alpha = ', num2str(alpha), ', \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied-vs-ffr-scatter/', source, '/nominal_alpha', num2str(alpha), '_phi', num2str(phi), '_nu', num2str(nu), '.png'];
else
    title(['Real: \alpha = ', num2str(alpha), ', \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied-vs-ffr-scatter/', source, '/real_alpha', num2str(alpha), '_phi', num2str(phi), '_nu', num2str(nu), '.png'];
end
print(file, '-dpng');

end