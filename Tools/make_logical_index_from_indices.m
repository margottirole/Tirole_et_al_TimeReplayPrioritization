function idx = make_logical_index_from_indices(indices,totalL)

idx = false(totalL,1);

for n = 1:size(indices,1)
    idx(indices(n,1):indices(n,2)) = true;
end

