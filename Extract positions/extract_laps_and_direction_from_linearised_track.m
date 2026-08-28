function [lap1, lap2, dir1, dir2] = extract_laps_and_direction_from_linearised_track(linear_position)
% parameters changed and kept end indices for direction MT 01/2021
%
% for laps: returns n_laps x 3 matrix for each running direction
% lap(:,1:2) = start and end indices of laps
% lap(:,3) indicates whether this is a partial lap
%
% for directions returns n_trajectory x 2 matrix of start and end indices of runs in each direction
thresh.smooth_win            = 25;         
thresh.smooth_type           = 'rloess';
thresh.min_trajectory_length = 10;
thresh.min_dir_size          = 0.1; 
thresh.track_segment_length  = 20;
thresh.end_zone_length       = 15;
thresh.min_lap_pc            = 0.25;

thresh.max_pos = max(linear_position);   % find max and min position
thresh.min_pos = min(linear_position);
thresh.range   = thresh.max_pos - thresh.min_pos;
thresh.delta   = thresh.range/thresh.track_segment_length;  % segment track length

thresh.min_lap_dist     = thresh.min_lap_pc * thresh.range; % calc min dist for partial lap
thresh.min_top_range    = [thresh.max_pos-thresh.min_lap_dist-(thresh.delta/2), thresh.max_pos-thresh.min_lap_dist+(thresh.delta/2)];
thresh.min_bottom_range = [thresh.min_lap_dist-(thresh.delta/2) thresh.min_lap_dist+(thresh.delta/2)];

% smooth position
smoothpos =  medfilt1(linear_position,10);

% find locations end of track
top_of_track    = smoothpos > (thresh.max_pos-thresh.end_zone_length);
bottom_of_track = smoothpos < (thresh.min_pos+thresh.end_zone_length);
ends_of_track   = or(top_of_track, bottom_of_track);

% extract direction
[dir1,dir2] = extract_tracking_direction(smoothpos,thresh);

% extract laps
lap1 = extract_unidirectional_laps(smoothpos, top_of_track, bottom_of_track, thresh.min_top_range, thresh.min_bottom_range);
lap2 = extract_unidirectional_laps(smoothpos, bottom_of_track, top_of_track, thresh.min_bottom_range, thresh.min_top_range);

end
