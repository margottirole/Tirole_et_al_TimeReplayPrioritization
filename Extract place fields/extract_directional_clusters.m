function directional_clusters= extract_directional_clusters(varargin)
% SPLIT CLUSTERS SPIKE TIMES IN DIRECTIONS
% For each extracted cluster, finds spike times occurring during run and splits them in two directions. 
% Creates a new structure where clusters are separated in direction 1 and direction 2.
% added a couple features 01/2021 MT
% can now use direction instead of half laps
% and there is a save option

p = inputParser;
addParameter(p,'method',{''},@ischar);
addParameter(p,'save',1,@isnumeric);
parse(p,varargin{:});

if exist('extracted_laps.mat')==2
    load extracted_laps.mat
    load extracted_clusters.mat
else
    load('.\Directional Analysis\extracted_laps.mat')
    load('extracted_clusters.mat')
end

% Classify half laps in directions: save start and end timestamps in two columns
for t = 1 : length(lap_times)
    if isfield(lap_times,'lap')
        track_halfLaps_times(t).direction_1(:,1) = lap_times(t).start(1:2:end);
        track_halfLaps_times(t).direction_1(:,2) = lap_times(t).end(1:2:end);
        track_halfLaps_times(t).direction_2(:,1) = lap_times(t).start(2:2:end);
        track_halfLaps_times(t).direction_2(:,2) = lap_times(t).end(2:2:end);
    elseif strcmp(p.Results.method,'dir')
        track_halfLaps_times(t).direction_1(:,1) = lap_times(t).dir1_start;
        track_halfLaps_times(t).direction_1(:,2) = lap_times(t).dir1_stop;
        track_halfLaps_times(t).direction_2(:,1) = lap_times(t).dir2_start;
        track_halfLaps_times(t).direction_2(:,2) = lap_times(t).dir2_stop;
    else
        track_halfLaps_times(t).direction_1(:,1) = lap_times(t).halfLaps_start(1:2:end);
        track_halfLaps_times(t).direction_1(:,2) = lap_times(t).halfLaps_stop(1:2:end);
        track_halfLaps_times(t).direction_2(:,1) = lap_times(t).halfLaps_start(2:2:end);
        track_halfLaps_times(t).direction_2(:,2) = lap_times(t).halfLaps_stop(2:2:end);
    end
end

% For each track, divide each cluster timestamps in two, based on direction
units = unique(clusters.spike_id);        
curr_size_1 = zeros(1,length(lap_times));
curr_size_2 = zeros(1,length(lap_times));
for i = 1 : length(units)
    spikes = clusters.spike_times(clusters.spike_id == units(i)); %find spikes of cluster
    for t = 1 : length(lap_times) % for each track
        % Find spikes for direction 1
        for j = 1 : size(track_halfLaps_times(t).direction_1,1)
            idx = discretize(spikes,track_halfLaps_times(t).direction_1(j,:)); %find spikes within each directional half lap
            directional_clusters(t).spikes_dir1(curr_size_1(t)+1:curr_size_1(t)+length(spikes(idx==1)), 2) = spikes(idx == 1);
            directional_clusters(t).spikes_dir1(curr_size_1(t)+1:curr_size_1(t)+length(spikes(idx==1)), 1) = ones(length(spikes(idx == 1)),1)*units(i);
            curr_size_1(t) = size(directional_clusters(t).spikes_dir1,1);
        end
        % Find spikes for direction 2
        for j = 1 : size(track_halfLaps_times(t).direction_2,1)
            idx = discretize(spikes,track_halfLaps_times(t).direction_2(j,:)); %find spikes within each directional half lap
            directional_clusters(t).spikes_dir2(curr_size_2(t)+1:curr_size_2(t)+length(spikes(idx==1)), 2) = spikes(idx == 1);
            directional_clusters(t).spikes_dir2(curr_size_2(t)+1:curr_size_2(t)+length(spikes(idx==1)), 1) = ones(length(spikes(idx == 1)),1)*units(i);
            curr_size_2(t) = size(directional_clusters(t).spikes_dir2,1);
        end
    end
    
end

if p.Results.save
     save extracted_directional_clusters directional_clusters
end


end


