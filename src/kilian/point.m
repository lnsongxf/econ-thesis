% POINT.M 
% Lutz Kilian
% University of Michigan
% April 1997


%function [CI]=point(y)
function [ dffr_t_CI, dffr_real_t_CI, dlog_I_t_CI, dlog_R_t_CI ] = point( y, A0, Y_t, i ) % PZL 2/2/16

global h p q

p=4;		% VAR lag order
% h=3;		% Impulse response horizon
h = 20; % PZL 2/2/16

[t,q]=size(y);
y=detrend(y,0);
[A,SIGMA,U,V]=olsvarc(y,p);						% VAR with intercept
if ~ any(abs(eig(A))>=1)
	[A]=asybc(A,SIGMA,t,p);
end;

% PZL 2/2/16
%[CI]=boot(A,U,y,V);
[dffr_t_CI, dffr_real_t_CI, dlog_I_t_CI, dlog_R_t_CI] = boot(A, U, y, V, A0, Y_t);