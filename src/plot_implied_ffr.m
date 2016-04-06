function [] = plot_implied_ffr( date, implied, ffr, results )

% settings
source = results.source;
alpha  = results.alpha;
phi    = results.phi;
nu     = results.nu;
real   = results.real;

[~, T] = size(date);
startdate = datenum(date(1, 1));
enddate   = datenum(date(1, T));

% plot
plot(date, implied, date, ffr);
legend('Implied', 'FFR');
xlim([startdate enddate]);
ylabel('Annualized Interest Rate');
if real == 0
    title(['Nominal: \alpha = ', num2str(alpha), ', \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied-vs-ffr/', source, '/nominal_alpha', num2str(alpha), '_phi', num2str(phi), '_nu', num2str(nu), '.png'];
else
    title(['Real: \alpha = ', num2str(alpha), ', \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied-vs-ffr/', source, '/real_alpha', num2str(alpha), '_phi', num2str(phi), '_nu', num2str(nu), '.png'];
end
print(file, '-dpng');

end

