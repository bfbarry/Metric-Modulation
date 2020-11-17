function str = join(pieces,delimiter)
% join  join an array of strings using a delimiter
%
%   str = join(pieces,delimiter)
%
%   pieces is a cell array of strings, delimiter is a string used to join these.
%       delimiter may include standard fprintf codes, e.g. \t or \n.
%
%   See also SPLIT.
%       
% JRI 3/13/07

require(iscell(pieces)&ischar(delimiter),'Inputs must be cell, string')

delimiter = sprintf(delimiter); %expand escapes such as \t & \n

nPieces = length(pieces);

str = '';
for i = 1:nPieces-1,
    str = [str pieces{i} delimiter];
end
str = [str pieces{nPieces}];
