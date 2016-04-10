function [] = plot_implied_ffr_scatter( implied, ffr, results )

% settings
source = results.source;
alpha  = results.alpha;
phi    = results.phi;
nu     = results.nu;
real   = results.real;

collard = 1:188;
blue = [0, 0.4470, 0.7410];
orange = [0.8500, 0.3250, 0.0980];

% plot
s1 = scatter(implied, ffr, 'MarkerEdgeColor', blue);
xl = xlim;
X = xl(1):xl(2);
hold on;

model = fitlm(implied, ffr);
b1 = model.Coefficients.Estimate(1);
m1 = model.Coefficients.Estimate(2);
l1 = line(X, m1*X + b1, 'Color', blue);

if strcmp(source, 'nipa')
    s2 = scatter(implied(collard), ffr(collard), 'MarkerEdgeColor', orange);
    
    model = fitlm(implied(collard), ffr(collard));
    b2 = model.Coefficients.Estimate(1);
    m2 = model.Coefficients.Estimate(2);
    l2 = line(X, m2*X + b2, 'Color', orange);
    
    legend([s1, s2], {'Full sample (1960:I to 2015:II)', 'Collard & Dellas (1960:I to 2006:IV)'}, 'Location', 'northwest');
end

hold off;

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