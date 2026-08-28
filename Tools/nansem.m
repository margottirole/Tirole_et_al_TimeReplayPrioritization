function s = nansem(x)
%nansem - Compute standard error of the mean (SEM), ignoring NaNs.
% FMATOOLBOX
if nargin < 1
    error('Incorrect number of parameters (type ''help <a href="matlab:help nansem">nansem</a>'' for details).');
end
if ~ismatrix(x) & ~isvector(x)
   error('Incorrect input - use vector or matrix (type ''help <a href="matlab:help nansem">nansem</a>'' for details).');
end

if any(size(x)==1)
    x = x(:); 
end
n = sum(~isnan(x));
s = nanstd(x)./sqrt(n);
end