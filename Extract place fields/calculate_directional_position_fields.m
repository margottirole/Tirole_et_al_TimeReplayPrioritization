function calculate_directional_position_fields(x_bins_width)

    parameters = list_of_parameters;
    
    % Get directional fields
    % extract direction based on velocity
    load('extracted_position.mat');
    for this_track=1:length(position.linear)
        [lap1, lap2, dir1, dir2] = extract_laps_and_direction_from_linearised_track(position.linear(this_track).linear);
        laps= [lap1; lap2];
        Lap_IDs= [ones(size(lap1,1),1); 2*ones(size(lap2,1),1)];
        [~,I]= sort(laps(:,1));
        laps= laps(I,:);

        lap_times(this_track).halfLaps_start= position.t(laps(:,1));
        lap_times(this_track).halfLaps_stop= position.t(laps(:,2));
        lap_times(this_track).is_halfLap_partial= laps(:,3);
        lap_times(this_track).halfLaps_dir= Lap_IDs(I);
        lap_times(this_track).dir1_start= position.t(dir1(:,1));
        lap_times(this_track).dir1_stop= position.t(dir1(:,2));
        lap_times(this_track).dir2_start= position.t(dir2(:,1));
        lap_times(this_track).dir2_stop= position.t(dir2(:,2));
    end
    if ~exist('Directional Analysis','dir')
        mkdir('Directional Analysis')
    end
    save('.\Directional Analysis\extracted_laps.mat','lap_times');
    
    % extract directional clusters
    directional_clusters= extract_directional_clusters('method','dir','save',0);
    % calculate directional place fields
    place_fields= calculate_directional_place_fields(x_bins_width,'save',0);
    
    if x_bins_width== parameters.x_bins_width_bayesian
        place_fields_BAYESIAN=place_fields;
        save('.\Directional Analysis\extracted_place_fields_BAYESIAN.mat','place_fields_BAYESIAN');
    elseif x_bins_width== parameters.x_bins_width
        save('.\Directional Analysis\extracted_place_fields.mat','place_fields');
    end
    
    copyfile('extracted_replay_events.mat','.\Directional Analysis\');
    copyfile('extracted_clusters.mat','.\Directional Analysis\');
    copyfile('extracted_position.mat','.\Directional Analysis\');
    copyfile('extracted_sleep_state_REM_NREM.mat','.\Directional Analysis\');
    
    % create a position .mat with nx2 directions tracks
    load('.\Directional Analysis\extracted_position.mat');
    load('.\Directional Analysis\extracted_laps.mat');
    position_tmp= position;
    position_tmp.linear= [];
    this_track= 1;
    for track_id=1:length(position.linear)
        for this_dir=1:2
            position_tmp.linear(this_track).track= track_id;
            position_tmp.linear(this_track).direction= this_dir;
            position_tmp.linear(this_track).linear= NaN(size(position.linear(track_id).linear));
            all_idx= position.t <0;
            for this_epoch=1:length(lap_times(track_id).(['dir' num2str(this_dir) '_start']))
                idx= position.t >= lap_times(track_id).(['dir' num2str(this_dir) '_start'])(this_epoch) & position.t <= lap_times(track_id).(['dir' num2str(this_dir) '_stop'])(this_epoch);
                position_tmp.linear(this_track).linear(idx)= position.linear(track_id).linear(idx);
                all_idx= [all_idx | idx];
            end
            position_tmp.linear(this_track).timestamps= position.t(all_idx);
            this_track= this_track+1;
        end
    end
    position= position_tmp;
    save('.\Directional Analysis\extracted_position.mat','position');
end