function [CANDIDATE,TRACKS,REST,SLEEP]= get_replay_rates_all_epochs(folders,scoring_type)

load('reward_conditions.mat');
parameters= list_of_parameters;
CANDIDATE= table;
TRACKS= table;
REST= table;
SLEEP= table;

CANDIDATE_k=1;
TRACK_k= 1;
REST_k=1;
SLEEP_k=1;

warning('off')

data_folder= pwd;
for this_folder=1:length(folders)

    cd([data_folder '\' folders{this_folder}]);

    load(['Directional Analysis\sorted_replay_' scoring_type '.mat']);
    sorted_replay_directional= sorted_replay;

    load(['sorted_replay_' scoring_type '.mat']);
    load(['significant_replay_events_' scoring_type '.mat']);
    load('time_range.mat');
    load('extracted_laps.mat');
    load('estimated_position_leave_one_out.mat');
    load('sorted_candidate_events.mat');
    load('extracted_position.mat');
    load('extracted_place_fields_BAYESIAN.mat');
    load('extracted_sleep_state_REM_NREM.mat');

    totalNum_replay_allTracks= sum(arrayfun(@(x) length(significant_replay_events.track(x).index),1:length(significant_replay_events.track)));

    curr_sess= strsplit(folders{this_folder},'\');
    curr_rat= curr_sess(1);  curr_sess= curr_sess(2);
    sess_idx= contains(reward_condition.session,curr_sess);
    
    %% Candidate replay events
    CANDIDATE.rat(CANDIDATE_k:CANDIDATE_k+7)= curr_rat;
    CANDIDATE.session(CANDIDATE_k:CANDIDATE_k+7)= curr_sess;
    CANDIDATE.session_number(CANDIDATE_k:CANDIDATE_k+7)= reward_condition.session_number(sess_idx);

    % PRE (awake + sleep)
    CANDIDATE.epoch{CANDIDATE_k}= 'PRE';
    CANDIDATE.epoch_duration(CANDIDATE_k)= diff(time_range.pre);
    CANDIDATE.SWR_number(CANDIDATE_k)= length([sorted_candidate_events.event_time.awakePRE...
                                                sorted_candidate_events.event_time.sleepPRE]);
    CANDIDATE.SWR_rate(CANDIDATE_k)= CANDIDATE.SWR_number(CANDIDATE_k)./CANDIDATE.epoch_duration(CANDIDATE_k);
    CANDIDATE.reward(CANDIDATE_k)= "";
    % PRE time bins
    time_range.awakeQuietPre= sortrows([time_range.quietOnly_PRE; time_range.awakeNotQuietRestPRE]);
     [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2*60,30*60,'awakeQuietPre',1,time_range,sorted_candidate_events,'pre');
     CANDIDATE.SWR_lap_rate{CANDIDATE_k}= temporalRate;
     CANDIDATE.SWR_lap_num{CANDIDATE_k}= temporalNum;
     CANDIDATE.SWR_lap_BinCtrs{CANDIDATE_k}= t_bins;

     CANDIDATE_k= CANDIDATE_k+1;

     % sleep PRE
     time_range.NREM_REM_PRE= sortrows([time_range.NREM_PRE; time_range.REM_PRE]);
    sorted_candidate_events.event_time.quietWake_PRE= sort([sorted_candidate_events.event_time.quietOnly_PRE, sorted_candidate_events.event_time.awakeNotQuietRestPRE]);
    sorted_candidate_events.event_time.NREM_REM_PRE= sort([sorted_candidate_events.event_time.NREM_PRE, sorted_candidate_events.event_time.REM_PRE]);
     
     CANDIDATE.epoch{CANDIDATE_k}= 'sleepPRE';
     CANDIDATE.epoch_duration(CANDIDATE_k)= sum(time_range.NREM_REM_PRE(:,2) - time_range.NREM_REM_PRE(:,1));
     CANDIDATE.SWR_number(CANDIDATE_k)= length(sorted_candidate_events.event_time.NREM_REM_PRE);
    CANDIDATE.SWR_rate(CANDIDATE_k)= CANDIDATE.SWR_number(CANDIDATE_k)./CANDIDATE.epoch_duration(CANDIDATE_k);
    CANDIDATE.reward(CANDIDATE_k)= "";

    [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2*60,10*60,'NREM_REM_PRE',1,time_range,sorted_candidate_events,'NREM_REM_PRE');
    CANDIDATE.SWR_lap_rate{CANDIDATE_k}= temporalRate;
    CANDIDATE.SWR_lap_num{CANDIDATE_k}= temporalNum;
    CANDIDATE.SWR_lap_BinCtrs{CANDIDATE_k}= t_bins;

    CANDIDATE_k= CANDIDATE_k+1;
    % Tracks
    for thisTrack=1:length(sorted_replay)
        CANDIDATE.epoch{CANDIDATE_k}= ['T' num2str(thisTrack)];
        CANDIDATE.epoch_duration(CANDIDATE_k)= sum(time_range.immobilityTRACK(thisTrack).track(:,2)-...
                                                   time_range.immobilityTRACK(thisTrack).track(:,1));
        CANDIDATE.SWR_number(CANDIDATE_k)= length(sorted_candidate_events.event_time.track(thisTrack).behaviour);
        CANDIDATE.SWR_rate(CANDIDATE_k)= CANDIDATE.SWR_number(CANDIDATE_k)./CANDIDATE.epoch_duration(CANDIDATE_k);
        % reward
        reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
        if strcmp(reward,'chocolate')
            CANDIDATE.reward(CANDIDATE_k)= "HIGH";
        elseif strcmp(reward,'diluted')
            CANDIDATE.reward(CANDIDATE_k)= "LOW";
        end

        % lap by lap
        SWRLap_rate= NaN(1,10); SWRLap_num= NaN(1,10);
        all_SWR_track= sorted_candidate_events.event_time.track(thisTrack).behaviour;
        kk=1;
        for this_lap=1:2:19
            % do full laps (back and forth)
            lap_immdur= []; lTmp= [];
            try
                lap_immdur= (sum(lap_times(thisTrack).lap(this_lap).v_cm < parameters.speed_threshold_laps) +...
                                sum(lap_times(thisTrack).lap(this_lap+1).v_cm < parameters.speed_threshold_laps))*0.04;
    
                lTmp= (all_SWR_track >= lap_times(thisTrack).start(this_lap) & ...
                    all_SWR_track <= lap_times(thisTrack).end(this_lap)) |...
                    (all_SWR_track >= lap_times(thisTrack).start(this_lap+1) & ...
                    all_SWR_track <= lap_times(thisTrack).end(this_lap+1));
                SWRLap_num(kk)= sum(lTmp);
                SWRLap_rate(kk)= sum(lTmp)./lap_immdur;
                kk= kk+1;
            end
        end
        CANDIDATE.SWR_lap_num{CANDIDATE_k}= SWRLap_num;
        CANDIDATE.SWR_lap_rate{CANDIDATE_k}= SWRLap_rate;

        CANDIDATE_k= CANDIDATE_k+1;
    end
    
    % Rests
    for this_rest=1:2
        CANDIDATE.epoch{CANDIDATE_k}= ['Rest' num2str(this_rest)];
        CANDIDATE.epoch_duration(CANDIDATE_k)= sum(time_range.immobilityREST(this_rest).rest(:,2)-...
                                                   time_range.immobilityREST(this_rest).rest(:,1));
        CANDIDATE.SWR_number(CANDIDATE_k)= length(sorted_candidate_events.event_time.rest(this_rest).rest);
        CANDIDATE.SWR_rate(CANDIDATE_k)= CANDIDATE.SWR_number(CANDIDATE_k)./CANDIDATE.epoch_duration(CANDIDATE_k);
        CANDIDATE.reward(CANDIDATE_k)="";

        % REST time bins
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2*60,10*60,'immobilityREST',1,time_range,sorted_candidate_events,'rest','thisEpoch',this_rest);
         CANDIDATE.SWR_lap_rate{CANDIDATE_k}= temporalRate;
         CANDIDATE.SWR_lap_num{CANDIDATE_k}= temporalNum;
         CANDIDATE.SWR_lap_BinCtrs{CANDIDATE_k}= t_bins;

        CANDIDATE_k= CANDIDATE_k+1;
    end

    % REST 3 time bins
    CANDIDATE.epoch{CANDIDATE_k}= ['Rest' num2str(3)];
    time_range.NREM_REM_POST= sortrows([time_range.NREM_POST; time_range.REM_POST]);
    time_range.awakeQuietPost= sortrows([time_range.quietOnly_POST; time_range.awakeNotQuietRestPOST]);
    idx= find(time_range.quietRestPOST(:,2) < time_range.NREM_REM_POST(1,1)); % before sleep
     [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2*60,10*60,'awakeQuietPost',1,time_range,sorted_candidate_events,'post','thisEpoch',idx);
     CANDIDATE.SWR_lap_rate{CANDIDATE_k}= temporalRate;
     CANDIDATE.SWR_lap_num{CANDIDATE_k}= temporalNum;
     CANDIDATE.SWR_lap_BinCtrs{CANDIDATE_k}= t_bins;

     CANDIDATE_k= CANDIDATE_k+1;
    
    % POST SLEEP
    CANDIDATE.epoch{CANDIDATE_k}= 'sleepPOST';
    CANDIDATE.epoch_duration(CANDIDATE_k)= sum(time_range.sleepPOST(:,2) - time_range.sleepPOST(:,1));
    CANDIDATE.SWR_number(CANDIDATE_k)= length(sorted_candidate_events.event_time.sleepPOST);
    CANDIDATE.SWR_rate(CANDIDATE_k)= CANDIDATE.SWR_number(CANDIDATE_k)./CANDIDATE.epoch_duration(CANDIDATE_k);
    CANDIDATE.reward(CANDIDATE_k)= "";

    % POST sleep time bins
     [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2*60,15*60,'NREM_REM_POST',1,time_range,sorted_candidate_events,'post');
     CANDIDATE.SWR_lap_rate{CANDIDATE_k}= temporalRate;
     CANDIDATE.SWR_lap_num{CANDIDATE_k}= temporalNum;
     CANDIDATE.SWR_lap_BinCtrs{CANDIDATE_k}= t_bins;

    CANDIDATE_k= CANDIDATE_k+1;
    
    %% REST
    for this_rest=1:2
        for thisTrack=1:length(sorted_replay)
            REST.rat(REST_k)= curr_rat;
            REST.session(REST_k)= curr_sess;
            REST.session_number(REST_k)= reward_condition.session_number(sess_idx);
            REST.rest(REST_k)= this_rest;

            reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
            if strcmp(reward,'chocolate')
                REST.reward{REST_k}= 'HIGH';
            elseif strcmp(reward,'diluted')
                REST.reward{REST_k}= 'LOW';
            end
            
            REST.track(REST_k)= thisTrack;
            REST.restDuration(REST_k)=  sum(time_range.immobilityREST(this_rest).rest(:,2)-...
                                                time_range.immobilityREST(this_rest).rest(:,1));
            REST.replayNum(REST_k)= length(sorted_replay(thisTrack).event_time.immobilityREST(this_rest).rest);
            REST.replayRate(REST_k)= REST.replayNum(REST_k)./REST.restDuration(REST_k);

            REST.restTimeEdges{REST_k}= time_range.rest(this_rest,:);
            REST.restTimeMidPoint(REST_k)= time_range.rest(this_rest,1) + diff(time_range.rest(this_rest,:))/2;

            [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityREST',thisTrack,time_range,sorted_replay,'REST','thisEpoch',this_rest);
             REST.RESTreplayRateBinned{REST_k}= temporalRate;
             REST.RESTreplayNumBinned{REST_k}= temporalNum;
             REST.RESTreplayQualityBinned{REST_k}= temporalQuality;
             REST.RESTbinCtrsBinned{REST_k}= t_bins;

           REST_k= REST_k+1;
        end
        
    end
    % add 'rest 3' before sleep
    time_range.NREM_REM_POST= sortrows([time_range.NREM_POST; time_range.REM_POST]);
    time_range.awakeQuietPost= sortrows([time_range.quietOnly_POST; time_range.awakeNotQuietRestPOST]);
    
    cumul_range= cumsum(time_range.immobilityPOST(:,2) - time_range.immobilityPOST(:,1));
    Idx= find(cumul_range-600 >0,1,'first');
    t_range= time_range.immobilityPOST(1:Idx,:);
    if cumul_range(Idx) > 600
        t_range(Idx,2)=  t_range(Idx,2)- (cumul_range(Idx)-600);
    end
    if time_range.NREM_REM_POST(1,1) < max(t_range,[],'all') % rat falls asleep within 10min
        Idx= find(any(t_range > time_range.NREM_REM_POST(1,1),2),1,'first');
        if t_range(Idx,1)>time_range.NREM_REM_POST(1,1)
            keyboard
            t_range= t_range(1:Idx-1,:);
        elseif t_range(Idx,2)>time_range.NREM_REM_POST(1,1)
            t_range= t_range(1:Idx,:);
            t_range(Idx,2)= time_range.NREM_REM_POST(1,1);
        end
        t_range= [t_range(1) time_range.NREM_REM_POST(1,1)];
    end   
    for thisTrack=1:length(sorted_replay)
            REST.rat(REST_k)= curr_rat;
            REST.session(REST_k)= curr_sess;
            REST.session_number(REST_k)= reward_condition.session_number(sess_idx);
            REST.rest(REST_k)= 3;
            reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
            if strcmp(reward,'chocolate')
                REST.reward{REST_k}= 'HIGH';
            elseif strcmp(reward,'diluted')
                REST.reward{REST_k}= 'LOW';
            end
            REST.track(REST_k)= thisTrack;
            REST.restDuration(REST_k)=   sum(t_range(:,2)- t_range(:,1));
            numTmp= (arrayfun(@(x) length(find(sorted_replay(thisTrack).event_time.immobilityPOST >= t_range(x,1) &...
                                    sorted_replay(thisTrack).event_time.immobilityPOST <= t_range(x,2))),1:size(t_range,1)));
   
            REST.replayNum(REST_k)= sum(numTmp);
            REST.replayRate(REST_k)= REST.replayNum(REST_k)./REST.restDuration(REST_k);

            REST.restTimeEdges{REST_k}= [time_range.post(1) t_range(end,2)];
            REST.restTimeMidPoint(REST_k)= REST.restTimeEdges{REST_k}(1) + diff(REST.restTimeEdges{REST_k})/2;
  
            idx= find(time_range.awakeQuietPost(:,2) < time_range.NREM_REM_POST(1,1)); % before sleep
            [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2.5*60,10*60,'awakeQuietPost',thisTrack,time_range,sorted_replay,'post','thisEpoch',idx);
            REST.RESTreplayRateBinned{REST_k}= temporalRate;
            REST.RESTreplayNumBinned{REST_k}= temporalNum;
            REST.RESTreplayQualityBinned{REST_k}= temporalQuality;
            REST.RESTbinCtrsBinned{REST_k}= t_bins;

            REST_k= REST_k+1;
    end


    %% SLEEP
    sleepTimeBin= 10*60; % 10 min
    stepSize= 5*60; % 5min
    for thisTrack=1:length(sorted_replay)
        SLEEP.rat(SLEEP_k)= curr_rat;
        SLEEP.session(SLEEP_k)= curr_sess;
        SLEEP.session_number(SLEEP_k)= reward_condition.session_number(sess_idx);

        reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
        if strcmp(reward,'chocolate')
            SLEEP.reward{SLEEP_k}= 'HIGH';
        elseif strcmp(reward,'diluted')
            SLEEP.reward{SLEEP_k}= 'LOW';
        end

        total_events_on_tracks= sum(arrayfun(@(x) length(sorted_replay(1).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay))) +...
                                sum(arrayfun(@(x) length(sorted_replay(2).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay))) + ...
                                sum(arrayfun(@(x) length(sorted_replay(3).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay)));
        
        totalImm_allTracks= sum(arrayfun(@(x) sum(time_range.immobilityTRACK(x).track(:,2)-time_range.immobilityTRACK(x).track(:,1)),1:length(sorted_replay)));

        
        SLEEP.track(SLEEP_k)= thisTrack;
        % PRE
        var_to_use_sort= 'pre'; var_to_use_timeRange= 'pre'; 
        % can create composite
        time_range.NREM_REM_PRE= sortrows([time_range.NREM_PRE; time_range.REM_PRE]);
        time_range.quietWakePre= sortrows([time_range.quietOnly_PRE; time_range.awakeNotQuietRestPRE]);
         for ll=1:3
            sorted_replay(ll).event_time.quietWake_PRE= sort([sorted_replay(ll).event_time.quietOnly_PRE, sorted_replay(ll).event_time.awakeNotQuietRestPRE]);
            sorted_replay(ll).event_time.NREMREM_PRE= sort([sorted_replay(ll).event_time.NREM_PRE, sorted_replay(ll).event_time.REM_PRE]);
            
            % posterior spread
            [~,idx]= sort([sorted_replay(ll).event_time.quietOnly_PRE, sorted_replay(ll).event_time.awakeNotQuietRestPRE]);
            tmp = [sorted_replay(ll).posterior_spread.quietOnly_PRE, sorted_replay(ll).posterior_spread.awakeNotQuietRestPRE];
            sorted_replay(ll).posterior_spread.quietWake_PRE= tmp(idx);
            tmp = [sorted_replay(ll).replay_score.quietOnly_PRE, sorted_replay(ll).replay_score.awakeNotQuietRestPRE];
            sorted_replay(ll).replay_score.quietWake_PRE= tmp(idx);

            [~,idx]= sort([sorted_replay(ll).event_time.NREM_PRE, sorted_replay(ll).event_time.REM_PRE]);
            tmp = [sorted_replay(ll).posterior_spread.NREM_PRE, sorted_replay(ll).posterior_spread.REM_PRE];
            sorted_replay(ll).posterior_spread.NREMREM_PRE= tmp(idx);
            tmp = [sorted_replay(ll).replay_score.NREM_PRE, sorted_replay(ll).replay_score.REM_PRE];
            sorted_replay(ll).replay_score.NREMREM_PRE= tmp(idx);
         end

        SLEEP.PREduration(SLEEP_k)=  sum(time_range.(var_to_use_timeRange)(:,2)-...
                                            time_range.(var_to_use_timeRange)(:,1));
        numTmp= (arrayfun(@(x) length(find(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= time_range.(var_to_use_timeRange)(x,1) &...
                                        sorted_replay(thisTrack).event_time.(var_to_use_sort) <= time_range.(var_to_use_timeRange)(x,2))),1:size(time_range.(var_to_use_timeRange),1)));
        SLEEP.PREreplayNum(SLEEP_k)= sum(numTmp);
        SLEEP.PREreplayRate(SLEEP_k)= SLEEP.PREreplayNum(SLEEP_k)./SLEEP.PREduration(SLEEP_k);

        [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2.5*60,30*60,'quietWakePre',thisTrack,time_range,sorted_replay,'quietWake_PRE');
        SLEEP.awakeQuietPREreplayRate{SLEEP_k}= temporalRate;
        SLEEP.awakeQuietPREreplayNum{SLEEP_k}= temporalNum;
        SLEEP.awakeQuietPREreplayQuality{SLEEP_k}= temporalQuality;
        SLEEP.awakeQuietPREbinCtrs{SLEEP_k}= t_bins;

        [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2.5*60,10*60,'NREM_REM_PRE',thisTrack,time_range,sorted_replay,'NREMREM_PRE');
        SLEEP.NREM_REM_PREreplayRate{SLEEP_k}= temporalRate;
        SLEEP.NREM_REM_PREreplayNum{SLEEP_k}= temporalNum;
        SLEEP.NREM_REM_PREreplayQuality{SLEEP_k}= temporalQuality;
        SLEEP.NREM_REM_PREbinCtrs{SLEEP_k}= t_bins;

        SLEEP.sleepPREduration_overall(SLEEP_k)=  sum(time_range.NREM_REM_PRE(:,2)-...
                                            time_range.NREM_REM_PRE(:,1));
        numTmp= (arrayfun(@(x) length(find(sorted_replay(thisTrack).event_time.NREMREM_PRE >= time_range.NREM_REM_PRE(x,1) &...
                                        sorted_replay(thisTrack).event_time.NREMREM_PRE <= time_range.NREM_REM_PRE(x,2))),1:size(time_range.NREM_REM_PRE,1)));
        SLEEP.sleepPREreplayNum_overall(SLEEP_k)= sum(numTmp);
        SLEEP.sleepPREreplayRate_overall(SLEEP_k)= SLEEP.sleepPREreplayNum_overall(SLEEP_k)./SLEEP.sleepPREduration_overall(SLEEP_k);
        

        % per time bin
        maxSleepTime=  60*60; % 1hr
        cumul_t= cumsum(time_range.(var_to_use_timeRange)(:,2) - time_range.(var_to_use_timeRange)(:,1));
        t_bins= 0:stepSize:maxSleepTime-sleepTimeBin;
        t_intervals= [t_bins' (t_bins+sleepTimeBin)']; 

        SLEEP.sleepPREtimeBinSize(SLEEP_k)= sleepTimeBin;
        SLEEP.sleepPREtimeBinsCtrs{SLEEP_k}= t_intervals(:,1)+ (t_intervals(:,2)-t_intervals(:,1))/2; 
        SLEEP.sleepPREreplayNum{SLEEP_k}= NaN(1,length(SLEEP.sleepPREtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPREreplayRate{SLEEP_k}= NaN(1,length(SLEEP.sleepPREtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPREreplayQuality{SLEEP_k}= NaN(1,length(SLEEP.sleepPREtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPREreplayCumNum{SLEEP_k}= NaN(1,length(SLEEP.sleepPREtimeBinsCtrs{SLEEP_k}));
  
         for this_interval=1:size(t_intervals,1)
             % find corresponding start and stop
              x_min= t_intervals(this_interval,1);
              [~,min_t]= min(abs(cumul_t-x_min));
              if x_min<cumul_t(min_t)
                  t_start= time_range.(var_to_use_timeRange)(min_t,2) - (cumul_t(min_t)-x_min);
              elseif x_min==cumul_t(min_t)
                  t_start= time_range.(var_to_use_timeRange)(min_t,2);
              elseif x_min>cumul_t(min_t) && min_t~=length(cumul_t)
                  t_start= time_range.(var_to_use_timeRange)(min_t,1) + (cumul_t(min_t)-x_min);
              else
                  t_start=[];
              end
              x_max=  t_intervals(this_interval,2);
              [~,max_t]= min(abs(cumul_t-x_max));
              if x_max<cumul_t(max_t)
                  t_stop= time_range.(var_to_use_timeRange)(max_t,2) - (cumul_t(max_t)-x_max);
              elseif x_max==cumul_t(max_t)
                  t_stop= time_range.(var_to_use_timeRange)(max_t,2);
              elseif x_max>cumul_t(max_t) && max_t~=length(cumul_t)
                  t_stop= time_range.(var_to_use_timeRange)(max_t,1) + (cumul_t(max_t)-x_max);
              else
                  t_stop=[];
              end

            if ~isempty(t_stop) && ~isempty(t_start)
            time_spent= diff(t_intervals(this_interval,:));
            SLEEP.sleepPREreplayNum{SLEEP_k}(this_interval)= numel(find(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= t_start &...
                                            sorted_replay(thisTrack).event_time.(var_to_use_sort) <= t_stop)); 
            SLEEP.sleepPREreplayRate{SLEEP_k}(this_interval)= SLEEP.sleepPREreplayNum{SLEEP_k}(this_interval)/time_spent; 
            
            % quality
            SLEEP.sleepPREreplayQuality{SLEEP_k}(this_interval)= median(sorted_replay(thisTrack).posterior_spread.(var_to_use_sort)(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= t_start &...
                                            sorted_replay(thisTrack).event_time.(var_to_use_sort) <= t_stop),'omitmissing'); 

            % state
            end
         end

         SLEEP.sleepPREreplayRate_BASELINE{SLEEP_k}= SLEEP.sleepPREreplayRate{SLEEP_k}./(total_events_on_tracks/totalImm_allTracks);
         SLEEP.sleepPREreplayCumNum{SLEEP_k}= cumsum(SLEEP.sleepPREreplayNum{SLEEP_k});
         
        % POST
        var_to_use_sort= 'post';
        var_to_use_timeRange= 'post';
        % can create composite, as long as is subset of
        % sorted_replay_events.X.(var)
        time_range.NREM_REM_POST= sortrows([time_range.NREM_POST; time_range.REM_POST]);
        time_range.quietWake_POST= sortrows([time_range.quietOnly_POST; time_range.awakeNotQuietRestPOST]);
         for ll=1:3
            sorted_replay(ll).event_time.quietWake_POST= sort([sorted_replay(ll).event_time.quietOnly_POST, sorted_replay(ll).event_time.awakeNotQuietRestPOST]);
            sorted_replay(ll).event_time.NREMREM_POST= sort([sorted_replay(ll).event_time.NREM_POST, sorted_replay(ll).event_time.REM_POST]);

            % scores
            [~,idx]= sort([sorted_replay(ll).event_time.quietOnly_POST, sorted_replay(ll).event_time.awakeNotQuietRestPOST]);
            tmp= [sorted_replay(ll).replay_score.quietOnly_POST, sorted_replay(ll).replay_score.awakeNotQuietRestPOST];
            sorted_replay(ll).replay_score.quietWake_POST= tmp(idx);

            [~,idx]= sort([sorted_replay(ll).event_time.NREM_POST, sorted_replay(ll).event_time.REM_POST]);
            tmp= [sorted_replay(ll).replay_score.NREM_POST, sorted_replay(ll).replay_score.REM_POST];
            sorted_replay(ll).replay_score.NREMREM_POST= tmp(idx);
         end
        
        SLEEP.POSTsleepDuration(SLEEP_k)= sum(time_range.(var_to_use_timeRange)(:,2)-...
                                            time_range.(var_to_use_timeRange)(:,1));
        
        numTmp= arrayfun(@(x) length(find(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= time_range.(var_to_use_timeRange)(x,1) &...
             sorted_replay(thisTrack).event_time.(var_to_use_sort) <= time_range.(var_to_use_timeRange)(x,2))),1:size(time_range.(var_to_use_timeRange),1));
   
        SLEEP.POSTreplayNum_overall(SLEEP_k)= sum(numTmp);
        SLEEP.POSTreplayRate_overall(SLEEP_k)= SLEEP.POSTreplayNum_overall(SLEEP_k)./SLEEP.POSTsleepDuration(SLEEP_k);
   
        % overall sleepPOST
        SLEEP.sleepPOSTduration_overall(SLEEP_k)= sum(time_range.NREM_REM_POST(:,2)-time_range.NREM_REM_POST(:,1));
        numTmp= arrayfun(@(x) length(find(sorted_replay(thisTrack).event_time.NREMREM_POST >= time_range.NREM_REM_POST(x,1) &...
             sorted_replay(thisTrack).event_time.NREMREM_POST <= time_range.NREM_REM_POST(x,2))),1:size(time_range.NREM_REM_POST,1));
        SLEEP.sleepPOSTreplayNum_overall(SLEEP_k)= sum(numTmp);
        SLEEP.sleepPOSTreplayRate_overall(SLEEP_k)= SLEEP.sleepPOSTreplayNum_overall(SLEEP_k)./SLEEP.sleepPOSTduration_overall(SLEEP_k);

        % First 15 min
        sleepTimeBin= 15*60;
        stepSize= 15*60;
        maxSleepTime= 15*60;
        % post
        [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(sleepTimeBin,stepSize,maxSleepTime,'post',thisTrack,time_range,sorted_replay,'post');
        SLEEP.(['POSTreplayRatePOST_' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= temporalRate;
        SLEEP.(['POSTreplayNumPOST' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= temporalNum;
        SLEEP.(['POSTbinCtrsPOST' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= t_bins;
        % sleepPOST
        [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(sleepTimeBin,stepSize,maxSleepTime,'NREM_REM_POST',thisTrack,time_range,sorted_replay,'NREMREM_POST');
        SLEEP.(['NremRemPOSTreplayRate_' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= temporalRate;
        SLEEP.(['NremRemPOSTreplayNum_' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= temporalNum;
        SLEEP.(['NremRemPOSTbinCtrs' num2str(maxSleepTime-sleepTimeBin) '_to_' num2str(maxSleepTime)]){SLEEP_k}= t_bins;
         
        % time to each state from beginning of post (in min)
        SLEEP.time_to_WAKE(SLEEP_k)= (time_range.awakeNotQuietRestPOST(1,1)- time_range.post(1))/60;
        SLEEP.time_to_QUIET(SLEEP_k)= (time_range.quietOnly_POST(1,1)- time_range.post(1))/60;
        SLEEP.time_to_NREM(SLEEP_k)= (time_range.NREM_POST(1,1)- time_range.post(1))/60;
        SLEEP.time_to_REM(SLEEP_k)= (time_range.REM_POST(1,1)- time_range.post(1))/60;

        % get speed
        time_to_sleep= min([time_range.NREM_POST(1,1) time_range.REM_POST(1,1)]);
        v_post= position.v_cm(position.t >= time_range.post(1) & position.t <= time_range.post(2));
        v_z= zscore(v_post);
        v_t= position.t(position.t >= time_range.post(1) & position.t <= time_range.post(2));
        v_z= smooth(v_z,500); 

        % state per small time bin
        maxSleepTime=  120*60;
        cumul_t= cumsum(time_range.post(:,2) - time_range.post(:,1));
        t_bins= 0:60:maxSleepTime-60;
        t_intervals= [t_bins' (t_bins+60)'];
        SLEEP.statesTimeBinsCtrs{SLEEP_k}= t_intervals(:,1)+ (t_intervals(:,2)-t_intervals(:,1))/2; 
        SLEEP.dominantState{SLEEP_k}= NaN(1,length(SLEEP.statesTimeBinsCtrs{SLEEP_k}));
        SLEEP.binnedSpeed{SLEEP_k}= NaN(1,length(SLEEP.statesTimeBinsCtrs{SLEEP_k}));
        SLEEP.binnedSpeed_z{SLEEP_k}= NaN(1,length(SLEEP.statesTimeBinsCtrs{SLEEP_k}));
        SLEEP.binnedRateAllTracks{SLEEP_k}= NaN(1,length(SLEEP.statesTimeBinsCtrs{SLEEP_k}));
        for this_interval=1:size(t_intervals,1)
             % find corresponding start and stop
              x_min= t_intervals(this_interval,1);
              min_t= find(cumul_t>=x_min,1,'first');
              t_start = time_range.(var_to_use_timeRange)(min_t,2) - (cumul_t(min_t)-x_min);

              x_max=  t_intervals(this_interval,2);
              max_t= find(cumul_t>=x_max,1,'first');
              t_stop = time_range.(var_to_use_timeRange)(max_t,2) - (cumul_t(max_t)-x_max);
              if ~isempty(t_stop) && ~isempty(t_start)
                time_spent= diff(t_intervals(this_interval,:));
                idx= arrayfun(@(x) sleep_state.time >= time_range.post(x,1) & ...
                        sleep_state.time <= time_range.post(x,2),1:size(time_range.post,1),'UniformOutput',0);
                idx= (sum([idx{:}]')>0)';
                st_tmp= arrayfun(@(x)length(find(sleep_state.state(idx & ...
                    (sleep_state.time >= t_start & sleep_state.time <= t_stop)) == x)),0:3); 
                [~,I]= max(st_tmp);
                SLEEP.dominantState{SLEEP_k}(this_interval)= I;

                % speed
                SLEEP.binnedSpeed_z{SLEEP_k}(this_interval)= median(v_z(v_t >= t_start & v_t <= t_stop));
                SLEEP.binnedSpeed{SLEEP_k}(this_interval)= SLEEP.binnedSpeed_z{SLEEP_k}(this_interval)*std(v_post)+mean(v_post);

                % rate
                all_events= sort([significant_replay_events.track(:).event_times]);
                numEvents= numel(find(all_events >= t_start & all_events <= t_stop));
                SLEEP.binnedRateAllTracks{SLEEP_k}(this_interval)= numEvents/(t_stop-t_start);

              end
        end

        % per time bin
        maxSleepTime=  120*60;
        cumul_t= cumsum(time_range.(var_to_use_timeRange)(:,2) - time_range.(var_to_use_timeRange)(:,1));
        t_bins= [0:stepSize:maxSleepTime-sleepTimeBin];
        t_intervals= [t_bins' (t_bins+sleepTimeBin)'];

        SLEEP.sleepPOSTtimeBinSize(SLEEP_k)= sleepTimeBin;
        SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}= t_intervals(:,1)+ (t_intervals(:,2)-t_intervals(:,1))/2; %t_bins(1:end-1)+sleepTimeBin/2;
        SLEEP.sleepPOSTreplayNum{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTreplayRate{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTreplayQuality{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTreplayCumNum{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTstate{SLEEP_k}= NaN(4,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTreplayRate_pctCAND{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));

        %FWD/REV
        SLEEP.sleepPOSTreplayFWDRate{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        SLEEP.sleepPOSTreplayREVRate{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));
        % Cand
        SLEEP.sleepPOSTCandEventNum{SLEEP_k}= NaN(1,length(SLEEP.sleepPOSTtimeBinsCtrs{SLEEP_k}));

         for this_interval=1:size(t_intervals,1)
             % find corresponding start and stop
              x_min= t_intervals(this_interval,1);
              min_t= find(cumul_t>=x_min,1,'first');
              t_start = time_range.(var_to_use_timeRange)(min_t,2) - (cumul_t(min_t)-x_min);

              x_max=  t_intervals(this_interval,2);
              max_t= find(cumul_t>=x_max,1,'first');
              t_stop = time_range.(var_to_use_timeRange)(max_t,2) - (cumul_t(max_t)-x_max);


            if ~isempty(t_stop) && ~isempty(t_start)
            time_spent= diff(t_intervals(this_interval,:));
            SLEEP.sleepPOSTreplayNum{SLEEP_k}(this_interval)= numel(find(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= t_start &...
                                            sorted_replay(thisTrack).event_time.(var_to_use_sort) <= t_stop)); 
            SLEEP.sleepPOSTreplayRate{SLEEP_k}(this_interval)= SLEEP.sleepPOSTreplayNum{SLEEP_k}(this_interval)/time_spent;
            % quality
            SLEEP.sleepPOSTreplayQuality{SLEEP_k}(this_interval)= nanmedian(sorted_replay(thisTrack).posterior_spread.(var_to_use_sort)(sorted_replay(thisTrack).event_time.(var_to_use_sort) >= t_start &...
                                            sorted_replay(thisTrack).event_time.(var_to_use_sort) <= t_stop)); 
            % cand events
            SLEEP.sleepPOSTCandEventNum{SLEEP_k}(this_interval)= numel(find(sorted_candidate_events.event_time.(var_to_use_sort) >= t_start &...
                                            sorted_candidate_events.event_time.(var_to_use_sort) <= t_stop)); 
            
            % FWD/REV
            FWD_idx= sorted_replay_directional(thisTrack).forward_reverse.(var_to_use_sort) == "forward";
            REV_idx= sorted_replay_directional(thisTrack).forward_reverse.(var_to_use_sort) == "reverse";
            SLEEP.sleepPOSTreplayFWDRate{SLEEP_k}(this_interval)= numel(find(sorted_replay_directional(thisTrack).event_time.(var_to_use_sort)(FWD_idx) >= t_start &...
                                            sorted_replay_directional(thisTrack).event_time.(var_to_use_sort)(FWD_idx) <= t_stop))/time_spent; 
            SLEEP.sleepPOSTreplayREVRate{SLEEP_k}(this_interval)= numel(find(sorted_replay_directional(thisTrack).event_time.(var_to_use_sort)(REV_idx) >= t_start &...
                                            sorted_replay_directional(thisTrack).event_time.(var_to_use_sort)(REV_idx) <= t_stop))/time_spent; 
            % state
            idx= arrayfun(@(x) sleep_state.time >= time_range.(var_to_use_timeRange)(x,1) & sleep_state.time <= time_range.(var_to_use_timeRange)(x,2),1:size(time_range.(var_to_use_timeRange),1),'UniformOutput',0);
            idx= (sum([idx{:}]')>0)';
            st_tmp= arrayfun(@(x)length(find(sleep_state.state(idx & (sleep_state.time >= t_start & sleep_state.time <= t_stop)) == x)),0:3); % should not contain 0s but..
            SLEEP.sleepPOSTstate{SLEEP_k}(:,this_interval)= st_tmp./sum(st_tmp);
            end
         end
         SLEEP.sleepPOSTreplayRate_pctCAND{SLEEP_k}= 100.*SLEEP.sleepPOSTreplayNum{SLEEP_k}./SLEEP.sleepPOSTCandEventNum{SLEEP_k};
          SLEEP.sleepPOSTreplayCumNum{SLEEP_k}= cumsum(SLEEP.sleepPOSTreplayNum{SLEEP_k});
         SLEEP.cumNumBeforeSleepPOST(SLEEP_k)= length(find(significant_replay_events.track(thisTrack).event_times < time_range.(var_to_use_timeRange)(1,1)));
         % rate immobility before sleep
         low_speed_idx= position.v_cm < parameters.speed_threshold_laps & position.t < time_range.(var_to_use_timeRange)(1,1) & ~isnan(position.x);    
         [start_idx,stop_idx]= getIntervals(low_speed_idx);
         starts= position.t(start_idx); stops= position.t(stop_idx);
         total_time_immobile_beforeSleepPOST= sum(stops'- starts');
         SLEEP.cumRateBeforeSleepPOST(SLEEP_k)= SLEEP.cumNumBeforeSleepPOST(SLEEP_k)./total_time_immobile_beforeSleepPOST;
         SLEEP.sleepPOSTreplayCumNum_offset{SLEEP_k}= SLEEP.cumNumBeforeSleepPOST(SLEEP_k)+SLEEP.sleepPOSTreplayCumNum{SLEEP_k};


         % states
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,120*60,'post',thisTrack,time_range,sorted_replay,'post');
         SLEEP.POSTreplayRatePOST{SLEEP_k}= temporalRate;
         SLEEP.POSTreplayNumPOST{SLEEP_k}= temporalNum;
         SLEEP.POSTbinCtrsPOST{SLEEP_k}= t_bins;
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,60*60,'quietWake_POST',thisTrack,time_range,sorted_replay,'quietWake_POST');
         SLEEP.quietWakePOSTreplayRate{SLEEP_k}= temporalRate;
         SLEEP.quietWakePOSTreplayNum{SLEEP_k}= temporalNum;
         SLEEP.quietWakePOSTbinCtrs{SLEEP_k}= t_bins;
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,120*60,'post',thisTrack,time_range,sorted_replay,'quietOnly_POST');
         SLEEP.quietOnlyPOSTreplayRatePOST{SLEEP_k}= temporalRate;
         SLEEP.quietOnlyPOSTreplayNumPOST{SLEEP_k}= temporalNum;
         SLEEP.quietOnlyPOSTbinCtrsPOST{SLEEP_k}= t_bins;
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,120*60,'post',thisTrack,time_range,sorted_replay,'awakeNotQuietRestPOST');
         SLEEP.wakePOSTreplayRatePOST{SLEEP_k}= temporalRate;
         SLEEP.wakePOSTreplayNumPOST{SLEEP_k}= temporalNum;
         SLEEP.wakePOSTbinCtrsPOST{SLEEP_k}= t_bins;
         % 
         [temporalNum,temporalRate,temporalQuality,t_bins]= getTemporalEvolution(5*60,2.5*60,15*60,'NREM_REM_POST',thisTrack,time_range,sorted_replay,'NREMREM_POST');
         SLEEP.NremRemPOSTreplayRate{SLEEP_k}= temporalRate;
         SLEEP.NremRemPOSTreplayNum{SLEEP_k}= temporalNum;
         SLEEP.NremRemPOSTreplayQuality{SLEEP_k}= temporalQuality;
         SLEEP.NremRemPOSTbinCtrs{SLEEP_k}= t_bins;
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,120*60,'post',thisTrack,time_range,sorted_replay,'NREM_POST');
         SLEEP.NremPOSTreplayRatePOST{SLEEP_k}= temporalRate;
         SLEEP.NremPOSTreplayNumPOST{SLEEP_k}= temporalNum;
         SLEEP.NremPOSTbinCtrsPOST{SLEEP_k}= t_bins;
         [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,120*60,'post',thisTrack,time_range,sorted_replay,'REM_POST');
         SLEEP.RemPOSTreplayRatePOST{SLEEP_k}= temporalRate;
         SLEEP.RemPOSTreplayNumPOST{SLEEP_k}= temporalNum;
         SLEEP.RemPOSTbinCtrsPOST{SLEEP_k}= t_bins;

       SLEEP_k= SLEEP_k+1;
    end

    %% TRACKS 
    % for each track: get local, remote n-1 n-2 and future, 
    % forward and reverse (local)
    for this_replayed_track=1:length(sorted_replay)

        TRACKS.rat(TRACK_k)= curr_rat;
        TRACKS.session(TRACK_k)= curr_sess;
        TRACKS.session_number(TRACK_k)= reward_condition.session_number(sess_idx);
        TRACKS.track(TRACK_k)= this_replayed_track;
        reward= reward_condition.(['track' num2str(this_replayed_track)]){sess_idx};
        if strcmp(reward,'chocolate')
            TRACKS.reward{TRACK_k}= 'HIGH';
        elseif strcmp(reward,'diluted')
            TRACKS.reward{TRACK_k}= 'LOW';
        end
        TRACKS.num_cells(TRACK_k)= length(place_fields_BAYESIAN.good_place_cells);

        % BEHAVIOUR
        TRACKS.num_laps(TRACK_k)= lap_times(this_replayed_track).total_number_of_laps/2;
        TRACKS.time_on_track_min(TRACK_k)= (lap_times(this_replayed_track).end(end)-lap_times(this_replayed_track).start(1))/60;
        TRACKS.total_num_laps_per_min(TRACK_k)= TRACKS.num_laps(TRACK_k)/TRACKS.time_on_track_min(TRACK_k);
        % lap per min
        t= lap_times(this_replayed_track).start(1):60:lap_times(this_replayed_track).end(end);
        num_lap_min= [];
        for ii=1:length(t)-1
                num_lap_min(ii)= sum(lap_times(this_replayed_track).end' <= t(ii+1));
        end
        TRACKS.cumul_num_lap_per_min{TRACK_k}= num_lap_min;

        numLaps= floor(length(lap_times(this_replayed_track).lap)/2);
        % total time immobile each zones
        endZones= lap_times(this_replayed_track).end_zones_coord;
        v_cm = position.v_cm;
        x= position.linear(this_replayed_track).linear;
        low_speed_idx= v_cm < parameters.speed_threshold_laps & ...
                         ~isnan(x) & ...
                        ((x>=endZones(1,1) & x<=endZones(1,2)) | (x>=endZones(2,1) & x<=endZones(2,2)));
        [start_idx,stop_idx]= getIntervals(low_speed_idx);
        TRACKS.time_end_zones_immobile(TRACK_k)= sum(position.t(stop_idx)- position.t(start_idx));
        % total time immobile per lap
        imm_per_lap= arrayfun(@(x) length(find(lap_times(this_replayed_track).lap(x).v_cm < parameters.speed_threshold_laps))*0.04,1:length(lap_times(this_replayed_track).lap));
        TRACKS.median_time_immobile_per_lap(TRACK_k)= median(imm_per_lap);
        imm_per_lap= arrayfun(@(x) sum(imm_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.time_immobile_per_lap{TRACK_k}= imm_per_lap;

        % END ZONES time spent immobile per lap
        imm_per_lap= arrayfun(@(x) length(find(lap_times(this_replayed_track).end_zone(x).v_cm < parameters.speed_threshold_laps))*0.04,1:length(lap_times(this_replayed_track).end_zone));
        TRACKS.time_end_zones_immobile_per_lap{TRACK_k}= imm_per_lap;
        % END ZONES position during imm
        x_bin_edges = 0:parameters.x_bins_width:200;
        v_end= [lap_times(this_replayed_track).end_zone.v_cm];
        x_end= [lap_times(this_replayed_track).end_zone.x];
        pos_imm= x_end(v_end< parameters.speed_threshold_laps);
        TRACKS.POS_end_zones_immobile_per_lap{TRACK_k}= 0.04*histcounts(pos_imm,x_bin_edges);
        
        % RUN ZONES time immobile
        low_speed_idx= v_cm < parameters.speed_threshold_laps & ~isnan(x) & ...
                        (x>endZones(1,2) & x<endZones(2,1));
        [start_idx,stop_idx]= getIntervals(low_speed_idx);
        TRACKS.time_run_zones_immobile(TRACK_k)= sum(position.t(stop_idx)- position.t(start_idx));
        imm_per_lap= arrayfun(@(x) length(find(lap_times(this_replayed_track).run_zone(x).v_cm < parameters.speed_threshold_laps))*0.04,1:length(lap_times(this_replayed_track).run_zone));
        TRACKS.time_run_zones_immobile_per_lap{TRACK_k}= imm_per_lap;
       
        % RUN ZONES position during imm
        x_end= [lap_times(this_replayed_track).run_zone.x];
        v_end= [lap_times(this_replayed_track).run_zone.v_cm];
        pos_imm= x_end(v_end< parameters.speed_threshold_laps);
        TRACKS.POS_run_zones_immobile_per_lap{TRACK_k}= 0.04*histcounts(pos_imm,x_bin_edges);

        % speed per lap
        speed_per_lap= arrayfun(@(x) median(lap_times(this_replayed_track).lap(x).v_cm(lap_times(this_replayed_track).lap(x).v_cm>parameters.speed_threshold_laps)),1:length(lap_times(this_replayed_track).lap));
        TRACKS.median_speed_per_lap(TRACK_k)= median(speed_per_lap);
        speed_per_lap= arrayfun(@(x) median(speed_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.speed_per_lap{TRACK_k}= speed_per_lap;

        % speedslow_per_lap= arrayfun(@(x) median(lap_times(this_replayed_track).lap(x).v_cm(lap_times(this_replayed_track).lap(x).v_cm<=parameters.speed_threshold_laps)),1:length(lap_times(this_replayed_track).lap));
        speedslow_per_lap= arrayfun(@(x) median(lap_times(this_replayed_track).end_zone(x).v_cm(lap_times(this_replayed_track).end_zone(x).v_cm<=parameters.speed_threshold_laps)),1:length(lap_times(this_replayed_track).end_zone));
        speedslow_per_lap= arrayfun(@(x) median(speedslow_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.speedSLOW_per_lap{TRACK_k}= speedslow_per_lap;

        % speed immobile
        speed_imm_per_lap= arrayfun(@(x) median(lap_times(this_replayed_track).lap(x).v_cm(lap_times(this_replayed_track).lap(x).v_cm<=parameters.speed_threshold_laps)),1:length(lap_times(this_replayed_track).lap));
        speed_imm_per_lap= arrayfun(@(x) nanmedian(speed_imm_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.speed_imm_per_lap{TRACK_k}= speed_imm_per_lap;
        % at rew site
        speed_imm_per_lap_REWSITE= arrayfun(@(x) median(lap_times(this_replayed_track).end_zone(x).v_cm(lap_times(this_replayed_track).end_zone(x).v_cm<=parameters.speed_threshold_laps)),1:length(lap_times(this_replayed_track).end_zone));
        speed_imm_per_lap_REWSITE= arrayfun(@(x) nanmedian(speed_imm_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.speed_imm_per_lap_REWSITE{TRACK_k}= speed_imm_per_lap_REWSITE;

        % REPLAY ANALYSES
        all_local_events= sorted_replay(this_replayed_track).event_time.immobilityTRACK(this_replayed_track).behaviour;
        Wscore_local_events= sorted_replay(this_replayed_track).replay_score.immobilityTRACK(this_replayed_track).score;

        all_forwardLocal_events= sorted_replay_directional(this_replayed_track).event_time.immobilityTRACK(this_replayed_track).behaviour(...
                        sorted_replay_directional(this_replayed_track).forward_reverse.immobilityTRACK(this_replayed_track).forward_reverse == "forward");
          Wscore_forwardLocal_events= sorted_replay_directional(this_replayed_track).replay_score.immobilityTRACK(this_replayed_track).score(...
                        sorted_replay_directional(this_replayed_track).forward_reverse.immobilityTRACK(this_replayed_track).forward_reverse == "forward");
        
        all_reverseLocal_events= sorted_replay_directional(this_replayed_track).event_time.immobilityTRACK(this_replayed_track).behaviour(...
                        sorted_replay_directional(this_replayed_track).forward_reverse.immobilityTRACK(this_replayed_track).forward_reverse == "reverse");
        Wscore_reverseLocal_events= sorted_replay_directional(this_replayed_track).replay_score.immobilityTRACK(this_replayed_track).score(...
                        sorted_replay_directional(this_replayed_track).forward_reverse.immobilityTRACK(this_replayed_track).forward_reverse == "reverse");

        % sorted_replay(replayed_track).event_time(where/when).track sorted_track(1).event_time(2).track is replay of track 1 during track 2
        if this_replayed_track>1 % track 2&3
            all_remote_events_n1= sorted_replay(this_replayed_track-1).event_time.immobilityTRACK(this_replayed_track).behaviour;
            Wscore_remote_events_n1= sorted_replay(this_replayed_track-1).replay_score.immobilityTRACK(this_replayed_track).score;
        else
            all_remote_events_n1= [];
            Wscore_remote_events_n1= [];
        end
        if this_replayed_track>2 % track 3
            all_remote_events_n2= sorted_replay(this_replayed_track-2).event_time.immobilityTRACK(this_replayed_track).behaviour;
            Wscore_remote_events_n2= sorted_replay(this_replayed_track-2).replay_score.immobilityTRACK(this_replayed_track).score;
        else
            all_remote_events_n2= [];
             Wscore_remote_events_n2= [];
        end
        if this_replayed_track==1
            future_n1_events= sorted_replay(this_replayed_track+1).event_time.immobilityTRACK(this_replayed_track).behaviour;
            future_n2_events= sorted_replay(this_replayed_track+2).event_time.immobilityTRACK(this_replayed_track).behaviour;
            Wscore_future_n1_events= sorted_replay(this_replayed_track+1).replay_score.immobilityTRACK(this_replayed_track).score;
            Wscore_future_n2_events= sorted_replay(this_replayed_track+2).replay_score.immobilityTRACK(this_replayed_track).score;
        elseif this_replayed_track==2
            future_n1_events= sorted_replay(this_replayed_track+1).event_time.immobilityTRACK(this_replayed_track).behaviour;
            Wscore_future_n1_events= sorted_replay(this_replayed_track+1).replay_score.immobilityTRACK(this_replayed_track).score;
            future_n2_events= [];
            Wscore_future_n2_events= [];
        else
            future_n1_events= [];
            Wscore_future_n1_events= [];
            future_n2_events= [];
            Wscore_future_n2_events= [];
        end
        num_replay_events_epoch= 0;
        for that_track=1:length(sorted_replay)
            num_replay_events_epoch= num_replay_events_epoch+length(sorted_replay(that_track).event_time.immobilityTRACK(this_replayed_track).behaviour);
        end
        total_local_replay_all_tracks= sum(arrayfun(@(x) length(sorted_replay(x).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay)));        
        total_events_on_tracks= sum(arrayfun(@(x) length(sorted_replay(1).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay))) +...
                                sum(arrayfun(@(x) length(sorted_replay(2).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay))) + ...
                                sum(arrayfun(@(x) length(sorted_replay(3).event_time.immobilityTRACK(x).behaviour),1:length(sorted_replay)));
        
        % LOCAL overall time on track
        TRACKS.LocalTrack_duration(TRACK_k)= sum(time_range.immobilityTRACK(this_replayed_track).track(:,2)-...
                                                time_range.immobilityTRACK(this_replayed_track).track(:,1));
        TRACKS.total_events_on_tracks(TRACK_k)= length([all_remote_events_n2 all_remote_events_n1 all_local_events future_n1_events future_n2_events]);
        TRACKS.total_events_rate_on_tracks(TRACK_k)= TRACKS.total_events_on_tracks(TRACK_k)/TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.Local_replay_number(TRACK_k)= length(all_local_events);
        TRACKS.Local_replay_rate(TRACK_k)= TRACKS.Local_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.Local_replay_meanWScore(TRACK_k)= mean(Wscore_local_events);

        idx_beforeSleep= significant_replay_events.track(this_replayed_track).event_times<= time_range.NREM_REM_POST(1,1);
        TRACKS.total_events_beforeSleepPOST(TRACK_k)= numel(significant_replay_events.track(this_replayed_track).event_times(idx_beforeSleep));
        idxLocal= significant_replay_events.track(this_replayed_track).event_times>= time_range.track(this_replayed_track,1) &...
            significant_replay_events.track(this_replayed_track).event_times<= time_range.track(this_replayed_track,2);
        TRACKS.totalLocal_events_beforeSleepPOST(TRACK_k)= numel(significant_replay_events.track(this_replayed_track).event_times(idxLocal & idx_beforeSleep));
        TRACKS.totalRemote_events_beforeSleepPOST(TRACK_k)= numel(significant_replay_events.track(this_replayed_track).event_times(~idxLocal & idx_beforeSleep));
        % find total immobility session before sleep - this is a repeat of
        % sort_replay_events...
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
        low_speed_epochs= [];
        low_speed_epochs(:,1)= starts;
        low_speed_epochs(:,2)= stops;
        % have to choose when to start counting...
        index= (low_speed_epochs(:,1) < time_range.NREM_REM_POST(1,1) & low_speed_epochs(:,2) >= time_range.pre(1,1));
        immTmp= low_speed_epochs(index,:);
        TRACKS.total_imm_beforeSleepPOST(TRACK_k)= sum(immTmp(:,2) -  immTmp(:,1));
        TRACKS.total_rate_beforeSleepPOST(TRACK_k)= TRACKS.total_events_beforeSleepPOST(TRACK_k)./TRACKS.total_imm_beforeSleepPOST(TRACK_k);
        
        [NumReplay_lap,binnedSpeed_lap,maxStopTime_lap]= get_events_lap_cumul_stopTime(parameters,lap_times,this_replayed_track,all_local_events);
        TRACKS.Local_replay_Lap_Num_cumulSec{TRACK_k}= NumReplay_lap;
        TRACKS.Local_binnedSpeed_lap_cumulSec{TRACK_k}= binnedSpeed_lap;
        TRACKS.maxStopTime_lap_cumulSec{TRACK_k}= maxStopTime_lap;

        [NumSWR_lap,binnedSpeed_lap,~]= get_events_lap_cumul_stopTime(parameters,lap_times,this_replayed_track,sorted_candidate_events.event_time.immobilityTRACK(this_replayed_track).behaviour);
        TRACKS.LocalSWR_Lap_Num_cumulSec{TRACK_k}= NumSWR_lap;
        TRACKS.LocalSWR_binnedSpeed_lap_cumulSec{TRACK_k}= binnedSpeed_lap;

        [NumFwd_lap,binnedSpeed_lap,~]= get_events_lap_cumul_stopTime(parameters,lap_times,this_replayed_track,all_forwardLocal_events);
        TRACKS.LocalFwd_Lap_Num_cumulSec{TRACK_k}= NumFwd_lap;
        TRACKS.LocalFwd_binnedSpeed_lap_cumulSec{TRACK_k}= binnedSpeed_lap;

        [NumRev_lap,binnedSpeed_lap,~]= get_events_lap_cumul_stopTime(parameters,lap_times,this_replayed_track,all_reverseLocal_events);
        TRACKS.LocalRev_Lap_Num_cumulSec{TRACK_k}= NumRev_lap;
        TRACKS.LocalRev_binnedSpeed_lap_cumulSec{TRACK_k}= binnedSpeed_lap;

        % per minute immobile on track
        % local
        [temporalNum,temporalRate,~,t_bins]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,all_local_events,[],'thisEpoch',this_replayed_track);
         TRACKS.local_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.local_num_min_immobile{TRACK_k}= temporalNum;
         TRACKS.t_bins_min_immobile{TRACK_k}= t_bins;
         % remote n-1
         [temporalNum,temporalRate,~]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,all_remote_events_n1,[],'thisEpoch',this_replayed_track);
         TRACKS.remote_n1_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.remote_n1_num_min_immobile{TRACK_k}= temporalNum;
         % remote n-2
         [temporalNum,temporalRate,~]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,all_remote_events_n2,[],'thisEpoch',this_replayed_track);
         TRACKS.remote_n2_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.remote_n2_num_min_immobile{TRACK_k}= temporalNum;
         % future n1
         [temporalNum,temporalRate,~]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,future_n1_events,[],'thisEpoch',this_replayed_track);
         TRACKS.future_n1_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.future_n1_num_min_immobile{TRACK_k}= temporalNum;
         % future n2
         [temporalNum,temporalRate,~]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,future_n2_events,[],'thisEpoch',this_replayed_track);
         TRACKS.future_n2_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.future_n2_num_min_immobile{TRACK_k}= temporalNum;
         % cand events
         all_SWR_track= sorted_candidate_events.event_time.track(this_replayed_track).behaviour;
         [temporalNum,temporalRate,~]= getTemporalEvolution(5*60,2.5*60,10*60,'immobilityTRACK',this_replayed_track,...
                                        time_range,all_SWR_track,[],'thisEpoch',this_replayed_track);
         TRACKS.cand_events_rate_min_immobile{TRACK_k}= temporalRate;
         TRACKS.cand_events_num_min_immobile{TRACK_k}= temporalNum;

        % number of replays per lap and time spent immobile per lap
        numLaps= floor(length(lap_times(this_replayed_track).lap)/2); 
        numLocal_per_lap= arrayfun(@(x) sum(all_local_events >= lap_times(this_replayed_track).start(x) & ...
                                                 all_local_events <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numLocal_per_lap= arrayfun(@(x) sum(numLocal_per_lap(x:x+1)),1:2:numLaps*2);
        
        TRACKS.numLocal_per_lap{TRACK_k}= numLocal_per_lap;
        TRACKS.rateLocal_per_lap{TRACK_k}= numLocal_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};
        % at rew zone
        imm_per_lap_REWSITE= arrayfun(@(x) length(find(lap_times(this_replayed_track).end_zone(x).v_cm < parameters.speed_threshold_laps))*0.04,1:length(lap_times(this_replayed_track).end_zone));
        imm_per_lap_REWSITE= arrayfun(@(x) sum(imm_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.time_immobile_per_lap_REWSITE{TRACK_k}= imm_per_lap_REWSITE;
        numLocal_per_lap_REWSITE= arrayfun(@(x) sum(all_local_events >= lap_times(this_replayed_track).end_zone(x).t(1) & ...
                                            all_local_events <= lap_times(this_replayed_track).end_zone(x).t(end)),1:length(lap_times(this_replayed_track).lap));
        numLocal_per_lap_REWSITE= arrayfun(@(x) sum(numLocal_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.numLocal_per_lap_REWSITE{TRACK_k}= numLocal_per_lap_REWSITE;
        TRACKS.rateLocal_per_lap_REWSITE{TRACK_k}= numLocal_per_lap_REWSITE./TRACKS.time_immobile_per_lap_REWSITE{TRACK_k};

        % add other measures per lap: SWR, FWD, REV
        all_SWR_events= sorted_candidate_events.event_time.track(this_replayed_track).behaviour;
        numSWR_per_lap= arrayfun(@(x) sum(all_SWR_events >= lap_times(this_replayed_track).start(x) & ...
                                      all_SWR_events <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numSWR_per_lap= arrayfun(@(x) sum(numSWR_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numSWR_per_lap{TRACK_k}= numSWR_per_lap;
        TRACKS.rateSWR_per_lap{TRACK_k}= numSWR_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};
        numSWR_per_lap_REWSITE= arrayfun(@(x) sum(all_SWR_events >= lap_times(this_replayed_track).end_zone(x).t(1) & ...
                                            all_SWR_events <= lap_times(this_replayed_track).end_zone(x).t(end)),1:length(lap_times(this_replayed_track).lap));
        numSWR_per_lap_REWSITE= arrayfun(@(x) sum(numSWR_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.numSWR_per_lap_REWSITE{TRACK_k}= numSWR_per_lap_REWSITE;
        TRACKS.rateSWR_per_lap_REWSITE{TRACK_k}= numSWR_per_lap_REWSITE./TRACKS.time_immobile_per_lap_REWSITE{TRACK_k};

        numFWD_per_lap= arrayfun(@(x) sum(all_forwardLocal_events >= lap_times(this_replayed_track).start(x) & ...
                                      all_forwardLocal_events <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numFWD_per_lap= arrayfun(@(x) sum(numFWD_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numLocalFWD_per_lap{TRACK_k}= numFWD_per_lap;
        TRACKS.rateLocalFWD_per_lap{TRACK_k}= numFWD_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};
        
        numFWD_per_lap_REWSITE= arrayfun(@(x) sum(all_forwardLocal_events >= lap_times(this_replayed_track).end_zone(x).t(1) & ...
                                            all_forwardLocal_events <= lap_times(this_replayed_track).end_zone(x).t(end)),1:length(lap_times(this_replayed_track).lap));
        numFWD_per_lap_REWSITE= arrayfun(@(x) sum(numFWD_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.numLocalFWD_per_lap_REWSITE{TRACK_k}= numFWD_per_lap_REWSITE;
        TRACKS.rateLocalFWD_per_lap_REWSITE{TRACK_k}= numFWD_per_lap_REWSITE./TRACKS.time_immobile_per_lap_REWSITE{TRACK_k};

        numREV_per_lap= arrayfun(@(x) sum(all_reverseLocal_events >= lap_times(this_replayed_track).start(x) & ...
                                      all_reverseLocal_events <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numREV_per_lap= arrayfun(@(x) sum(numREV_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numLocalREV_per_lap{TRACK_k}= numREV_per_lap;
        TRACKS.rateLocalREV_per_lap{TRACK_k}= numREV_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};

        numREV_per_lap_REWSITE= arrayfun(@(x) sum(all_reverseLocal_events >= lap_times(this_replayed_track).end_zone(x).t(1) & ...
                                            all_reverseLocal_events <= lap_times(this_replayed_track).end_zone(x).t(end)),1:length(lap_times(this_replayed_track).lap));
        numREV_per_lap_REWSITE= arrayfun(@(x) sum(numREV_per_lap_REWSITE(x:x+1)),1:2:numLaps*2);
        TRACKS.numLocalREV_per_lap_REWSITE{TRACK_k}= numREV_per_lap_REWSITE;
        TRACKS.rateLocalREV_per_lap_REWSITE{TRACK_k}= numREV_per_lap_REWSITE./TRACKS.time_immobile_per_lap_REWSITE{TRACK_k};

        % remote per lap
        %n1
        numRemote_per_lap= arrayfun(@(x) sum(all_remote_events_n1 >= lap_times(this_replayed_track).start(x) & ...
                                      all_remote_events_n1 <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numRemote_per_lap= arrayfun(@(x) sum(numRemote_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numRemote_n1_per_lap{TRACK_k}= numRemote_per_lap;
        TRACKS.rateRemote_n1_per_lap{TRACK_k}= numRemote_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};
        %n2
        numRemote_per_lap= arrayfun(@(x) sum(all_remote_events_n2 >= lap_times(this_replayed_track).start(x) & ...
                                      all_remote_events_n2 <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numRemote_per_lap= arrayfun(@(x) sum(numRemote_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numRemote_n2_per_lap{TRACK_k}= numRemote_per_lap;
        TRACKS.rateRemote_n2_per_lap{TRACK_k}= numRemote_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};
        %all remote
        all_remote_events= [all_remote_events_n1 all_remote_events_n2];
        numRemote_per_lap= arrayfun(@(x) sum(all_remote_events >= lap_times(this_replayed_track).start(x) & ...
                                      all_remote_events <= lap_times(this_replayed_track).end(x)),1:length(lap_times(this_replayed_track).lap));
        numRemote_per_lap= arrayfun(@(x) sum(numRemote_per_lap(x:x+1)),1:2:numLaps*2);
        TRACKS.numRemote_per_lap{TRACK_k}= numRemote_per_lap;
        TRACKS.rateRemote_per_lap{TRACK_k}= numRemote_per_lap./TRACKS.time_immobile_per_lap{TRACK_k};

        % LOCAL forward/reverse overall time on track
        TRACKS.LocalForward_replay_number(TRACK_k)= length(all_forwardLocal_events);
        TRACKS.LocalForward_replay_rate(TRACK_k)= TRACKS.LocalForward_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.LocalForward_replay_meanWScore(TRACK_k)= mean(Wscore_forwardLocal_events);

        TRACKS.LocalReverse_replay_number(TRACK_k)= length(all_reverseLocal_events);
        TRACKS.LocalReverse_replay_rate(TRACK_k)= TRACKS.LocalReverse_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.LocalReverse_replay_meanWScore(TRACK_k)= mean(Wscore_reverseLocal_events);

        TRACKS.totalNumEventsTrack(TRACK_k)=  sum(arrayfun(@(x) length(sorted_replay(x).event_time.immobilityTRACK(this_replayed_track).behaviour),1:length(sorted_replay)));
        TRACKS.totalRateEventsTrack(TRACK_k)= TRACKS.totalNumEventsTrack(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);

        % remote
        % n-1
        TRACKS.remote_n1_replay_number(TRACK_k)= length(all_remote_events_n1);
        TRACKS.remote_n1_replay_rate(TRACK_k)= TRACKS.remote_n1_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.remote_n1_replay_meanWScore(TRACK_k)= mean(Wscore_remote_events_n1);
        % n-2
        TRACKS.remote_n2_replay_number(TRACK_k)= length(all_remote_events_n2);
        TRACKS.remote_n2_replay_rate(TRACK_k)= TRACKS.remote_n2_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.remote_n2_replay_meanWScore(TRACK_k)= mean(Wscore_remote_events_n2);
        % future n+1
        TRACKS.future_n1_replay_number(TRACK_k)= length(future_n1_events);
        TRACKS.future_n1_replay_rate(TRACK_k)= TRACKS.future_n1_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.future_n1_replay_meanWScore(TRACK_k)= mean(Wscore_future_n1_events);
        % future n+2
        TRACKS.future_n2_replay_number(TRACK_k)= length(future_n2_events);
        TRACKS.future_n2_replay_rate(TRACK_k)= TRACKS.future_n2_replay_number(TRACK_k)./TRACKS.LocalTrack_duration(TRACK_k);
        TRACKS.future_n2_replay_meanWScore(TRACK_k)= mean(Wscore_future_n2_events);
        
        % local remote per lap
        lap_immdur= NaN(1,10); localLap_rate=NaN(1,10); localLap_quality=NaN(1,10); localLap_num=NaN(1,10);
        remoten1Lap_rate= NaN(1,10); remoten2Lap_rate=NaN(1,10); remoten1Lap_num= NaN(1,10); remoten2Lap_num=NaN(1,10);
        future_n1_Lap_rate= NaN(1,10); future_n2_Lap_rate= NaN(1,10); futureLap_rate= NaN(1,10);
        future_n1_Lap_quality= NaN(1,10); future_n2_Lap_quality= NaN(1,10); futureLap_quality= NaN(1,10);
        remoten1Lap_quality= NaN(1,10); remoten2Lap_quality= NaN(1,10);
        kk=1;
        for this_lap=1:2:19
            % do full laps (back and forth)
            try
            lap_immdur(kk)= (sum(lap_times(this_replayed_track).lap(this_lap).v_cm < parameters.speed_threshold_laps) +...
                            sum(lap_times(this_replayed_track).lap(this_lap+1).v_cm < parameters.speed_threshold_laps))*0.04;

            % local
            lTmp= (all_local_events >= lap_times(this_replayed_track).start(this_lap) & ...
                all_local_events <= lap_times(this_replayed_track).end(this_lap)) |...
                (all_local_events >= lap_times(this_replayed_track).start(this_lap+1) & ...
                all_local_events <= lap_times(this_replayed_track).end(this_lap+1));
            localLap_num(kk)= sum(lTmp);
            localLap_rate(kk)= sum(lTmp)./lap_immdur(kk);
            localLap_quality(kk)= mean(Wscore_local_events(lTmp));
            % remote n1
            r1Tmp= (all_remote_events_n1 >= lap_times(this_replayed_track).start(this_lap) & ...
                all_remote_events_n1 <= lap_times(this_replayed_track).end(this_lap)) |...
                (all_remote_events_n1 >= lap_times(this_replayed_track).start(this_lap+1) & ...
                all_remote_events_n1 <= lap_times(this_replayed_track).end(this_lap+1));
            remoten1Lap_num(kk)= sum(r1Tmp);
            remoten1Lap_rate(kk)= sum(r1Tmp)./lap_immdur(kk);
            remoten1Lap_quality(kk)= mean(Wscore_remote_events_n1(r1Tmp));
            % remote n2
            r2Tmp= (all_remote_events_n2 >= lap_times(this_replayed_track).start(this_lap) & ...
                all_remote_events_n2 <= lap_times(this_replayed_track).end(this_lap)) |...
                (all_remote_events_n2 >= lap_times(this_replayed_track).start(this_lap+1) & ...
                all_remote_events_n2 <= lap_times(this_replayed_track).end(this_lap+1));
            remoten2Lap_num(kk)= sum(r2Tmp);
            remoten2Lap_rate(kk)= sum(r2Tmp)./lap_immdur(kk);
            remoten2Lap_quality(kk)= mean(Wscore_remote_events_n2(r2Tmp));
            % future n1
            fTmp= (future_n1_events >= lap_times(this_replayed_track).start(this_lap) & ...
                future_n1_events <= lap_times(this_replayed_track).end(this_lap)) |...
                (future_n1_events >= lap_times(this_replayed_track).start(this_lap+1) & ...
                future_n1_events <= lap_times(this_replayed_track).end(this_lap+1));
            future_n1_Lap_rate(kk)= sum(fTmp)./lap_immdur(kk);
            future_n1_Lap_quality(kk)= mean(Wscore_future_n1_events(fTmp));
            % future n2 
            fTmp= (future_n2_events >= lap_times(this_replayed_track).start(this_lap) & ...
                future_n2_events <= lap_times(this_replayed_track).end(this_lap)) |...
                (future_n2_events >= lap_times(this_replayed_track).start(this_lap+1) & ...
                future_n2_events <= lap_times(this_replayed_track).end(this_lap+1));
            future_n2_Lap_rate(kk)= sum(fTmp)./lap_immdur(kk);
            future_n2_Lap_quality(kk)= mean(Wscore_future_n2_events(fTmp));
            % future
            future= [future_n1_events future_n2_events];
            Wfuture_score= [Wscore_future_n1_events Wscore_future_n2_events];
            fTmp= (future >= lap_times(this_replayed_track).start(this_lap) & ...
                future <= lap_times(this_replayed_track).end(this_lap)) |...
                (future >= lap_times(this_replayed_track).start(this_lap+1) & ...
                future <= lap_times(this_replayed_track).end(this_lap+1));
            futureLap_rate(kk)= sum(fTmp)./lap_immdur(kk);
            futureLap_quality(kk)= mean(Wfuture_score(fTmp));
            end

            kk=kk+1;
        end
        TRACKS.local_Lap_rate{TRACK_k}= localLap_rate;
        TRACKS.local_Lap_num{TRACK_k}= localLap_num;
        TRACKS.local_Lap_quality{TRACK_k}= localLap_quality;
        TRACKS.remote_n1_Lap_rate{TRACK_k}= remoten1Lap_rate;
        TRACKS.remote_n1_Lap_num{TRACK_k}= remoten1Lap_num;
        TRACKS.remote_n1_quality{TRACK_k}= remoten1Lap_quality;
        TRACKS.remote_n2_Lap_rate{TRACK_k}= remoten2Lap_rate;
        TRACKS.remote_n2_Lap_num{TRACK_k}= remoten2Lap_num;
        TRACKS.remote_n2_quality{TRACK_k}= remoten2Lap_quality;
        TRACKS.future_Lap_rate{TRACK_k}= futureLap_rate;
        TRACKS.future_Lap_quality{TRACK_k}= futureLap_quality;
        TRACKS.future_n1_Lap_rate{TRACK_k}= future_n1_Lap_rate;
        TRACKS.future_n1_Lap_quality{TRACK_k}= future_n1_Lap_quality;
        TRACKS.future_n2_Lap_rate{TRACK_k}= future_n2_Lap_rate;
        TRACKS.future_n2_Lap_quality{TRACK_k}= future_n2_Lap_quality;

        TRACK_k= TRACK_k+1;
    end

    cd(data_folder)

end

save(fullfile(data_folder,'NEW_TABLES','CANDIDATE_EVENTS.mat'),'CANDIDATE');
save(fullfile(data_folder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'),'TRACKS');
save(fullfile(data_folder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'),'REST');
save(fullfile(data_folder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'),'SLEEP');

end


function [temporalNum,temporalRate,temporalQuality,timeBinsCtrs]= getTemporalEvolution(sleepTimeBin,stepSize,maxSleepTime,state_time_range,thisTrack,time_range,sorted_events,var_to_observe,varargin)

p= inputParser;
addParameter(p,'thisEpoch',[]);
addParameter(p,'output','rate');
parse(p,varargin{:});

if isempty(p.Results.thisEpoch)
    cumul_t= cumsum(time_range.(state_time_range)(:,2) - time_range.(state_time_range)(:,1));
else % allows to only calculate for part of time range
    if isstruct(time_range.(state_time_range))
        fname= fieldnames(time_range.(state_time_range));
        fname= fname{1};
        time_range.(state_time_range)= time_range.(state_time_range)(p.Results.thisEpoch).(fname);
        cumul_t= cumsum(time_range.(state_time_range)(:,2) - time_range.(state_time_range)(:,1));
    else
        cumul_t= cumsum(time_range.(state_time_range)(p.Results.thisEpoch,2) - time_range.(state_time_range)(p.Results.thisEpoch,1));
        time_range.(state_time_range)= time_range.(state_time_range)(p.Results.thisEpoch,:);
    end
end

t_bins= 0:stepSize:maxSleepTime-sleepTimeBin;
t_intervals= [t_bins' (t_bins+sleepTimeBin)'];
timeBinsCtrs= t_intervals(:,1)+ (t_intervals(:,2)-t_intervals(:,1))/2;

temporalRate= NaN(1,length(timeBinsCtrs));
temporalNum= NaN(1,length(timeBinsCtrs));
temporalQuality= NaN(1,length(timeBinsCtrs));

for this_interval=1:size(t_intervals,1)
   % find corresponding start and stop
   x_min= t_intervals(this_interval,1);
   min_t= find(cumul_t>=x_min,1,'first');
   t_start= time_range.(state_time_range)(min_t,2) - (cumul_t(min_t)-x_min);

   x_max=  t_intervals(this_interval,2);
   max_t= find(cumul_t>=x_max,1,'first');
   t_stop= time_range.(state_time_range)(max_t,2) - (cumul_t(max_t)-x_max);
   if ~isempty(t_stop) && ~isempty(t_start)
    time_spent= diff(t_intervals(this_interval,:));
    if isempty(var_to_observe) && ismatrix(sorted_events) % pass a vector of event times for sorted_events
        if p.Results.output == "rate"
            temporalNum(this_interval)= numel(find(sorted_events >= t_start &...
                                                sorted_events <= t_stop));
        end
    else
        if isstruct(sorted_events(thisTrack).event_time.(var_to_observe))
            % find fields
            fname= fieldnames(sorted_events(thisTrack).event_time.(var_to_observe));
            fname= fname{1};
            tmp_sorted= sorted_events(thisTrack).event_time.(var_to_observe)(p.Results.thisEpoch).(fname);
            temporalNum(this_interval)= numel(find(tmp_sorted >= t_start & tmp_sorted <= t_stop)); 

            if isfield(sorted_events,'replay_score')
                fname= fieldnames(sorted_events(thisTrack).replay_score.(var_to_observe));
                fname= fname{1};
                tmpQual_sorted= sorted_events(thisTrack).replay_score.(var_to_observe)(p.Results.thisEpoch).(fname);
                temporalQuality(this_interval)= mean(tmpQual_sorted(tmp_sorted >= t_start & tmp_sorted <= t_stop));
            end

        else
            temporalNum(this_interval)= numel(find(sorted_events(thisTrack).event_time.(var_to_observe) >= t_start &...
                                            sorted_events(thisTrack).event_time.(var_to_observe) <= t_stop)); 
            if isfield(sorted_events,'replay_score')
                tmpQual= sorted_events(thisTrack).replay_score.(var_to_observe);
                temporalQuality(this_interval)= mean(tmpQual(sorted_events(thisTrack).event_time.(var_to_observe) >= t_start &...
                                                sorted_events(thisTrack).event_time.(var_to_observe) <= t_stop)); 
            end
        end
    end
    temporalRate(this_interval)= temporalNum(this_interval)/time_spent; 
   end
end

end


function [NumReplay_lap,binnedSpeed_lap,maxStopTime_lap]= get_events_lap_cumul_stopTime(parameters,lap_times,thisTrack,all_events)
% Get distribution of replay rates as a function of cumulative stop time at
% end zones

    binEdges= 0:0.5:20;
    binCtrs= binEdges(1:end-1)+mean(diff(binEdges))/2;
    numLaps= lap_times(thisTrack).total_number_of_laps;
    NumReplay_lap= NaN(numLaps,length(binCtrs));
    binnedSpeed_lap= NaN(numLaps,length(binCtrs));
    maxStopTime_lap= NaN(numLaps,1);
    k=1;
    for this_lap=1:numLaps
        % for each zone in a lap (1 zones per lap) get cumulative stopping
        % time
        NumReplay_lapZone= NaN(length(binCtrs));
        binnedSpeed_lapZone= NaN(length(binCtrs));
        maxStopTime_lapZone= NaN(length(binCtrs));

        lap_t= [lap_times(thisTrack).end_zone(this_lap).t];
        lap_v= [lap_times(thisTrack).end_zone(this_lap).v_cm];
        stopping_log= lap_v < parameters.speed_threshold_laps;

        [start_idx,stop_idx]= getIntervals(stopping_log);
        stops= [lap_t(start_idx)' lap_t(stop_idx)'];
        stop_dur= cumsum(stops(:,2)- stops(:,1));
        stop_dur2= [[ 0; stop_dur(1:end-1)] stop_dur(1:end)];

        % get speed in cumulative stops
        stop_v= lap_v(stopping_log);
        stop_t= lap_t(stopping_log);
        cum_time= nan(size(stop_t));
        for i = 1:size(stops,1)
            % indices of samples within this stop
            idx= stop_t >= stops(i,1) & stop_t < stops(i,2);
            if ~any(idx), continue; end
            % map to cumulative stop time
            t_rel= stop_t(idx) - stops(i,1);  % relative within this stop
            total_stop_len= stops(i,2) - stops(i,1);
            cum_len= stop_dur2(i,2) - stop_dur2(i,1);
            % scale to cumulative duration segment
            cum_time(idx)= stop_dur2(i,1) + (t_rel / total_stop_len) * cum_len;
        end
        % Remove samples not in any stop
        valid= ~isnan(cum_time);
        cum_time= cum_time(valid);
        stop_v= stop_v(valid);
        % Compute median speed in each cumulative-time bin
        [~,~,binIdx]= histcounts(cum_time, binEdges);
        binnedSpeed_lapZone= accumarray(binIdx(binIdx>0)', stop_v(binIdx>0)', [numel(binEdges)-1, 1], @median, NaN)';

        % get events in cumulative stops
        shifted_events= [];
        for jj=1:length(start_idx) % I know there is a faster way
            idx= all_events >= stops(jj,1) & all_events <=  stops(jj,2);
            if ~isempty(idx)
                % Shift to cumulative time
                shifted_events= [shifted_events all_events(idx) - stops(jj,1) + stop_dur(jj,1)];
            end
        end

        NumReplay_lapZone= histcounts(shifted_events, binEdges);
        NumReplay_lapZone(binCtrs>max(stop_dur))= NaN;
        NumReplay_lap(k,~isnan(NumReplay_lapZone))= NumReplay_lapZone(~isnan(NumReplay_lapZone));
        binnedSpeed_lap(k,binCtrs<max(stop_dur))= binnedSpeed_lapZone(binCtrs<max(stop_dur));
        maxStopTime_lapZone= binCtrs(histcounts(max(stop_dur),binEdges)>0);
        if max(stop_dur) >20
            maxStopTime_lapZone= 20;
        end
        if ~isempty(maxStopTime_lapZone)
            maxStopTime_lap(k)= maxStopTime_lapZone;
        end

        k= k+1;
    end

end