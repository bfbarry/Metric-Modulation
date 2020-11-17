function [closestv, r, c]=closestrc(M, value)
[closestva, closesti]=min(abs(M(:) - value));
[r,c]=ind2sub(size(M), closesti);
closestv = M(closesti);