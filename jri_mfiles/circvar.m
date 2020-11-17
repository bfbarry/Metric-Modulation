function [ncvar,wcvar] = circvar(z)
% circvar  Calculate circular variance of angles (input as columns in a matrix). 
%
%       [ncv, wcv] = circvar(z);
%
% Input:
%       z       complex sample data, each column is a variable, rows are samples
%
% Output: 
%       ncv     normalized circ var (all vectors count equally) [0,1]
%       wcv     weighted circ var (vectors weighted by their magnitude) [0,1]
%       wcvn    wcv expressed as a fraction of the expected variance from 
%               a uniform random distribution of phases (of constant mag 1/2pi) from -pi:pi.
%
%       z is a list of phase vectors
%           each element z_i = r_i * exp(i*theta_i)
%
%       sd = sqrt(-2*log(1-cv))
%
% JRI 2/26/02, ADP 5/28/02


% Get normalized circular variance

znorm		= z./abs(z);
ncvar		= 1 - abs(sum(znorm)/length(z));

% Get weighted circular variance.

wcvar = 1 - abs(sum(z)./sum(abs(z)));

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%try things 'by the book' (N.I. Fisher)
%first moment
R = mean(z);            %vector mean
Rbar = abs(R);          %mean length
thetabar = angle(R);    %mean angle
V = 1-Rbar;             %sample circular variance
v = sqrt(-2*log(1-V));  %sample standard deviation (note, lower case v)

%second moment
R2 = mean(z.*z);
R2bar = abs(R2);

