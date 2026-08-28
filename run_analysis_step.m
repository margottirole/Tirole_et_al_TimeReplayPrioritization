function run_analysis_step(option)
parameters= list_of_parameters;

%% EXTRACT POSITIONS FROM VIDEO
if strcmp(option,'EXTRACT_POSITION')  
    % disp('processing position data')
    extract_laps;
end

%% CALCULATE PLACE FIELDS
if strcmp(option,'PLACE_FIELDS')
    disp('processing place_field data')
    calculate_place_fields(parameters.x_bins_width_bayesian);
end

%% CALCULATE DIRECTIONAL PLACE FIELDS
if strcmp(option,'DIRECTIONAL_FIELDS')
    disp('processing directional place_field data')
    calculate_directional_position_fields(parameters.x_bins_width_bayesian);
end

%% EXTRACT SLEEP EPOCHS
if strcmp(option,'SLEEP')
    sleepStager;
end

%% EXTRACT CANDIDATE REPLAY EVENTS
if strcmp(option,'extract bayesian and replay')
    disp('Bayesian and extract replay')
    spike_count([],[],[],'Y');
    bayesian_decoding([],[],'Y');
    extract_replay_events; %finds onset and offset of replay events
end

%% REPLAY SCORING
if strcmp(option,'REPLAY')
    num_shuffles=1000;
    analysis_type=[0 1 0 1];  % line fitting, weighted corr, "pac-man" path finding, spearman 

    disp('processing replay events')
    replay_decoding; %extract and decodes replay events
    
    % SCORING METHODS: TEST SIGNIFICANCE ON REPLAY EVENTS
    disp('scoring replay events')
    scored_replay = replay_scoring([],analysis_type); 
    save scored_replay scored_replay;
    
    % RUN SHUFFLES
    disp('running shuffles')
    
    load decoded_replay_events
    p = gcp; % Starting new parallel pool
    shuffle_choice={'PRE spike_train_circular_shift','PRE place_field_circular_shift', 'POST place bin circular shift'};
    tic
    if ~isempty(p)
        for shuffle_id=1:length(shuffle_choice)
            shuffle_type{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events);
        end
    else
        disp('parallel processing not possible');
        for shuffle_id=1:length(shuffle_choice)
            shuffle_type{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events);
        end
    end
    save shuffled_tracks shuffle_type;
    disp('time to run shuffles was...');
    toc
    
    % Evaluate significance
    load('scored_replay.mat');
    load('shuffled_tracks.mat');
    scored_replay= replay_significance(scored_replay, shuffle_type);
    save scored_replay scored_replay
    
    %%%%%%analyze segments%%%%%%%%%%
    % splitting replay events
    tic
    replay_decoding_split_events;
    load decoded_replay_events_segments;
    scored_replay1 = replay_scoring(decoded_replay_events1,analysis_type);
    scored_replay2 = replay_scoring(decoded_replay_events2,analysis_type);
    save scored_replay_segments scored_replay1 scored_replay2;
    
    load decoded_replay_events_segments;
    p = gcp; % get parallel pool
    if ~isempty(p)
        for shuffle_id=1:length(shuffle_choice)
            shuffle_type1{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events1);
            shuffle_type2{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events2);
        end
    else
        disp('parallel processing not possible');
        for shuffle_id=1:length(shuffle_choice)
            shuffle_type1{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events1);
            shuffle_type2{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events2);
        end
    end
    
    save shuffled_tracks_segments shuffle_type1 shuffle_type2;
    
    load scored_replay_segments; load shuffled_tracks_segments;
    scored_replay1=replay_significance(scored_replay1, shuffle_type1);
    scored_replay2=replay_significance(scored_replay2, shuffle_type2);
    save scored_replay_segments scored_replay1 scored_replay2
    disp('running segments took...')
    toc
    
end

if strcmp(option,'SHUFFLES') % SHUFFLES & SCORING ONLY
        num_shuffles=1000;
        analysis_type=[0 1 0 1];

        disp('scoring replay events')
        load('decoded_replay_events.mat');
        scored_replay = replay_scoring(decoded_replay_events,analysis_type); % weighted corr  
        save scored_replay scored_replay;

        % RUN SHUFFLES
        tic;
        disp('running shuffles')
        p = gcp; % Starting new parallel pool
        shuffle_choice={'PRE spike_train_circular_shift','PRE place_field_circular_shift', 'POST place bin circular shift'};
        tic
        if ~isempty(p)
            for shuffle_id=1:length(shuffle_choice)
                shuffle_type{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events);
            end
        else
            disp('parallel processing not possible');
            for shuffle_id=1:length(shuffle_choice)
                shuffle_type{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events);
            end
        end
        save shuffled_tracks shuffle_type;
        disp('time to run shuffles was...');
        toc
        % Evaluate significance
        load('scored_replay.mat');
        load('shuffled_tracks.mat');
        scored_replay= replay_significance(scored_replay, shuffle_type);
        save scored_replay scored_replay

        %%%%%%analyze segments%%%%%%%%%%
        % splitting replay events
        tic
        replay_decoding_split_events('replay_rate_shuffle');
        load decoded_replay_events_segments;
        scored_replay1 = replay_scoring(decoded_replay_events1,analysis_type);
        scored_replay2 = replay_scoring(decoded_replay_events2,analysis_type);
        save scored_replay_segments scored_replay1 scored_replay2;

        load decoded_replay_events_segments;
        p = gcp; % get parallel pool
        if ~isempty(p)
            for shuffle_id=1:length(shuffle_choice)
                shuffle_type1{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events1);
                shuffle_type2{shuffle_id}.shuffled_track = parallel_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events2);
            end
        else
            disp('parallel processing not possible');
            for shuffle_id=1:length(shuffle_choice)
                shuffle_type1{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events1);
                shuffle_type2{shuffle_id}.shuffled_track = run_shuffles(shuffle_choice{shuffle_id},analysis_type,num_shuffles,decoded_replay_events2);
            end
        end

        save shuffled_tracks_segments shuffle_type1 shuffle_type2;

        load scored_replay_segments; load shuffled_tracks_segments;
        scored_replay1=replay_significance(scored_replay1, shuffle_type1);
        scored_replay2=replay_significance(scored_replay2, shuffle_type2);
        save scored_replay_segments scored_replay1 scored_replay2
        disp('running segments took...')
        toc
end

%% SORT REPLAY
if strcmp(option,'SORT_EVENTS')
    % analyze significant replays from whole events and segmented events
    % only using replay events passing threshold for ripple power
    number_of_significant_replays(0.05,3,'wcorr',[]); % pval, ripple zscore, method, reexposure
    sort_replay_events([],'wcorr'); 
    sort_all_candidate_events('wcorr'); % sort candidate events by epoch as well
end

end