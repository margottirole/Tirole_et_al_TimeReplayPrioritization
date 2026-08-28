function parameters = list_of_parameters(varargin)

parameters.MUA_filter_length= 41; % in samples (ms)
parameters.MUA_filter_alpha= 2;

% for LFP analysis
parameters.theta_filter= [4 12]; % all in Hz
parameters.ripple_filter= [125 300];
parameters.spindle_filter= [9 17]; 
parameters.delta_filter= [1 4];  
parameters.fast_osc_filter= [100 300];
parameters.high_gamma_filter= [40 100]; 
parameters.low_gamma_filter= [17 40];

% for tracking
parameters.max_pixel_distance = 50;
parameters.max_pixel_distance_jump = 40; 
parameters.position_filter_length = 101; 
parameters.speed_filter_length = 25; 
parameters.max_distance_jump = 40;
parameters.max_speed_sleepbox = 100;

% For place field calculation
parameters.speed_threshold = 4; % cm/s
parameters.speed_threshold_laps = 5; % cm/s
parameters.speed_threshold_max = 50; % cm/s
parameters.place_field_smoothing = 10; % multiply by x_bins_width to have cm
parameters.place_field_smoothing_bayesian = 2; % multiply by x_bins_width to have cm
parameters.min_smooth_peak = 0.5; % Hz
parameters.min_raw_peak = 1; % Hz
parameters.max_mean_rate = 5; % Hz
parameters.x_bins_width = 2; % cm
parameters.x_bins_width_bayesian = 10; % cm
parameters.half_width_threshold = 0.0005; %= 50us

% For waveform extraction
parameters.nSamplesForSpike = [-24, 24];
parameters.SR = 30000; %30kHz
parameters.nChannels = 4;

% For CSC extraction
parameters.CSC_filter_length = 15; 

%for replay detection
parameters.min_zscore=0;
parameters.max_zscore=3;
parameters.max_search_length=300; % ms
parameters.min_event_duration=0.1; % in s
parameters.max_event_duration=0.750; % in s
parameters.min_react_duration = 0.05;

% For bayesian decoding
parameters.replay_bin_width = 0.02; %s
parameters.run_bin_width = 0.25; %s
parameters.position_bin_width = 10;
parameters.smoothing_number_of_bins = 5;
parameters.bayesian_threshold = 1e-4;

end 