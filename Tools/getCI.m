function [yCI95,yMean] = getCI(y,varargin)
% returns a 2 x N (N= number of columns or rows) of CIs (5th/95th CI)
p=inputParser;
addParameter(p,'direction','columns'); % 'columns' (default) or 'rows'
parse(p,varargin{:});

if p.Results.direction == "rows"
    y= y';
end
y(isnan(y))= []; % omit nans

yCI95= NaN(2,size(y,2)); yMean= NaN(1,size(y,2));
for thiscol=1:size(y,2)
    N = size(y,1);                                      
    yMean(thiscol) = mean(y(:,thiscol));                                    
    ySEM = std(y(:,thiscol))/sqrt(N);                              
    CI95 = tinv([0.025 0.975], N-1);                    
    yCI95(:,thiscol) = bsxfun(@times, ySEM, CI95(:));  
end

end