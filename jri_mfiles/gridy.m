function hout = gridy(y,c,lw)
% gridy  Plot horizontal y grid lines
%
%   h = gridy(y, [c], [lw])
%
%   plot grid lines at values of y, with optional linespec c & linewidth lw
%
%   c is either a [r g b] or a standard color letter or a linespec (color letter
%   & optional line style).
%
%   returns handles to drawn lines.
%
% simple shortcut function to plotgrid for common use
%
%   See also PLOTGRID, GRIDX.
%
% JRI 5/03

if ~nargin,
  y = 0;
end

if nargin < 3,
  lw = 0.5;
end

if nargin < 2,
  h = plotgrid([],[],y,[]);
else
  if isstr(c),
    if length(c)==1,
      style = '-';
    else
      style = c(2:end);
    end
    c = c(1);
  else %it's a rgb color, use solid line. For more control call plotgrid.
    style = '-';
  end
  h = plotgrid([],[],y,[],c,lw,style);
end

if nargout,
  hout = h;
end
