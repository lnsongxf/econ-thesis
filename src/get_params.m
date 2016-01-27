function [ nom, real ] = get_params()

nom = struct('nu', {}, 'phi', {}, 'ymin', {}, 'ymax', {}, 'mean', {}, 'std', {}, 'corr', {});

nom(1).nu = 1;
nom(2).nu = 1;
nom(3).nu = 0.34;
nom(4).nu = 0.34;

nom(1).phi = 0;
nom(2).phi = 0.8;
nom(3).phi = 0;
nom(4).phi = 0.8;

real = nom;

nom(1).ymin = 0;
nom(2).ymin = -100;
nom(3).ymin = 0;
nom(4).ymin = 0;

nom(1).ymax = 20;
nom(2).ymax = 150;
nom(3).ymax = 20;
nom(4).ymax = 20;

real(1).ymin = -5;
real(2).ymin = -100;
real(3).ymin = -5;
real(4).ymin = -5;

real(1).ymax = 15;
real(2).ymax = 150;
real(3).ymax = 15;
real(4).ymax = 15;

end

