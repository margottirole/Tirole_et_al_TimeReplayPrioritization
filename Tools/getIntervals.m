function [starts,stops]= getIntervals(logical_array)
% logical_array is a logical vector satisfying conditions and to extract
% intervals where logical_array==1

% returns starts and stops for intervals, as well 

starts= []; stops= [];
if ~any(~ismember(unique(logical_array),[0 1]))
    
    % find changes in sequences of 0/1s
    gaps= diff([ logical_array]);
    starts= find(gaps==1)+1;
    stops= find(gaps==-1);
    if logical_array(1)==1
        starts= [1 starts];
    end
    if logical_array(end)==1
        stops= [stops length(logical_array)];
    end

    int_too_short= starts == stops;% e.g. a single 1 at the very end
    starts(int_too_short)=[];
    stops(int_too_short)=[];

    starts= starts';
    stops= stops';

    % figure;
    % plot(logical_array,'k*-');
    % hold on;
    % plot(starts,ones(length(starts)),'g+');
    % plot(stops,ones(length(stops)),'r+');

else
    disp('wrong array input, needs to be a vector of 0s and 1s');
    keyboard
    return;
end



end