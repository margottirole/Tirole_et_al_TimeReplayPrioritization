function Replays= buildTableModel(opts,folders)

load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));

Replays = table; k = 1;
warning('off');

dt = 60; % seconds 
for this_folder = 1:length(folders)

    load(fullfile(opts.dataFolder,folders{this_folder},'significant_replay_events_wcorr.mat'));
    load(fullfile(opts.dataFolder,folders{this_folder},'sorted_replay_wcorr.mat'));
    load(fullfile(opts.dataFolder,folders{this_folder},'extracted_position.mat'));
    load(fullfile(opts.dataFolder,folders{this_folder},'time_range.mat'));

    curr_sess = strsplit(folders{this_folder},'\');
    curr_rat  = string(curr_sess{1});
    curr_sess = string(curr_sess{2});

    for thisT=1:3

        idx= SLEEP.session == curr_sess & SLEEP.track == thisT;

        % sleep timestamps
        time_range.NREM_REM_POST= sortrows([time_range.NREM_POST; time_range.REM_POST]);

        Replays.rat(k)= curr_rat;
        Replays.session(k)= curr_sess;
        Replays.track(k)= thisT;
        Replays.dt(k)= dt;  
  
        % epochs timestamps
        Replays.startSessionTs(k)= time_range.pre(1,1);
        Replays.trackTs{k}= time_range.track;
        Replays.restTs{k}= [time_range.rest; [time_range.post(1) time_range.NREM_REM_POST(1,1)]];
        Replays.SleepTs{k}= time_range.NREM_REM_POST;

        % events: local online
        Replays.localOnlineEvents{k}= sorted_replay(thisT).event_time.track(thisT).behaviour;

        % create time vector and bins
        t= Replays.startSessionTs(k):dt:Replays.SleepTs{k}(1,1);
        edges= [t t(end)+dt];
        Replays.binCtrs{k}= edges(1:end-1) + dt/2;

        track_idx= Replays.binCtrs{k} >= Replays.trackTs{k}(thisT,1) & Replays.binCtrs{k} <= Replays.trackTs{k}(thisT,2);
        Replays.binCtrs_TrackOnly{k}= Replays.binCtrs{k}(track_idx);

        Replays.localOnlineRate{k}= histcounts(Replays.localOnlineEvents{k}, edges)./dt;
        Replays.localOnlineRate_TrackOnly{k}= Replays.localOnlineRate{k}(track_idx);

        smoothBins= 5; 
        Replays.localOnlineRate_smooth{k}= movmean(Replays.localOnlineRate{k},[smoothBins-1 0],'omitnan');
        Replays.localOnlineRate_smooth_TrackOnly{k}= Replays.localOnlineRate_smooth{k}(track_idx);

        % subsequent events on tracks after 
        subsequentT= arrayfun(@(x) sorted_replay(thisT).event_time.track(x).behaviour,thisT+1:length(sorted_replay(thisT).event_time.track),'UniformOutput', false);
        subsequentT_ID= arrayfun(@(x) x*ones(size(sorted_replay(thisT).event_time.track(x).behaviour)),thisT+1:length(sorted_replay(thisT).event_time.track),'UniformOutput', false);

        % subsequent events during following rests
        subsequentRest= [arrayfun(@(x) sorted_replay(thisT).event_time.REST(x).rest, thisT:2,'UniformOutput',false),...
                        sorted_replay(thisT).event_time.post(sorted_replay(thisT).event_time.post < time_range.NREM_REM_POST(1,1))];
        subsequentRest_ID= [arrayfun(@(x) (10+x)*ones(size(sorted_replay(thisT).event_time.REST(x).rest)),thisT:2,'UniformOutput',false),...
                             13*ones(size(sorted_replay(thisT).event_time.post(sorted_replay(thisT).event_time.post < time_range.NREM_REM_POST(1,1))))];

        % sort in time
        [subAll,I]= sort([subsequentT{:} subsequentRest{:}]);
        subId= [subsequentT_ID{:} subsequentRest_ID{:}];

        Replays.subsequentEvents{k}= subAll;
        Replays.subsequentEvents_ID{k}= subId(I);
        Replays.sleepEvents{k}= sort([sorted_replay(thisT).event_time.NREM_POST sorted_replay(thisT).event_time.REM_POST]);

        Replays.spkCount_localOnline{k}= histcounts(Replays.localOnlineEvents{k},edges); % binned
        Replays.spkCount_localOnline_TrackOnly{k}= Replays.spkCount_localOnline{k}(track_idx);

        Replays.spkCount_subsequentOnline{k}= histcounts(Replays.subsequentEvents{k}(ismember(Replays.subsequentEvents_ID{k},1:3)),edges); % binned
        Replays.spkCount_subsequentAll{k}= histcounts(Replays.subsequentEvents{k},edges);

        % sleep POST and rest 3 rates
        Replays.sleepPOSTrate(k)= SLEEP.NremRemPOSTreplayRate_0_to_900{idx};
        Replays.rest3rate(k)= REST.replayRate(REST.session == curr_sess & REST.track == thisT & REST.rest==3);

        k= k+1;
    end
end
warning('on');

end