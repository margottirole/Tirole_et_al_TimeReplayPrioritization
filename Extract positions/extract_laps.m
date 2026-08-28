function extract_laps(varargin)

if isempty(varargin)
    plot_option= 0; % do not plot
else
    plot_option= 1;
end

load extracted_position
parameters=list_of_parameters;

if plot_option
    figure;
end
for track_id=1:length(position.linear)
    
    
x = medfilt1(position.linear(track_id).linear,10);  % smooth position data
t= position.t;

max_pos = max(position.linear(track_id).linear);   % find max and min position
min_pos = min(position.linear(track_id).linear);
% delta   = (max_pos-min_pos)/10;  % segment track length
delta=15;

track_edge_indices = find( x<(min_pos+delta) | x>(max_pos-delta)); % find indices when animal at top or bottom of track
large_jump_indices = find(abs(diff(x(track_edge_indices)))>(5*delta)); % looks for jumps between consecutive indices in j that are larger than 4 delta

lap_times(track_id).start = t(track_edge_indices(large_jump_indices(1:end-1))+1); % lap start time
lap_times(track_id).end  = t(track_edge_indices(large_jump_indices(2:end)));   % lap end time
lap_times(track_id).duration = lap_times(track_id).end  - lap_times(track_id).start; % lap durations

for i=1:length(lap_times(track_id).start)
    % store x and t for lap (includes end zone)
    lap_times(track_id).lap(i).x= x(t>=lap_times(track_id).start(i) & t<=lap_times(track_id).end(i));
    lap_times(track_id).lap(i).t= t(t>=lap_times(track_id).start(i) & t<=lap_times(track_id).end(i));
    lap_times(track_id).lap(i).v_cm= position.v_cm(t>=lap_times(track_id).start(i) & t<=lap_times(track_id).end(i));
    % store direction
    if lap_times(track_id).lap(i).x(end) > lap_times(track_id).lap(i).x(1)
        lap_times(track_id).lap(i).direction= 1;
    elseif lap_times(track_id).lap(i).x(end) < lap_times(track_id).lap(i).x(1)
        lap_times(track_id).lap(i).direction= 2;
    else
        error('extract_laps: no direction found');
    end
    
    % store x and t only for end zone
    lap_times(track_id).end_zone(i).x= lap_times(track_id).lap(i).x(lap_times(track_id).lap(i).x < (min_pos+delta) | lap_times(track_id).lap(i).x > (max_pos-delta));
    lap_times(track_id).end_zone(i).t= lap_times(track_id).lap(i).t(lap_times(track_id).lap(i).x < (min_pos+delta) | lap_times(track_id).lap(i).x > (max_pos-delta));
    lap_times(track_id).end_zone(i).v_cm=  lap_times(track_id).lap(i).v_cm(lap_times(track_id).lap(i).x < (min_pos+delta) | lap_times(track_id).lap(i).x > (max_pos-delta));

    % store x and t in between end zones
    lap_times(track_id).run_zone(i).x= lap_times(track_id).lap(i).x(lap_times(track_id).lap(i).x > (min_pos+delta) & lap_times(track_id).lap(i).x < (max_pos-delta));
    lap_times(track_id).run_zone(i).t= lap_times(track_id).lap(i).t(lap_times(track_id).lap(i).x > (min_pos+delta) & lap_times(track_id).lap(i).x < (max_pos-delta));
    lap_times(track_id).run_zone(i).v_cm=  lap_times(track_id).lap(i).v_cm(lap_times(track_id).lap(i).x > (min_pos+delta) & lap_times(track_id).lap(i).x < (max_pos-delta));

end

lap_times(track_id).total_number_of_laps = length(lap_times(track_id).start);
lap_times(track_id).end_zones_coord= [min_pos min_pos+delta; max_pos-delta max_pos];

if plot_option
    subplot(1,length(position.linear),track_id);
    dir1_idx= [lap_times(track_id).lap.direction] == 1;
    dir2_idx= [lap_times(track_id).lap.direction] == 2;
    plot([lap_times(track_id).lap(dir1_idx).t],[lap_times(track_id).lap(dir1_idx).x],'k.');
    hold on;
    plot([lap_times(track_id).lap(dir2_idx).t],[lap_times(track_id).lap(dir2_idx).x],'r.');
end

end

save('extracted_laps.mat','lap_times');
end