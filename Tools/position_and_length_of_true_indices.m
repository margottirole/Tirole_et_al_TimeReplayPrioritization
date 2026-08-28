function [out] = position_and_length_of_true_indices(idx)

if size(idx,2) ~= 1
    idx = transpose(idx);
end

edges = diff(idx);


edge_up = find(edges==1) + 1;        % find edges
edge_down = find(edges==-1);

nUp = numel(edge_up);
nDown = numel(edge_down);

if nUp == 0
    if nDown == 0
        if sum(idx) == length(idx)
            edge_up = 1;
            edge_down = length(idx);
            nUp = 1;
            nDown = 1;
        else
        out = [];
        return
        end
    else
        edge_up = 1;
        nUp = 1;
    end
end

up1 = edge_up(1);
if nDown == 0
    down1 = length(edges);
else
    down1 = edge_down(1);
end
if nUp == nDown
    if up1 > down1
        edge_up = [1; edge_up];
        edge_down = [edge_down; length(edges)];
    end
elseif nUp > nDown
    edge_down = [edge_down; length(edges)];
elseif nUp < nDown
    edge_up = [1; edge_up];
end

out(:,1:2) = [edge_up, edge_down];
out(:,3) = out(:,2) - out(:,1) +1;

zidx = out(:,3)==0;
out(zidx,3)=1;


end
