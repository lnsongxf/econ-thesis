function [] = plot_implied_ffr( date, implied, ffr, options )

% settings
i = options.i;
real = options.real;
nu = options.nu;
phi = options.phi;
ymin = options.ymin;
ymax = options.ymax;

% plot
plot(date, implied, date, ffr);
legend('Implied', 'FFR');
xlim([datenum(1960, 1, 1) datenum(2006, 10, 1)]);
ylim([ymin ymax])
ylabel('Annualized Interest Rate');
if real == 0
    title(['Nominal: \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied_ffr/nominal_', int2str(i), '.png'];
else
    title(['Real: \nu = ', num2str(nu), ', \phi = ', num2str(phi)]);
    file = ['figs/implied_ffr/real_', int2str(i), '.png'];
end
print(file, '-dpng');

end

