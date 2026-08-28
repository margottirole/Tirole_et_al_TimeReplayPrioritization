function estimated_position=reconstructFast(n,all_place_fields,bin_width)
    % Creates matrix where rows are cells and columns are position bins
    bin_length = size(all_place_fields,2); %columns
    number_of_cells = size(all_place_fields,1); %rows
    parameters.bayesian_threshold=10.^(log2(number_of_cells)-log2(400)); % small value multiplied to all values to get rid of zeros
    all_place_fields(all_place_fields<parameters.bayesian_threshold) = parameters.bayesian_threshold;
    sum_of_place_fields = sum(all_place_fields,1);  % adds up spikes per bin (used later for exponential)
    for j = 1: size(n,2)
        n_spikes = n(:,j)*ones(1,bin_length); %number of spikes in time bin
        pre_product = all_place_fields.^n_spikes; % pl field values raised to num of spikes
        pre_product(find(pre_product<parameters.bayesian_threshold)) = parameters.bayesian_threshold;
        product_of_place_fields = prod(pre_product,1); %product of pl fields
        estimated_position(:,j) = product_of_place_fields.*(exp(-bin_width*sum_of_place_fields)); % bayesian formula
    end
    % do not normalise yet
    % estimated_position= estimated_position./sum(estimated_position,1);
end