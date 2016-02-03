% BOOT.M 
% Lutz Kilian
% University of Michigan
% April 1997

%function [CI]=boot(A,U,y,V)
function [ dffr_t_CI, dffr_real_t_CI, dlog_I_t_CI, dlog_R_t_CI ] = boot( A, U, y, V, A0, Y_t ) % PZL 2/2/16

global p h 

nrep=1000; % for 90% interval

[t,q]=size(y);				
y=y';
Y=y(:,p:t);	
for i=1:p-1
 	Y=[Y; y(:,p-i:t-i)];		
end;

Ur=zeros(q*p,t-p);   
Yr=zeros(q*p,t-p+1); 
IRFrmat=zeros(nrep,q^2*(h+1));

% % PZL 2/2/16
dffr_ts = zeros(nrep, h+1);
dffr_real_ts = zeros(nrep, h+1);
dlog_I_ts = zeros(nrep, h+1);
dlog_R_ts = zeros(nrep, h+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  start of bootstrap simulation                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create nboot bootstrap replications of pseudo data

for j=1:nrep
   
	pos=fix(rand(1,1)*(t-p+1))+1;
	Yr(:,1)=Y(:,pos);

	index=fix(rand(1,t-p)*(t-p))+1;
	Ur(:,2:t-p+1)=U(:,index);	

	for i=2:t-p+1
		Yr(:,i)= V + A*Yr(:,i-1)+Ur(:,i); 
	end;

	yr=[Yr(1:q,:)];
	for i=2:p
		yr=[Yr((i-1)*q+1:i*q,1) yr];
   end;
   yr=yr';
   yr=detrend(yr,0);
   
	pr=p;

   [Ar,SIGMAr]=olsvarc(yr,pr);

	if ~ any(abs(eig(Ar))>=1)
		[Ar]=asybc(Ar,SIGMAr,t,pr);
	end;

	[IRFr]=irfvar(Ar,SIGMAr(1:q,1:q),pr);
	IRFrmat(j,:)=vec(IRFr)';
    
    % PZL 2/2/16
    dy_t = IRFr(36:42, :);
    dffr_ts(j, :) = dy_t(6, :);
    dffr_real_ts(j, :) = dy_t(6, :) - dy_t(2, :);
    [dlog_I_t, dlog_R_t] = compute_implied_irf(dy_t, Y_t, A0, Ar, SIGMAr, 0, 1);
    dlog_I_ts(j, :) = dlog_I_t;
    dlog_R_ts(j, :) = dlog_R_t;
end;   

% Calculate 90 perccent interval endpoints
CI=prctile(IRFrmat,[5 95]);

% PZL 2/2/16
dffr_t_CI = prctile(dffr_ts, [5 50 95]);
dffr_real_t_CI = prctile(dffr_real_ts, [5 50 95]);
dlog_I_t_CI = prctile(dlog_I_ts, [5 50 95]);
dlog_R_t_CI = prctile(dlog_R_ts, [5 50 95]);

