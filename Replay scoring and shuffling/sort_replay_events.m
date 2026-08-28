function [sorted_replay,time_range]=sort_replay_events(option,varargin)
% option is [] if no reexposure, and a vector for reexposures, e.g. [ 1 3 ; 2 4 ]
% varargin can be 'wcorr' , 'spearman', 'linear' or 'control_fixed_rate'

parameters= list_of_parameters;
if isempty(varargin)
    load significant_replay_events;
elseif ~isempty(varargin) && ~ischar(varargin{1})
    significant_replay_events= varargin{1};
else
    switch varargin{1}
        case 'wcorr'
            if exist('significant_replay_events_wcorr.mat')==2
                load significant_replay_events_wcorr
            elseif exist('significant_replay_events_wcorr_individual_exposures.mat')==2
                load significant_replay_events_wcorr_individual_exposures
            else
                disp('wcorr not found, loading default')
                load significant_replay_events;
            end
        case 'spearman'
            if exist('significant_replay_events_spearman.mat')==2
                load significant_replay_events_spearman
            elseif exist('significant_replay_events_spearman_individual_events.mat')==2
                load significant_replay_events_spearman_individual_events
            else
                disp('spearman not found, loading default')
                load significant_replay_events;
            end
        case 'linear'
            if exist('significant_replay_events_linear.mat')==2
                load significant_replay_events_linear
            elseif exist('significant_replay_events_linear_individual_events.mat')==2
                load significant_replay_events_linear_individual_events
            else
                disp('linear not found, loading default')
                load significant_replay_events;
            end
        case 'control_fixed_rate'
            if exist('significant_replay_events_wcorr_FIXED.mat')==2
                load significant_replay_events_wcorr_FIXED
            elseif exist('significant_replay_events_wcorr_individual_exposures_FIXED.mat')==2
                load significant_replay_events_wcorr_individual_exposures_FIXED
            else
                disp('wcorr not found, loading default')
                load significant_replay_events_wcorr;
            end
        case 'reactivations'
            if exist('significant_reactivations.mat')==2
                load significant_reactivations
                significant_replay_events= reactivation_events; 
            elseif exist('significant_reactivations_individual_exposures.mat')==2
                load significant_reactivations_individual_exposures
                significant_replay_events= reactivation_events; 
            else
                disp('reactivations not found');
                keyboard
            end
        otherwise
                disp('did not recognise input, loading default');
                load significant_replay_events;
    end
end
if contains(pwd,'Directional Analysis')
    load('..\extracted_position.mat'); % load from non directional analysis
else
    load extracted_position
end
if exist('extracted_sleep_state_REM_NREM.mat','file')
    sleep_state_NREM= load('extracted_sleep_state_REM_NREM.mat');
end


% tracks
number_of_tracks=length(position.linear);
v_cm = smooth(position.v_cm,25*1+1);  %1 second smoothing
low_speed_idx= NaN(size(position.t));

low_speed_idx(v_cm < parameters.speed_threshold_laps)= -1;
low_speed_idx(isnan(low_speed_idx))= 1;
starts= position.t(find((diff(low_speed_idx)) < -1)+1);
stops= position.t(find((diff(low_speed_idx)) > 1));    
    
if low_speed_idx(1) == -1
    starts= [position.t(1) starts]; % start
end
if low_speed_idx(end) == -1
    stops= [stops position.t(end)];
end
low_speed_epochs(:,1)= starts;
low_speed_epochs(:,2)= stops;

for track=1:number_of_tracks

        time_range.track(track,:)=[min(position.linear(track).timestamps) max(position.linear(track).timestamps)];  

        % find periods of reduced speed
	    index= (low_speed_epochs(:,1) < time_range.track(track,2) & low_speed_epochs(:,2) >= time_range.track(track,1));
        time_range.immobilityTRACK(track).track= low_speed_epochs(index,:);
       
        %adjust for time when animal is taken off the track
        time_range.immobilityTRACK(track).track(time_range.immobilityTRACK(track).track > time_range.track(track,2))= time_range.track(track,2);
        %adjust for time when animal is put on the track
        time_range.immobilityTRACK(track).track(time_range.immobilityTRACK(track).track < time_range.track(track,1))= time_range.track(track,1);  
        
        repeat_indices= find(time_range.immobilityTRACK(track).track(:,1)== time_range.immobilityTRACK(track).track(:,2));
        time_range.immobilityTRACK(track).track(repeat_indices,:)=[];
   
end

% pre / post
time_range.pre=[min(position.t) time_range.track(1,1)];
if isempty(option)  %NO REXPOSURE
    time_range.post=[time_range.track(length(position.linear),2) max(position.t)];
else %assumes two tracks
    time_range.post=[time_range.track(2,2) time_range.track(3,1)];  %when track 2 is finished till the rexposure of track 1 (labelled as 3)
end
index= (low_speed_epochs(:,1) < time_range.post(2) & low_speed_epochs(:,2) >= time_range.post(1));
time_range.immobilityPOST= low_speed_epochs(index,:);

% rest periods between mazes
this_track=1;
if length(position.linear) ==3
    for this_rest=1:length(position.linear)-1
        timestamps= position.sleepbox(position.sleepbox >= max(position.linear(this_track).timestamps) & position.sleepbox <= min(position.linear(this_track+1).timestamps)); 
        time_range.rest(this_rest,:)=[min(timestamps) max(timestamps)];
        this_track=this_track+1;
    end
elseif length(position.linear) ==6 % directional analysis on 3 mazes data
    ts= position.sleepbox(position.sleepbox >= max(position.linear(2).timestamps) & position.sleepbox <= min(position.linear(3).timestamps)); 
    time_range.rest(1,:)= [min(ts) max(ts)];
    ts= position.sleepbox(position.sleepbox >= max(position.linear(4).timestamps) & position.sleepbox <= min(position.linear(5).timestamps)); 
    time_range.rest(2,:)= [min(ts) max(ts)];
elseif length(position.linear)==2
    timestamps= position.sleepbox(position.sleepbox >= max(position.linear(this_track).timestamps) & position.sleepbox <= min(position.linear(this_track+1).timestamps)); 
    time_range.rest(1,:)= [min(timestamps) max(timestamps)];
end


sleep_start=position.t(sleep_state.sleep_indices.start);
sleep_stop=position.t(sleep_state.sleep_indices.stop);

% wake == 0 (state_0), quiet==1 (state_1), NREM==2 (state_2), REM==3 (state_3)
% define quiet as quiet+REM+NREM
% but trust mainly for PRE and POST, not so much rest
quiet_start= sort([sleep_state_NREM.sleep_state.state_indices.state_1(:,1);...
                sleep_state_NREM.sleep_state.state_indices.state_2(:,1);...
                sleep_state_NREM.sleep_state.state_indices.state_3(:,1)]);
quiet_stop= sort([sleep_state_NREM.sleep_state.state_indices.state_1(:,2);...
                sleep_state_NREM.sleep_state.state_indices.state_2(:,2);...
                sleep_state_NREM.sleep_state.state_indices.state_3(:,2)]);
quietOnly_start= sleep_state_NREM.sleep_state.state_indices.state_1(:,1);
quietOnly_stop= sleep_state_NREM.sleep_state.state_indices.state_1(:,2);
NREM_start= sleep_state_NREM.sleep_state.state_indices.state_2(:,1);
NREM_stop= sleep_state_NREM.sleep_state.state_indices.state_2(:,2);
REM_start= sleep_state_NREM.sleep_state.state_indices.state_3(:,1);
REM_stop= sleep_state_NREM.sleep_state.state_indices.state_3(:,2);

% remove any detected during rest - replace by any sleep_start/sleep_stop:
% higher confidence
quietRest= [quiet_start quiet_stop];
index= [quietRest(:,1)> time_range.pre(2) & quietRest(:,1) < time_range.post(1), quietRest(:,2)> time_range.pre(2) & quietRest(:,2) < time_range.post(1)];
to_rem= sum(index,2);
to_change= find(to_rem==1);
for ii=1:length(to_change)
    if index(to_change(ii),1)==1 % start before post
        quietRest(to_change(ii),1)= time_range.post(1);
    else
        quietRest(to_change(ii),2)= time_range.pre(2);
    end
end
quiet_start(to_rem==2,:)=[];
quiet_stop(to_rem==2,:)=[];


quietOnly= [quietOnly_start quietOnly_stop];
index= [quietOnly(:,1)> time_range.pre(2) & quietOnly(:,1) < time_range.post(1), quietOnly(:,2)> time_range.pre(2) & quietOnly(:,2) < time_range.post(1)];
to_rem= sum(index,2);
to_change= find(to_rem==1);
for ii=1:length(to_change)
    if index(to_change(ii),1)==1 % start before post
        quietOnly(to_change(ii),1)= time_range.post(1);
    else
        quietOnly(to_change(ii),2)= time_range.pre(2);
    end
end
quietOnly(to_rem==2,:)=[];
quietOnly(to_rem==2,:)=[];

NREM= [NREM_start NREM_stop];
index= [NREM(:,1)> time_range.pre(2) & NREM(:,1) < time_range.post(1), NREM(:,2)> time_range.pre(2) & NREM(:,2) < time_range.post(1)];
to_rem= sum(index,2);
to_change= find(to_rem==1);
for ii=1:length(to_change)
    if index(to_change(ii),1)==1 % start before post
        NREM(to_change(ii),1)= time_range.post(1);
    else
        NREM(to_change(ii),2)= time_range.pre(2);
    end
end
NREM(to_rem==2,:)=[];
NREM(to_rem==2,:)=[];

REM= [REM_start REM_stop];
index= [REM(:,1)> time_range.pre(2) & REM(:,1) < time_range.post(1), REM(:,2)> time_range.pre(2) & REM(:,2) < time_range.post(1)];
to_rem= sum(index,2);
to_change= find(to_rem==1);
for ii=1:length(to_change)
    if index(to_change(ii),1)==1 % start before post
        REM(to_change(ii),1)= time_range.post(1);
    else
        REM(to_change(ii),2)= time_range.pre(2);
    end
end
REM(to_rem==2,:)=[];
REM(to_rem==2,:)=[];

% fill in any detected through older version
quietRest= sortrows([quietRest; [sleep_start(sleep_start>= time_range.pre(2) & sleep_start <= time_range.post(1))' sleep_stop(sleep_stop>= time_range.pre(2) & sleep_stop <= time_range.post(1))']]);


% now store
time_range.sleep=[sleep_start;sleep_stop]';
time_range.quietRest= quietRest;
time_range.awake=[time_range.pre(1) sleep_stop; sleep_start max(position.t)]';
time_range.awakeNotQuietRest=[[time_range.pre(1); quietRest(:,2)], [quietRest(:,1); max(position.t)]];

time_range.NREM= NREM;
time_range.REM= REM;
time_range.quietOnly= quietOnly;

total_time_asleep=sum(time_range.sleep(:,2)-time_range.sleep(:,1))/60
total_time_awake=sum(time_range.awake(:,2)-time_range.awake(:,1))/60

total_time_quietRest=sum(time_range.quietRest(:,2)-time_range.quietRest(:,1))/60
total_time_awakeNotQuietRest=sum(time_range.awakeNotQuietRest(:,2)-time_range.awakeNotQuietRest(:,1))/60

% find sleep/wake during PRE
index=find(time_range.sleep(:,1)< time_range.pre(2) & time_range.sleep(:,2)> time_range.pre(1));
time_range.sleepPRE= time_range.sleep(index,:);
index=find(time_range.awake(:,1)< time_range.pre(2) & time_range.awake(:,2)> time_range.pre(1));
time_range.awakePRE= time_range.awake(index,:);
%adjust for final time when animal is put on track
time_range.awakePRE(time_range.awakePRE > time_range.pre(2))=time_range.pre(2);
time_range.sleepPRE(time_range.sleepPRE > time_range.pre(2))=time_range.pre(2);
% redo for other states
% quiet rest
index=find(time_range.quietRest(:,1)< time_range.pre(2) & time_range.quietRest(:,2)> time_range.pre(1));
time_range.quietRestPRE= time_range.quietRest(index,:);
index=find(time_range.awakeNotQuietRest(:,1)< time_range.pre(2) & time_range.awakeNotQuietRest(:,2)> time_range.pre(1));
time_range.awakeNotQuietRestPRE= time_range.awakeNotQuietRest(index,:);
% NREM
index=find(time_range.NREM(:,1)< time_range.pre(2) & time_range.NREM(:,2)> time_range.pre(1));
time_range.NREM_PRE= time_range.NREM(index,:);
% REM
index=find(time_range.REM(:,1)< time_range.pre(2) & time_range.REM(:,2)> time_range.pre(1));
time_range.REM_PRE= time_range.REM(index,:);
% quiet only
index=find(time_range.quietOnly(:,1)< time_range.pre(2) & time_range.quietOnly(:,2)> time_range.pre(1));
time_range.quietOnly_PRE= time_range.quietOnly(index,:);
% adjust for final time when animal is put on track
time_range.awakeNotQuietRestPRE(time_range.awakeNotQuietRestPRE > time_range.pre(2))=time_range.pre(2);
time_range.quietRestPRE(time_range.quietRestPRE > time_range.pre(2))=time_range.pre(2);
time_range.NREM_PRE(time_range.NREM_PRE > time_range.pre(2))=time_range.pre(2);
time_range.REM_PRE(time_range.REM_PRE > time_range.pre(2))=time_range.pre(2);

% find sleep/wake during POST
index=find(time_range.sleep(:,1)< time_range.post(2) & time_range.sleep(:,2)> time_range.post(1));
time_range.sleepPOST=time_range.sleep(index,:);
index=find(time_range.awake(:,1)< time_range.post(2) & time_range.awake(:,2)> time_range.post(1));
time_range.awakePOST=time_range.awake(index,:);
% redo for other states
% quiet rest
index=find(time_range.quietRest(:,1)< time_range.post(2) & time_range.quietRest(:,2)> time_range.post(1));
time_range.quietRestPOST= time_range.quietRest(index,:);
index=find(time_range.awakeNotQuietRest(:,1)< time_range.post(2) & time_range.awakeNotQuietRest(:,2)> time_range.post(1));
time_range.awakeNotQuietRestPOST= time_range.awakeNotQuietRest(index,:);
% NREM
index=find(time_range.NREM(:,1)< time_range.post(2) & time_range.NREM(:,2)> time_range.post(1));
time_range.NREM_POST= time_range.NREM(index,:);
% REM
index=find(time_range.REM(:,1)< time_range.post(2) & time_range.REM(:,2)> time_range.post(1));
time_range.REM_POST= time_range.REM(index,:);
% quiet only
index=find(time_range.quietOnly(:,1)< time_range.post(2) & time_range.quietOnly(:,2)> time_range.post(1));
time_range.quietOnly_POST= time_range.quietOnly(index,:);

%add first awake time when animal is taken off track
time_range.awakePOST(time_range.awakePOST<time_range.post(1))=time_range.post(1);
time_range.sleepPOST(time_range.sleepPOST<time_range.post(1))=time_range.post(1);
time_range.awakePOST(time_range.awakePOST>time_range.post(2))=time_range.post(2);
time_range.sleepPOST(time_range.sleepPOST>time_range.post(2))=time_range.post(2);
% other states
time_range.quietRestPOST(time_range.quietRestPOST<time_range.post(1))=time_range.post(1);
time_range.awakeNotQuietRestPOST(time_range.awakeNotQuietRestPOST<time_range.post(1))=time_range.post(1);
time_range.NREM_POST(time_range.NREM_POST<time_range.post(1))=time_range.post(1);
time_range.REM_POST(time_range.REM_POST<time_range.post(1))=time_range.post(1);
time_range.quietOnly_POST(time_range.quietOnly_POST<time_range.post(1))=time_range.post(1);
time_range.quietRestPOST(time_range.quietRestPOST>time_range.post(2))=time_range.post(2);
time_range.awakeNotQuietRestPOST(time_range.awakeNotQuietRestPOST>time_range.post(2))=time_range.post(2);
time_range.NREM_POST(time_range.NREM_POST>time_range.post(2))=time_range.post(2);
time_range.REM_POST(time_range.REM_POST>time_range.post(2))=time_range.post(2);
time_range.quietOnly_POST(time_range.quietOnly_POST>time_range.post(2))=time_range.post(2);

% find sleep/wake during rests
for this_rest= 1:size(time_range.rest,1)
    % immobility
    index= (low_speed_epochs(:,1) < time_range.rest(this_rest,2) & low_speed_epochs(:,2) >= time_range.rest(this_rest,1));
    time_range.immobilityREST(this_rest).rest=  low_speed_epochs(index,:);
    % sleep
    index= (time_range.sleep(:,1) < time_range.rest(this_rest,2) & time_range.sleep(:,2)>=time_range.rest(this_rest,1));
    time_range.sleepREST(this_rest).rest= time_range.sleep(index,:);
    % wake
    index= (time_range.awake(:,1) < time_range.rest(this_rest,2) & time_range.awake(:,2)>=time_range.rest(this_rest,1));
    time_range.awakeREST(this_rest).rest= time_range.awake(index,:);
        %adjust for time when animal is put on track
    time_range.sleepREST(this_rest).rest(time_range.sleepREST(this_rest).rest > time_range.rest(this_rest,2))= time_range.rest(this_rest,2);
    time_range.awakeREST(this_rest).rest(time_range.awakeREST(this_rest).rest > time_range.rest(this_rest,2))= time_range.rest(this_rest,2);
    time_range.immobilityREST(this_rest).rest(time_range.immobilityREST(this_rest).rest > time_range.rest(this_rest,2))= time_range.rest(this_rest,2);
    time_range.sleepREST(this_rest).rest(time_range.sleepREST(this_rest).rest < time_range.rest(this_rest,1))= time_range.rest(this_rest,1);
    time_range.awakeREST(this_rest).rest(time_range.awakeREST(this_rest).rest < time_range.rest(this_rest,1))= time_range.rest(this_rest,1);
    time_range.immobilityREST(this_rest).rest(time_range.immobilityREST(this_rest).rest < time_range.rest(this_rest,1))= time_range.rest(this_rest,1);
end
    
% calculate cumulative time
time_range.awakePRE_CUMULATIVE=compute_cumulative_time(time_range.awakePRE);
time_range.sleepPRE_CUMULATIVE=compute_cumulative_time(time_range.sleepPRE);
time_range.awakePOST_CUMULATIVE=compute_cumulative_time(time_range.awakePOST);
time_range.sleepPOST_CUMULATIVE=compute_cumulative_time(time_range.sleepPOST);
% other states
time_range.awakeNotQuietRestPRE_CUMULATIVE=compute_cumulative_time(time_range.awakeNotQuietRestPRE);
time_range.quietRestPRE_CUMULATIVE=compute_cumulative_time(time_range.quietRestPRE);
time_range.NREM_PRE_CUMULATIVE=compute_cumulative_time(time_range.NREM_PRE);
time_range.REM_PRE_CUMULATIVE=compute_cumulative_time(time_range.REM_PRE);

time_range.awakeNotQuietRestPOST_CUMULATIVE=compute_cumulative_time(time_range.awakeNotQuietRestPOST);
time_range.quietRestPOST_CUMULATIVE=compute_cumulative_time(time_range.quietRestPOST);
time_range.NREM_POST_CUMULATIVE=compute_cumulative_time(time_range.NREM_POST);
time_range.REM_POST_CUMULATIVE=compute_cumulative_time(time_range.REM_POST);
for this_rest= 1:size(time_range.rest,1)
    time_range.awakeREST_CUMULATIVE(this_rest).rest=compute_cumulative_time(time_range.awakeREST(this_rest).rest);
    time_range.sleepREST_CUMULATIVE(this_rest).rest=compute_cumulative_time(time_range.sleepREST(this_rest).rest);
    % includes awake and rest
    time_range.REST_CUMULATIVE(this_rest).rest= compute_cumulative_time(time_range.rest(this_rest,:));
    %immobility
    time_range.immobilityREST_CUMULATIVE(this_rest).rest= compute_cumulative_time(time_range.immobilityREST(this_rest).rest);
end
for this_track= 1:number_of_tracks
    time_range.track_CUMULATIVE(this_track).behaviour= compute_cumulative_time(time_range.track(this_track,:));
    time_range.immobilityTRACK_CUMULATIVE(this_track).behaviour= compute_cumulative_time(time_range.immobilityTRACK(this_track).track);
end

% initialise variables
for track=1:number_of_tracks
    for j=1:number_of_tracks
        sorted_replay(track).index.track(j).behaviour=[];
        sorted_replay(track).index.immobilityTRACK(j).behaviour=[];
        sorted_replay(track).ref_index.track(j).behaviour=[];
        sorted_replay(track).ref_index.immobilityTRACK(j).behaviour=[];
        sorted_replay(track).event_time.track(j).behaviour= [];
        sorted_replay(track).event_time.immobilityTRACK(j).behaviour= [];
        sorted_replay(track).bayesian_bias.track(j).bias= [];
        sorted_replay(track).bayesian_bias.immobilityTRACK(j).bias= [];
        sorted_replay(track).replay_score.track(j).score= [];
        sorted_replay(track).replay_score.immobilityTRACK(j).score= [];
        sorted_replay(track).FR_events.track(j).FR= [];
        sorted_replay(track).FR_events.immobilityTRACK(j).FR= [];

        % add linear slope
        sorted_replay(track).linear_slope.track(j).linear_slope=[];
        sorted_replay(track).linear_slope.immobilityTRACK(j).linear_slope=[];

        % add directionality (forward/reverse)
        sorted_replay(track).direction.track(j).direction=[];
        sorted_replay(track).direction.immobilityTRACK(j).direction=[];
        sorted_replay(track).forward_reverse.track(j).forward_reverse=[];
        sorted_replay(track).forward_reverse.immobilityTRACK(j).forward_reverse=[];

        % posterior spread
        sorted_replay(track).posterior_spread.track(j).posterior_spread=[];
        sorted_replay(track).posterior_spread.immobilityTRACK(j).posterior_spread=[];

        
    end

    var= {'awakeNotQuietRestPRE','quietRestPRE','NREM_PRE','REM_PRE','pre','quietOnly_PRE'...
        'awakeNotQuietRestPOST','quietRestPOST','NREM_POST','REM_POST','post','quietOnly_POST'};
    for thisc=1:length(var)
        sorted_replay(track).index.(var{thisc})=[];
        sorted_replay(track).ref_index.(var{thisc})=[];
        sorted_replay(track).event_time.(var{thisc})=[];

        sorted_replay(track).bayesian_bias.(var{thisc})=[];
        sorted_replay(track).replay_score.(var{thisc})=[];
        sorted_replay(track).FR_events.(var{thisc})=[];
        sorted_replay(track).linear_slope.(var{thisc})=[];
        sorted_replay(track).posterior_spread.(var{thisc})=[];

        sorted_replay(track).forward_reverse.(var{thisc})=[];
        sorted_replay(track).direction.(var{thisc})=[];
    end
    
    sorted_replay(track).index.awakePRE=[];
    sorted_replay(track).index.sleepPRE=[];
    sorted_replay(track).index.awakePOST=[];
    sorted_replay(track).index.sleepPOST=[];   
    sorted_replay(track).index.immobilityPOST=[];
    
    sorted_replay(track).ref_index.awakePRE=[];
    sorted_replay(track).ref_index.sleepPRE=[];
    sorted_replay(track).ref_index.awakePOST=[];
    sorted_replay(track).ref_index.sleepPOST=[];
    
    sorted_replay(track).event_time.awakePRE=[];
    sorted_replay(track).event_time.sleepPRE=[];
    sorted_replay(track).event_time.awakePOST=[];
    sorted_replay(track).event_time.sleepPOST=[];
    sorted_replay(track).event_time.immobilityPOST=[];
    
    sorted_replay(track).bayesian_bias.awakePRE= [];
    sorted_replay(track).replay_score.awakePRE= [];
    sorted_replay(track).FR_events.awakePRE= [];
    
    sorted_replay(track).bayesian_bias.sleepPRE= [];
    sorted_replay(track).replay_score.sleepPRE= [];
    sorted_replay(track).FR_events.sleepPRE= [];
    
    sorted_replay(track).bayesian_bias.awakePOST= [];
    sorted_replay(track).replay_score.awakePOST= [];
    sorted_replay(track).FR_events.awakePOST= [];
    
    sorted_replay(track).bayesian_bias.sleepPOST= [];
    sorted_replay(track).replay_score.sleepPOST= [];
    sorted_replay(track).FR_events.sleepPOST= [];

    % add linear slope
    sorted_replay(track).linear_slope.awakePRE=[];
    sorted_replay(track).linear_slope.sleepPRE=[];
    sorted_replay(track).linear_slope.awakePOST=[];
    sorted_replay(track).linear_slope.sleepPOST=[];

    % add forward reverse
    sorted_replay(track).direction.awakePRE=[];
    sorted_replay(track).direction.sleepPRE=[];
    sorted_replay(track).direction.awakePOST=[];
    sorted_replay(track).direction.sleepPOST=[];

    sorted_replay(track).forward_reverse.awakePRE=[];
    sorted_replay(track).forward_reverse.sleepPRE=[];
    sorted_replay(track).forward_reverse.awakePOST=[];
    sorted_replay(track).forward_reverse.sleepPOST=[];

    % posterior spread
    sorted_replay(track).posterior_spread.awakePRE=[];
    sorted_replay(track).posterior_spread.sleepPRE=[];
    sorted_replay(track).posterior_spread.awakePOST=[];
    sorted_replay(track).posterior_spread.sleepPOST=[];
    
    
    for this_rest= 1:size(time_range.rest,1)
        sorted_replay(track).index.awakeREST(this_rest).rest=[];
        sorted_replay(track).index.sleepREST(this_rest).rest=[];
        sorted_replay(track).index.REST(this_rest).rest=[];
        sorted_replay(track).index.immobilityREST(this_rest).rest=[];
        
        sorted_replay(track).ref_index.awakeREST(this_rest).rest=[];
        sorted_replay(track).ref_index.sleepREST(this_rest).rest=[];
        sorted_replay(track).ref_index.REST(this_rest).rest=[];
        sorted_replay(track).ref_index.immobilityREST(this_rest).rest=[];
        
        sorted_replay(track).event_time.awakeREST(this_rest).rest=[];
        sorted_replay(track).event_time.sleepREST(this_rest).rest=[];
        sorted_replay(track).event_time.REST(this_rest).rest=[];
        sorted_replay(track).event_time.immobilityREST(this_rest).rest=[];
        
        sorted_replay(track).bayesian_bias.awakeREST(this_rest).bias= [];
        sorted_replay(track).replay_score.awakeREST(this_rest).score= [];
        sorted_replay(track).FR_events.awakeREST(this_rest).FR= [];
        
        sorted_replay(track).bayesian_bias.sleepREST(this_rest).bias= [];
        sorted_replay(track).replay_score.sleepREST(this_rest).score= [];
        sorted_replay(track).FR_events.sleepREST(this_rest).FR= [];
        
        sorted_replay(track).bayesian_bias.REST(this_rest).bias= [];
        sorted_replay(track).replay_score.REST(this_rest).score= [];
        sorted_replay(track).FR_events.REST(this_rest).FR= [];
        
        sorted_replay(track).bayesian_bias.immobilityREST(this_rest).bias= [];
        sorted_replay(track).replay_score.immobilityREST(this_rest).score= [];
        sorted_replay(track).FR_events.immobilityREST(this_rest).FR= [];

        % add slope extracted from line fitting
        sorted_replay(track).linear_slope.awakeREST(this_rest).linear_slope=[];
        sorted_replay(track).linear_slope.sleepREST(this_rest).linear_slope=[];
        sorted_replay(track).linear_slope.REST(this_rest).linear_slope=[];
        sorted_replay(track).linear_slope.immobilityREST(this_rest).linear_slope=[];

        % add forward/reverse
        sorted_replay(track).direction.awakeREST(this_rest).direction=[];
        sorted_replay(track).direction.sleepREST(this_rest).direction=[];
        sorted_replay(track).direction.REST(this_rest).direction=[];
        sorted_replay(track).direction.immobilityREST(this_rest).direction=[];

        sorted_replay(track).forward_reverse.awakeREST(this_rest).forward_reverse=[];
        sorted_replay(track).forward_reverse.sleepREST(this_rest).forward_reverse=[];
        sorted_replay(track).forward_reverse.REST(this_rest).forward_reverse=[];
        sorted_replay(track).forward_reverse.immobilityREST(this_rest).forward_reverse=[];

        % posterior spread
        sorted_replay(track).posterior_spread.awakeREST(this_rest).posterior_spread=[];
        sorted_replay(track).posterior_spread.sleepREST(this_rest).posterior_spread=[];
        sorted_replay(track).posterior_spread.REST(this_rest).posterior_spread=[];
        sorted_replay(track).posterior_spread.immobilityREST(this_rest).posterior_spread=[];
    end
    
end

for track=1:number_of_tracks
    event_times= significant_replay_events.track(track).event_times;
    bayesian_bias= significant_replay_events.track(track).bayesian_bias;
    replay_score= significant_replay_events.track(track).replay_score;
    spikes= significant_replay_events.track(track).spikes;
    event_dur= significant_replay_events.track(track).event_duration;
    % add linear slope
    linear_slope= significant_replay_events.track(track).linear_slope;
    % add posterior spread
    posterior_spread= significant_replay_events.track(track).posterior_spread; 
    if contains(pwd,'Directional Analysis')
        % add forward reverse
        direction= significant_replay_events.track(track).direction;
        forward_reverse= significant_replay_events.track(track).forward_reverse;
    else
        direction= zeros(1,length(linear_slope));
        forward_reverse= cell(1,length(linear_slope));
    end
    
    for j=1:length(event_times)
        index=j;
        ref_index= significant_replay_events.track(track).ref_index(j);
        % tracks
        for k=1:number_of_tracks
            % all track time
            if check_if_event_is_in_time_window(event_times(j),time_range.track(k,:))
                sorted_replay(track).index.track(k).behaviour= [sorted_replay(track).index.track(k).behaviour index];
                sorted_replay(track).ref_index.track(k).behaviour=[sorted_replay(track).ref_index.track(k).behaviour ref_index];
                sorted_replay(track).event_time.track(k).behaviour= [sorted_replay(track).event_time.track(k).behaviour event_times(j)];
                sorted_replay(track).bayesian_bias.track(k).bias= [sorted_replay(track).bayesian_bias.track(k).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.track(k).score= [sorted_replay(track).replay_score.track(k).score replay_score(j)];
                sorted_replay(track).FR_events.track(k).FR= [sorted_replay(track).FR_events.track(k).FR numel(spikes{j})/event_dur(j)];
                % 
                sorted_replay(track).linear_slope.track(k).linear_slope= [sorted_replay(track).linear_slope.track(k).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.track(k).direction= [sorted_replay(track).direction.track(k).direction direction(j)];
                sorted_replay(track).forward_reverse.track(k).forward_reverse= [sorted_replay(track).forward_reverse.track(k).forward_reverse forward_reverse(j)];
                % posterior spread
                sorted_replay(track).posterior_spread.track(k).posterior_spread= [sorted_replay(track).posterior_spread.track(k).posterior_spread posterior_spread(j)];
            end
            % immobility periods
            if check_if_event_is_in_time_window(event_times(j),time_range.immobilityTRACK(k).track)
                sorted_replay(track).index.immobilityTRACK(k).behaviour= [sorted_replay(track).index.immobilityTRACK(k).behaviour index];
                sorted_replay(track).ref_index.immobilityTRACK(k).behaviour=[sorted_replay(track).ref_index.immobilityTRACK(k).behaviour ref_index];
                sorted_replay(track).event_time.immobilityTRACK(k).behaviour= [sorted_replay(track).event_time.immobilityTRACK(k).behaviour event_times(j)];
                sorted_replay(track).bayesian_bias.immobilityTRACK(k).bias= [sorted_replay(track).bayesian_bias.immobilityTRACK(k).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.immobilityTRACK(k).score= [sorted_replay(track).replay_score.immobilityTRACK(k).score replay_score(j)];
                sorted_replay(track).FR_events.immobilityTRACK(k).FR= [sorted_replay(track).FR_events.immobilityTRACK(k).FR numel(spikes{j})/event_dur(j)];
                %
                sorted_replay(track).linear_slope.immobilityTRACK(k).linear_slope= [sorted_replay(track).linear_slope.immobilityTRACK(k).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.immobilityTRACK(k).direction= [sorted_replay(track).direction.immobilityTRACK(k).direction direction(j)];
                sorted_replay(track).forward_reverse.immobilityTRACK(k).forward_reverse= [sorted_replay(track).forward_reverse.immobilityTRACK(k).forward_reverse forward_reverse(j)];
                % posterior_spread
                sorted_replay(track).posterior_spread.immobilityTRACK(k).posterior_spread= [sorted_replay(track).posterior_spread.immobilityTRACK(k).posterior_spread posterior_spread(j)];
            end
        end
        
        % rests
        for this_rest=1:size(time_range.rest,1)
            % awake
            if check_if_event_is_in_time_window(event_times(j),time_range.awakeREST(this_rest).rest)
                sorted_replay(track).index.awakeREST(this_rest).rest=[sorted_replay(track).index.awakeREST(this_rest).rest index];
                sorted_replay(track).ref_index.awakeREST(this_rest).rest=[sorted_replay(track).ref_index.awakeREST(this_rest).rest ref_index];
                sorted_replay(track).event_time.awakeREST(this_rest).rest=[sorted_replay(track).event_time.awakeREST(this_rest).rest event_times(j)];
                
                sorted_replay(track).bayesian_bias.awakeREST(this_rest).bias= [sorted_replay(track).bayesian_bias.awakeREST(this_rest).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.awakeREST(this_rest).score= [sorted_replay(track).replay_score.awakeREST(this_rest).score replay_score(j)];
                sorted_replay(track).FR_events.awakeREST(this_rest).FR= [sorted_replay(track).FR_events.awakeREST(this_rest).FR numel(spikes{j})/event_dur(j)];
                %
                sorted_replay(track).linear_slope.awakeREST(this_rest).linear_slope= [sorted_replay(track).linear_slope.awakeREST(this_rest).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.awakeREST(this_rest).direction= [sorted_replay(track).direction.awakeREST(this_rest).direction direction(j)];
                sorted_replay(track).forward_reverse.awakeREST(this_rest).forward_reverse= [sorted_replay(track).forward_reverse.awakeREST(this_rest).forward_reverse forward_reverse(j)];
                % posterior_spread
                 sorted_replay(track).posterior_spread.awakeREST(this_rest).posterior_spread= [sorted_replay(track).posterior_spread.awakeREST(this_rest).posterior_spread posterior_spread(j)];
            end
            % sleep 
            if check_if_event_is_in_time_window(event_times(j),time_range.sleepREST(this_rest).rest)
                sorted_replay(track).index.sleepREST(this_rest).rest=[sorted_replay(track).index.sleepREST(this_rest).rest index];
                sorted_replay(track).ref_index.sleepREST(this_rest).rest=[sorted_replay(track).ref_index.sleepREST(this_rest).rest ref_index];
                sorted_replay(track).event_time.sleepREST(this_rest).rest=[sorted_replay(track).event_time.sleepREST(this_rest).rest event_times(j)];
                
                sorted_replay(track).bayesian_bias.sleepREST(this_rest).bias= [sorted_replay(track).bayesian_bias.sleepREST(this_rest).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.sleepREST(this_rest).score= [sorted_replay(track).replay_score.sleepREST(this_rest).score replay_score(j)];
                sorted_replay(track).FR_events.sleepREST(this_rest).FR= [sorted_replay(track).FR_events.sleepREST(this_rest).FR numel(spikes{j})/event_dur(j)];
            
                %
                sorted_replay(track).linear_slope.sleepREST(this_rest).linear_slope= [sorted_replay(track).linear_slope.sleepREST(this_rest).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.sleepREST(this_rest).direction= [sorted_replay(track).direction.sleepREST(this_rest).direction direction(j)];
                sorted_replay(track).forward_reverse.sleepREST(this_rest).forward_reverse= [sorted_replay(track).forward_reverse.sleepREST(this_rest).forward_reverse forward_reverse(j)];
                % posterior_spread
                sorted_replay(track).posterior_spread.sleepREST(this_rest).posterior_spread= [sorted_replay(track).posterior_spread.sleepREST(this_rest).posterior_spread posterior_spread(j)];
             
            end
            %all
            if check_if_event_is_in_time_window(event_times(j),time_range.rest(this_rest,:))
                sorted_replay(track).index.REST(this_rest).rest=[sorted_replay(track).index.REST(this_rest).rest index];
                sorted_replay(track).ref_index.REST(this_rest).rest=[sorted_replay(track).ref_index.REST(this_rest).rest ref_index];
                sorted_replay(track).event_time.REST(this_rest).rest=[sorted_replay(track).event_time.REST(this_rest).rest event_times(j)];
                
                sorted_replay(track).bayesian_bias.REST(this_rest).bias= [sorted_replay(track).bayesian_bias.REST(this_rest).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.REST(this_rest).score= [sorted_replay(track).replay_score.REST(this_rest).score replay_score(j)];
                sorted_replay(track).FR_events.REST(this_rest).FR= [sorted_replay(track).FR_events.REST(this_rest).FR numel(spikes{j})/event_dur(j)];
                %
                sorted_replay(track).linear_slope.REST(this_rest).linear_slope= [sorted_replay(track).linear_slope.REST(this_rest).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.REST(this_rest).direction= [sorted_replay(track).direction.REST(this_rest).direction direction(j)];
                sorted_replay(track).forward_reverse.REST(this_rest).forward_reverse= [sorted_replay(track).forward_reverse.REST(this_rest).forward_reverse forward_reverse(j)];
                % posterior_spread
                sorted_replay(track).posterior_spread.REST(this_rest).posterior_spread= [sorted_replay(track).posterior_spread.REST(this_rest).posterior_spread posterior_spread(j)];
            end
            % immobility periods
            if check_if_event_is_in_time_window(event_times(j),time_range.immobilityREST(this_rest).rest)
                sorted_replay(track).index.immobilityREST(this_rest).rest= [sorted_replay(track).index.immobilityREST(this_rest).rest index];
                sorted_replay(track).ref_index.immobilityREST(this_rest).rest=[sorted_replay(track).ref_index.immobilityREST(this_rest).rest ref_index];
                sorted_replay(track).event_time.immobilityREST(this_rest).rest= [sorted_replay(track).event_time.immobilityREST(this_rest).rest event_times(j)];
                sorted_replay(track).bayesian_bias.immobilityREST(this_rest).bias= [sorted_replay(track).bayesian_bias.immobilityREST(this_rest).bias bayesian_bias(j)];
                sorted_replay(track).replay_score.immobilityREST(this_rest).score= [sorted_replay(track).replay_score.immobilityREST(this_rest).score replay_score(j)];
                sorted_replay(track).FR_events.immobilityREST(this_rest).FR= [sorted_replay(track).FR_events.immobilityREST(this_rest).FR numel(spikes{j})/event_dur(j)];
                %
                sorted_replay(track).linear_slope.immobilityREST(this_rest).linear_slope= [sorted_replay(track).linear_slope.immobilityREST(this_rest).linear_slope linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.immobilityREST(this_rest).direction= [sorted_replay(track).direction.immobilityREST(this_rest).direction direction(j)];
                sorted_replay(track).forward_reverse.immobilityREST(this_rest).forward_reverse= [sorted_replay(track).forward_reverse.immobilityREST(this_rest).forward_reverse forward_reverse(j)];
                % posterior_spread
                sorted_replay(track).posterior_spread.immobilityREST(this_rest).posterior_spread= [sorted_replay(track).posterior_spread.immobilityREST(this_rest).posterior_spread posterior_spread(j)];
            end
        end
        
        % PRE
        if check_if_event_is_in_time_window(event_times(j),time_range.awakePRE)
            sorted_replay(track).index.awakePRE=[sorted_replay(track).index.awakePRE index];
            sorted_replay(track).ref_index.awakePRE=[sorted_replay(track).ref_index.awakePRE ref_index];
            sorted_replay(track).event_time.awakePRE=[sorted_replay(track).event_time.awakePRE event_times(j)];
            
            sorted_replay(track).bayesian_bias.awakePRE= [sorted_replay(track).bayesian_bias.awakePRE bayesian_bias(j)];
            sorted_replay(track).replay_score.awakePRE= [sorted_replay(track).replay_score.awakePRE replay_score(j)];
            sorted_replay(track).FR_events.awakePRE= [sorted_replay(track).FR_events.awakePRE numel(spikes{j})/event_dur(j)];

            %
            sorted_replay(track).linear_slope.awakePRE= [sorted_replay(track).linear_slope.awakePRE linear_slope(j)];
            % forward/reverse
            sorted_replay(track).direction.awakePRE= [sorted_replay(track).direction.awakePRE direction(j)];
            sorted_replay(track).forward_reverse.awakePRE= [sorted_replay(track).forward_reverse.awakePRE forward_reverse(j)];
            % posterior_spread
            sorted_replay(track).posterior_spread.awakePRE= [sorted_replay(track).posterior_spread.awakePRE posterior_spread(j)];
        end
        if check_if_event_is_in_time_window(event_times(j),time_range.sleepPRE)
            sorted_replay(track).index.sleepPRE=[sorted_replay(track).index.sleepPRE index];
            sorted_replay(track).ref_index.sleepPRE=[sorted_replay(track).ref_index.sleepPRE ref_index];
            sorted_replay(track).event_time.sleepPRE=[sorted_replay(track).event_time.sleepPRE event_times(j)];
            
            sorted_replay(track).bayesian_bias.sleepPRE= [sorted_replay(track).bayesian_bias.sleepPRE bayesian_bias(j)];
            sorted_replay(track).replay_score.sleepPRE= [sorted_replay(track).replay_score.sleepPRE replay_score(j)];
            sorted_replay(track).FR_events.sleepPRE= [sorted_replay(track).FR_events.sleepPRE numel(spikes{j})/event_dur(j)];
            %
            sorted_replay(track).linear_slope.sleepPRE= [sorted_replay(track).linear_slope.sleepPRE linear_slope(j)];
            % forward/reverse
            sorted_replay(track).direction.sleepPRE= [sorted_replay(track).direction.sleepPRE direction(j)];
            sorted_replay(track).forward_reverse.sleepPRE= [sorted_replay(track).forward_reverse.sleepPRE forward_reverse(j)];
            % posterior_spread
            sorted_replay(track).posterior_spread.sleepPRE= [sorted_replay(track).posterior_spread.sleepPRE posterior_spread(j)];
        end

        % all other states: quietRest/not/NREM/REM, PRE+POST
        for thisc=1:length(var)
            if check_if_event_is_in_time_window(event_times(j),time_range.(var{thisc}))
                sorted_replay(track).index.(var{thisc})=[sorted_replay(track).index.(var{thisc}) index];
                sorted_replay(track).ref_index.(var{thisc})=[sorted_replay(track).ref_index.(var{thisc}) ref_index];
                sorted_replay(track).event_time.(var{thisc})=[sorted_replay(track).event_time.(var{thisc}) event_times(j)];
                
                sorted_replay(track).bayesian_bias.(var{thisc})= [sorted_replay(track).bayesian_bias.(var{thisc}) bayesian_bias(j)];
                sorted_replay(track).replay_score.(var{thisc})= [sorted_replay(track).replay_score.(var{thisc}) replay_score(j)];
                sorted_replay(track).FR_events.(var{thisc})= [sorted_replay(track).FR_events.(var{thisc}) numel(spikes{j})/event_dur(j)];
    
                %
                sorted_replay(track).linear_slope.(var{thisc})= [sorted_replay(track).linear_slope.(var{thisc}) linear_slope(j)];
                % forward/reverse
                sorted_replay(track).direction.(var{thisc})= [sorted_replay(track).direction.(var{thisc}) direction(j)];
                sorted_replay(track).forward_reverse.(var{thisc})= [sorted_replay(track).forward_reverse.(var{thisc}) forward_reverse(j)];
                % posterior_spread
                sorted_replay(track).posterior_spread.(var{thisc})= [sorted_replay(track).posterior_spread.(var{thisc}) posterior_spread(j)];
            end
        end
        
        %  POST
        if check_if_event_is_in_time_window(event_times(j),time_range.awakePOST)
            sorted_replay(track).index.awakePOST=[sorted_replay(track).index.awakePOST index];
            sorted_replay(track).ref_index.awakePOST=[sorted_replay(track).ref_index.awakePOST ref_index];
            sorted_replay(track).event_time.awakePOST=[sorted_replay(track).event_time.awakePOST event_times(j)];
            
            sorted_replay(track).bayesian_bias.awakePOST= [sorted_replay(track).bayesian_bias.awakePOST bayesian_bias(j)];
            sorted_replay(track).replay_score.awakePOST= [sorted_replay(track).replay_score.awakePOST replay_score(j)];
            sorted_replay(track).FR_events.awakePOST= [sorted_replay(track).FR_events.awakePOST numel(spikes{j})/event_dur(j)];
            %
            sorted_replay(track).linear_slope.awakePOST= [sorted_replay(track).linear_slope.awakePOST linear_slope(j)];
            % forward/reverse
            sorted_replay(track).direction.awakePOST= [sorted_replay(track).direction.awakePOST direction(j)];
            sorted_replay(track).forward_reverse.awakePOST= [sorted_replay(track).forward_reverse.awakePOST forward_reverse(j)];
            % posterior_spread
            sorted_replay(track).posterior_spread.awakePOST= [sorted_replay(track).posterior_spread.awakePOST posterior_spread(j)];
        end
        if check_if_event_is_in_time_window(event_times(j),time_range.sleepPOST)
            sorted_replay(track).index.sleepPOST=[sorted_replay(track).index.sleepPOST index];
            sorted_replay(track).ref_index.sleepPOST=[sorted_replay(track).ref_index.sleepPOST ref_index];
            sorted_replay(track).event_time.sleepPOST=[sorted_replay(track).event_time.sleepPOST event_times(j)];
            
            sorted_replay(track).bayesian_bias.sleepPOST= [sorted_replay(track).bayesian_bias.sleepPOST bayesian_bias(j)];
            sorted_replay(track).replay_score.sleepPOST= [sorted_replay(track).replay_score.sleepPOST replay_score(j)];
            sorted_replay(track).FR_events.sleepPOST= [sorted_replay(track).FR_events.sleepPOST numel(spikes{j})/event_dur(j)];
            %
            sorted_replay(track).linear_slope.sleepPOST= [sorted_replay(track).linear_slope.sleepPOST linear_slope(j)];
            % forward/reverse
            sorted_replay(track).direction.sleepPOST= [sorted_replay(track).direction.sleepPOST direction(j)];
            sorted_replay(track).forward_reverse.sleepPOST= [sorted_replay(track).forward_reverse.sleepPOST forward_reverse(j)];
            % posterior_spread
            sorted_replay(track).posterior_spread.sleepPOST= [sorted_replay(track).posterior_spread.sleepPOST posterior_spread(j)];
        end
        if check_if_event_is_in_time_window(event_times(j),time_range.immobilityPOST)
            sorted_replay(track).event_time.immobilityPOST=[sorted_replay(track).event_time.immobilityPOST event_times(j)];
        end
        
    end
end

for track=1:number_of_tracks
    % PRE
    sorted_replay(track).cumulative_event_time.awakePRE= interpolate_cumulative_time(time_range.awakePRE_CUMULATIVE,...
        time_range.awakePRE,sorted_replay(track).event_time.awakePRE);
    sorted_replay(track).cumulative_event_time.sleepPRE= interpolate_cumulative_time(time_range.sleepPRE_CUMULATIVE,...
        time_range.sleepPRE,sorted_replay(track).event_time.sleepPRE);
    % REST
    for this_rest= 1:size(time_range.rest,1)
         sorted_replay(track).cumulative_event_time.awakeREST(this_rest).rest= interpolate_cumulative_time(time_range.awakeREST_CUMULATIVE(this_rest).rest,...
            time_range.awakeREST(this_rest).rest,sorted_replay(track).event_time.awakeREST(this_rest).rest);
        sorted_replay(track).cumulative_event_time.sleepREST(this_rest).rest= interpolate_cumulative_time(time_range.sleepREST_CUMULATIVE(this_rest).rest,...
            time_range.sleepREST(this_rest).rest,sorted_replay(track).event_time.sleepREST(this_rest).rest);
        sorted_replay(track).cumulative_event_time.REST(this_rest).rest= interpolate_cumulative_time(time_range.REST_CUMULATIVE(this_rest).rest,...
            time_range.rest(this_rest,:),sorted_replay(track).event_time.REST(this_rest).rest);
        % immobility
        sorted_replay(track).cumulative_event_time.immobilityREST(this_rest).rest= interpolate_cumulative_time(time_range.immobilityREST_CUMULATIVE(this_rest).rest,...
            time_range.immobilityREST(this_rest).rest,sorted_replay(track).event_time.immobilityREST(this_rest).rest);
    end
    
    % MAZES
    for this_track= 1:number_of_tracks
         sorted_replay(track).cumulative_event_time.TRACK(this_track).behaviour= interpolate_cumulative_time(time_range.track_CUMULATIVE(this_track).behaviour,...
            time_range.track(this_track,:),sorted_replay(track).event_time.track(this_track).behaviour);
        % immobility
        sorted_replay(track).cumulative_event_time.immobilityTRACK(this_track).behaviour= interpolate_cumulative_time(time_range.immobilityTRACK_CUMULATIVE(this_track).behaviour,...
            time_range.immobilityTRACK(this_track).track,sorted_replay(track).event_time.immobilityTRACK(this_track).behaviour);
    end
    
    % POST
    sorted_replay(track).cumulative_event_time.awakePOST= interpolate_cumulative_time(time_range.awakePOST_CUMULATIVE,...
        time_range.awakePOST,sorted_replay(track).event_time.awakePOST);
    sorted_replay(track).cumulative_event_time.sleepPOST= interpolate_cumulative_time(time_range.sleepPOST_CUMULATIVE,...
        time_range.sleepPOST,sorted_replay(track).event_time.sleepPOST);
end

[sorted_replay(:).method]= deal(varargin{1});

save time_range time_range
if isempty(varargin)
    save sorted_replay sorted_replay
elseif ~isempty(varargin) && ~ischar(varargin{1})
    disp('not saving')
else
    switch varargin{1}
        case 'wcorr'
            save sorted_replay_wcorr sorted_replay
        case 'spearman'
           save sorted_replay_spearman sorted_replay
       case 'linear'
           save sorted_replay_linear sorted_replay
        case 'control_fixed_rate'
            save sorted_replay_wcorr_FIXED sorted_replay
        case 'reactivations'
            sorted_reactivations= sorted_replay;
            save sorted_reactivations sorted_reactivations
        otherwise
            save sorted_replay sorted_replay
    end
end


end

function output=check_if_event_is_in_time_window(event_time,time_window)
output=0;
for i=1:size(time_window,1)
    if event_time>=time_window(i,1) & event_time<time_window(i,2)
        output=1;
    end
end
end

function cumulative_time=compute_cumulative_time(time)
cumulative_time=time-time(:,1); %normalize by epoch start
cumulative_time(:,2)= cumsum(cumulative_time(:,2));
cumulative_time(2:end,1)=cumulative_time(1:(end-1),2);
end

function cumulative_event_times=  interpolate_cumulative_time(cumulative_time,time, event_times)
if isempty(time)
    cumulative_event_times=NaN;
else
    time(2:end,1)=time(2:end,1)+1e-10;
    cumulative_time(2:end,1)=cumulative_time(2:end,1)+1e-10;
    t= NaN(size(time,1)*size(time,2),1);
    t_c= NaN(size(time,1)*size(time,2),1);
    t(1:2:end)=time(:,1);
    t(2:2:end)=time(:,2);
    t_c(1:2:end)=cumulative_time(:,1);
    t_c(2:2:end)=cumulative_time(:,2);
    cumulative_event_times=interp1(t,t_c,event_times,'linear');
end
end
