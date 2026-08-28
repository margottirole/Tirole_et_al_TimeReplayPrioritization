function lap_indices = extract_unidirectional_laps(smoothpos,start_idx,end_idx,partial_end_range,partial_start_range)

% 
% returns n_laps x 3 matrix
% lap_indices(:,1:2) = start and end indices of laps
% lap_indices(:,3) indicates whether this is a partial lap
%

start_indices = position_and_length_of_true_indices(start_idx);
end_indices   = position_and_length_of_true_indices(end_idx);

partial_end_idx   = and(smoothpos < partial_end_range(2),    smoothpos > partial_end_range(1));
partial_start_idx = and(smoothpos < partial_start_range(2), smoothpos > partial_start_range(1));

partial_end_indices   = position_and_length_of_true_indices(partial_end_idx);
partial_start_indices = position_and_length_of_true_indices(partial_start_idx);


n_start = size(start_indices,1);

partial_lap_idx = false(n_start,1);
lap_indices     = NaN(n_start,2);

for n = 1:n_start   % loop over start points
    
    start_point     = start_indices(n,2);      
    poss_end_points = end_indices(end_indices(:,1) > start_point ,1); % find all possible end points at other end of track
    
    if isempty(poss_end_points) % skip if there are no possible end points
        continue
    end
    
    % the next point of interest is either the animal reaching the end of the track, or the animal re-entering the same end (ie when partial track run)
    if n == n_start 
        next_point = [NaN, poss_end_points(1)];
    else   
        next_point = [start_indices(n+1,1), poss_end_points(1)];
    end
    
    [~,nextID] = min(next_point); % find which option is closest to start point
    
    if nextID == 1  % if the next closest point is re-entry into same track end...
        
        part_cross_idx = and(partial_end_indices(:,1)>start_point, partial_end_indices(:,1) < next_point(1));
        part_cross = any(part_cross_idx); % determine whether the animal croseed the minium threshold we would consider as a lap
        
        if part_cross % if it has crossed the threshold...
           
            part_crossings = partial_end_indices(part_cross_idx,1); 
            track_segment  = smoothpos(start_point:next_point); % ... find out how far it got
           
            if smoothpos(start_point) > smoothpos(part_crossings(1,1))  % depends on which way the animal is running
                pos_reached      = min(track_segment);
                partial_end_idx  = track_segment < pos_reached + 5;  
            else
                pos_reached = max(track_segment);
                partial_end_idx  = track_segment > pos_reached - 5;
            end
            
             partial_end_inds = find(partial_end_idx);
             partial_end      = start_point + partial_end_inds(1) - 1;
            
            lap_indices(n,1) = start_point;
            lap_indices(n,2) = partial_end;    
            
            partial_lap_idx(n) = true;      % record as partial lap
            
        else % if it hasn't crossed the partial lap threshold
            continue
        end
    else % if the animal did reach the other end
         lap_indices(n,1) = start_point; 
         lap_indices(n,2) = next_point(2);       
    end    
end

nanidx = isnan(lap_indices(:,1));

lap_indices(nanidx,:)   = [];
partial_lap_idx(nanidx) = [];


%% find any return partial lap

lap_idx = make_logical_index_from_indices(lap_indices,length(smoothpos)); % to check if partial position falls within lap that has already been detected

n_end       = size(end_indices,1);
part_lap    = NaN(n_end,2);
poss_starts = NaN(n_end,1); % to record partial lap threshold crossing so we don't repeat the same ones


for ne = 1: n_end % loop over end points
    end_point   = end_indices(ne,1);
    poss_start = partial_start_indices(partial_start_indices(:,1) < end_point,1); % check partial crossings in the other direction as potential start points
    if isempty(poss_start)
        continue
    else
        poss_start = poss_start(end);        
        if lap_idx(poss_start)  % if this crossing is already in an extracted lap
            continue
        elseif any(poss_starts == poss_start)  % if this crossing has already been extracted as a partial lap
            continue
        else % extract partial lap
            prev_end = end_indices(end_indices(:,2) < poss_start, 2);
            if isempty(prev_end)
                continue
            else
                prev_end = prev_end(end);
                track_segment  = smoothpos(prev_end:end_point);
                
                if smoothpos(end_point) > smoothpos(poss_start)
                    pos_reached      = min(track_segment);
                    partial_start_idx  = track_segment < pos_reached + 5;
                else
                    pos_reached = max(track_segment);
                    partial_start_idx  = track_segment > pos_reached - 5;
                end
                
                partial_start_inds = find(partial_start_idx);
                partial_start      = prev_end + partial_start_inds(end) - 1;
                
                part_lap(ne,1) = partial_start;
                part_lap(ne,2) = end_point;
                
                poss_starts(ne) = poss_start;
            end
        end
    end
end

part_lap(isnan(part_lap(:,1)),:) = [];
part_lap(:,3) =true;

lap_indices(:,3) = partial_lap_idx;

lap_indices = vertcat(lap_indices, part_lap);

lap_indices = sortrows(lap_indices);


end