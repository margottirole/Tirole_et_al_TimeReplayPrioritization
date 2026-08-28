

function directional_place_fields = calculate_directional_place_fields(x_bins_width,varargin)
% CALCULATES PLACE FIELDS FOR EACH RUN DIRECTION
% INPUTS:
%   x_bin_width: enter width value (2 for fine resolution, 10 for bayesian decoding).
% Loads list_of_parameters.m, extracted_clusters.mat,extracted_directional_clusters.mat, extracted_position.mat, extracted_waveform.mat
% uses function skaggs_information.m
% adapted MT 01/2021
% added save option
% changed how total time in direction is calculated

p = inputParser;
addRequired(p,'x_bins_width',@isnumeric);
addParameter(p,'save',1,@isnumeric);
parse(p,x_bins_width,varargin{:});

parameters = list_of_parameters;
if exist('extracted_directional_clusters.mat')==2
    load('extracted_directional_clusters.mat');
    load('extracted_laps.mat')
else
    load('.\Directional Analysis\extracted_directional_clusters.mat');
    load('.\Directional Analysis\extracted_laps.mat')
end
    
load('extracted_clusters.mat');
load('extracted_position.mat');
if exist('extracted_waveforms.mat','file')
    load('extracted_waveforms.mat');
else
    disp('no extracted_waveforms.mat file');
    allclusters_waveform=[];
end

% Run threshold on pyramidal cells: half-width amplitude
if ~isempty(allclusters_waveform)       
    PC_indices = [allclusters_waveform.half_width] > parameters.half_width_threshold; % cells that pass treshold of pyramidal cell half width
    pyramidal_cells = [allclusters_waveform(PC_indices).converted_ID];
end

%find track positions
alt_track=1;
for track_id=1:length(position.linear)
     for dir = 1 : 2 % for each direction
        directional_place_fields.track(alt_track).time_window_dir= [lap_times(track_id).(['dir' num2str(dir) '_start'])' lap_times(track_id).(['dir' num2str(dir) '_stop'])'];
        directional_place_fields.track(alt_track).track= track_id;
        directional_place_fields.track(alt_track).direction= dir;
        alt_track= alt_track+1;
     end
end

%find mean rate spikes on all tracks / time on all tracks
%(for identifying putative interneurons later in the code)
alt_track=1;
for dir = 1 : 2 % for each direction
    all_spikes = []; 
    for track_id = 1:length(position.linear)   
        total_time_in_track(alt_track) = sum(directional_place_fields.track(alt_track).time_window_dir(:,2)-directional_place_fields.track(alt_track).time_window_dir(:,1));
        total_time_in_track_dir(track_id)= total_time_in_track(alt_track);
        for j = 1 : max(clusters.id_conversion(:,1))
            all_spikes(track_id,j) = length(find(directional_clusters(track_id).(strcat('spikes_dir',num2str(dir)))(:,1)==j));
        end
        directional_place_fields.mean_rate=sum(all_spikes,1)/sum(total_time_in_track_dir);
        alt_track= alt_track+1;
    end
end

%% Place field calculation
time_bin_width=position.t(2)-position.t(1);
alt_track= 1;
for track_id = 1:length(position.linear)
    for dir = 1 : 2 % for each direction
    
    position_index = isnan(position.linear(track_id).linear);
    position_speed = abs(position.v_cm);
    position_speed(position_index) = NaN;  %make sure speed is NaN if position is NaN

    position_during_spike = interp1(position.t,position.linear(track_id).linear,directional_clusters(track_id).(strcat('spikes_dir',num2str(dir)))(:,2),'nearest'); %interpolates position into spike time
    speed_during_spike = interp1(position.t,position_speed,directional_clusters(track_id).(strcat('spikes_dir',num2str(dir)))(:,2),'nearest');

    x_bin_edges = 0:x_bins_width:100*position.linear(track_id).length; % forces x_bins to be from 0 to 200cm
    x_bin_centres = [(x_bin_edges(2)-x_bins_width/2):x_bins_width:(x_bin_edges(end-1)+x_bins_width/2)];
    x_bins = 0:x_bins_width:(100*position.linear(track_id).length); %bin position

    % Time spent at each x_bin (speed filtered)
    pos_dir= [];
    for this_epoch=1:size(directional_place_fields.track(alt_track).time_window_dir,1)
            pos_dir= [pos_dir position.linear(track_id).linear(position.t>directional_place_fields.track(alt_track).time_window_dir(this_epoch,1) &...
             position.t<directional_place_fields.track(alt_track).time_window_dir(this_epoch,2) & position_speed>parameters.speed_threshold_laps...
             & position_speed<parameters.speed_threshold_max)];        
    end
    x_hist = time_bin_width.*histcounts(pos_dir,x_bin_edges); % Changed bin_centre to bin_edges

    directional_place_fields.track(alt_track).x_bin_centres = x_bin_centres;
    directional_place_fields.track(alt_track).x_bin_edges = x_bin_edges;
    directional_place_fields.track(alt_track).x_bins = x_bins;
    directional_place_fields.track(alt_track).x_bins_width = x_bins_width;
    directional_place_fields.track(alt_track).dwell_map = x_hist;

    for j = 1 : max(clusters.id_conversion(:,1))
        
        % Number of spikes per bin within time window (speed filtered)
        directional_place_fields.track(alt_track).spike_hist{j} = histcounts(position_during_spike(find(directional_clusters(track_id).(strcat('spikes_dir',num2str(dir)))(:,1)==j & ...
                                                    speed_during_spike>parameters.speed_threshold_laps &...
                                                    speed_during_spike<parameters.speed_threshold_max)),x_bin_edges); % Changed bin_centre to bin_edges

        directional_place_fields.track(alt_track).raw{j} = directional_place_fields.track(alt_track).spike_hist{j}./x_hist; % place field calculation
        directional_place_fields.track(alt_track).raw{j}(find(isnan(directional_place_fields.track(alt_track).raw{j})==1))=0;
      
        % zero bins with 0 dwell time, but make sure no spikes occurred
        non_visited_bins = find(x_hist==0);
        if sum(directional_place_fields.track(alt_track).spike_hist{j}(non_visited_bins))>0
            disp('ERROR: x_hist is zero, but spike histogram is not');
        else
            directional_place_fields.track(alt_track).raw{j}(non_visited_bins)= 0;
        end
        directional_place_fields.track(alt_track).non_visited_bins = non_visited_bins; %NaNs that have been replaced by O
        
        % Create smoothing filter (gamma)
        if x_bins_width== parameters.x_bins_width_bayesian
            w= [1 1];  %moving average filter of 2 sample, will be become a filter of [0.25 0.5 0.25] with filtfilt
        else
            w= gausswin(parameters.place_field_smoothing);
        end
        w = w./sum(w); %make sure smoothing filter sums to 1
        
        % Get place field information
        directional_place_fields.track(alt_track).smooth{j}         = filtfilt(w,1,directional_place_fields.track(alt_track).raw{j}); %smooth pl field
        directional_place_fields.track(alt_track).centre_of_mass(j) = sum(directional_place_fields.track(alt_track).smooth{j}.*x_bin_centres/sum(directional_place_fields.track(alt_track).smooth{j}));  %averaged center
        [directional_place_fields.track(alt_track).peak(j) , index] = max(directional_place_fields.track(alt_track).smooth{j}); %peak of smoothed place field and index of peak (center)
        if directional_place_fields.track(alt_track).peak(j) ~=0
            if length(index)>1 % very rare exception where you have multiple peaks of same height....
                index= index(1);
            end
            directional_place_fields.track(alt_track).centre(j) = x_bin_centres(index);
            
        else
            directional_place_fields.track(alt_track).centre(j) = NaN;
        end
        directional_place_fields.track(alt_track).raw_peak(j)          = max(directional_place_fields.track(alt_track).raw{j}); % raw pl field peak
        directional_place_fields.track(alt_track).mean_rate_session(j) = length(find(clusters.spike_id==j))/(position.t(end)-position.t(1)); %mean firing rate
        directional_place_fields.track(alt_track).mean_rate_track(j)   = sum(directional_place_fields.track(alt_track).spike_hist{j})/(total_time_in_track(alt_track));
        if directional_place_fields.track(alt_track).peak(j) ~=0
            directional_place_fields.track(alt_track).half_max_width(j) = x_bins_width*half_max_width(directional_place_fields.track(alt_track).smooth{j}); %finds half width of smoothed place field (width from y values closest to 50% of peak)
        else
            directional_place_fields.track(alt_track).half_max_width(j) = NaN;
        end
    end

    %calculate skagges information
    directional_place_fields.track(alt_track).skaggs_info= skaggs_information(directional_place_fields.track(alt_track));
    
    % Find cells that pass the 'Place cell' thresholds -
    % both peak of smoothed place field or peak of raw place field need to be above the respective thresholds
    putative_place_cells = find((directional_place_fields.track(alt_track).peak >= parameters.min_smooth_peak...
        & directional_place_fields.track(alt_track).raw_peak >= parameters.min_raw_peak)...
        & directional_place_fields.mean_rate <= parameters.max_mean_rate...
        & directional_place_fields.track(alt_track).skaggs_info > 0);
    
    % Set a less conservative criteria for place cells, having to pass either peak firing rate thresholds (smoothed PF and raw PF)
    putative_place_cells_LIBERAL = find(directional_place_fields.track(alt_track).peak >= parameters.min_smooth_peak... 
        | directional_place_fields.track(alt_track).raw_peak >= parameters.min_raw_peak...
        & directional_place_fields.mean_rate <= parameters.max_mean_rate...
        & directional_place_fields.track(alt_track).skaggs_info > 0);
    
    if ~isempty(allclusters_waveform)
        directional_place_fields.track(alt_track).good_cells = intersect(putative_place_cells,pyramidal_cells); % Check that the cells that passed the threshold are pyramidal cells
        directional_place_fields.track(alt_track).good_cells_LIBERAL = intersect(putative_place_cells_LIBERAL,pyramidal_cells); % Check that the cells that passed the threshold are pyramidal cells
    else
        directional_place_fields.track(alt_track).good_cells = putative_place_cells;
        directional_place_fields.track(alt_track).good_cells_LIBERAL = putative_place_cells_LIBERAL;            
    end
   
    % Sort place fields according to the location of their peak
    [~,index] = sort(directional_place_fields.track(alt_track).centre);
    directional_place_fields.track(alt_track).sorted = index;
    [~,index1] = sort(directional_place_fields.track(alt_track).centre(directional_place_fields.track(alt_track).good_cells));
    directional_place_fields.track(alt_track).sorted_good_cells = directional_place_fields.track(alt_track).good_cells(index1);
    [~,index2] = sort(directional_place_fields.track(alt_track).centre(directional_place_fields.track(alt_track).good_cells_LIBERAL));
    directional_place_fields.track(alt_track).sorted_good_cells_LIBERAL = directional_place_fields.track(alt_track).good_cells_LIBERAL(index2);
    
    alt_track= alt_track+1;
    end
end
    
%% Classify cells as good place cells, interneuron, pyramidal cells & other cells

 %interneurons classfication
 interneurons = find(directional_place_fields.mean_rate > parameters.max_mean_rate);
 directional_place_fields.interneurons=interneurons;
          
good_place_cells=[]; track=[];
for alt_track=1:length(directional_place_fields.track) %good cells classfication
    good_place_cells = [good_place_cells directional_place_fields.track(alt_track).sorted_good_cells];
    track =[track alt_track*ones(size(directional_place_fields.track(alt_track).sorted_good_cells))];
end
directional_place_fields.good_place_cells = unique(good_place_cells);

good_place_cells_LIBERAL=[];
for alt_track=1:length(directional_place_fields.track) %good cells (liberal threshold) classfication
    good_place_cells_LIBERAL = [good_place_cells_LIBERAL directional_place_fields.track(alt_track).sorted_good_cells_LIBERAL];
end
directional_place_fields.good_place_cells_LIBERAL = unique(good_place_cells_LIBERAL);

% cells that are unique for each track
unique_cells=[];
for alt_track = 1:length(directional_place_fields.track)
    directional_place_fields.track(alt_track).unique_cells = setdiff(good_place_cells(track==alt_track),good_place_cells(track~=alt_track),'stable');
    unique_cells = [unique_cells, directional_place_fields.track(alt_track).unique_cells];
end
directional_place_fields.unique_cells = unique_cells;  % all cells that have good place fields only on a single track

% putative pyramidal cells classification:  pyramidal cells that pass the 'Pyramidal type' threshold (but not need to be place cells)
putative_pyramidal_cells = find(directional_place_fields.mean_rate <= parameters.max_mean_rate);

if ~isempty(allclusters_waveform)
    directional_place_fields.pyramidal_cells = intersect(putative_pyramidal_cells,pyramidal_cells);
else
    directional_place_fields.pyramidal_cells = putative_pyramidal_cells;
end
directional_place_fields.pyramidal_cells=unique(directional_place_fields.pyramidal_cells);

other_cells = setdiff(1:max(clusters.id_conversion(:,1)),good_place_cells,'stable'); %find the excluded putative pyramidal cells
directional_place_fields.other_cells = setdiff(other_cells,interneurons,'stable'); %remove also the interneurons

 %save place fields (different filenames used based on x_bins_width chosen)
if p.Results.save
    if x_bins_width == parameters.x_bins_width_bayesian
        directional_place_fields_BAYESIAN = directional_place_fields;
        save extracted_directional_place_fields_BAYESIAN directional_place_fields_BAYESIAN;
    elseif x_bins_width == parameters.x_bins_width
        save extracted_directional_place_fields directional_place_fields;
    else disp('error: x_bin_width does not match expected value')
    end
end

end
 

function half_width = half_max_width(place_field)
    %interpolate place field to get better resolution
    new_step_size = 0.1;  %decrease value to get finer resolution interpolation of place field
    place_field_resampled = interp1(1:length(place_field),place_field,1:new_step_size:length(place_field),'linear');
    [peak,index] = max(place_field_resampled); %finds smoothed place field peak firing rate (FR)
    for i = index : length(place_field_resampled)
        if place_field_resampled(i)<peak/2 %finds the point after the peak where the FR is half the peak FR
            break;
        end
    end
    for j = index : -1 : 1 %finds the point before the peak where the FR is half the peak FR
        if place_field_resampled(j)<peak/2
            break;
        end
    end
    half_width = new_step_size*(i-j); %distance between half-peaks
    %(calculated in indicies of original place field, but converted to distance in cm in function above)
end
