function regressreplayChange= regress_replayChangeMap(folders)

warning('off')
load('reward_conditions.mat');
parameters= list_of_parameters;
regressreplayChange= table;
COUNTER_K=1;

for this_folder=1:length(folders)

    % load files
    load(fullfile(folders{this_folder},'sorted_replay_wcorr.mat'));
    load(fullfile(folders{this_folder},'significant_replay_events_wcorr.mat'));
    load(fullfile(folders{this_folder},'extracted_place_fields_BAYESIAN.mat'));
    load(fullfile(folders{this_folder},'extracted_laps.mat'));
    load(fullfile(folders{this_folder},'extracted_clusters.mat'));
    load(fullfile(folders{this_folder},'extracted_position.mat'));

    curr_sess= strsplit(folders{this_folder},'\');
    curr_rat= curr_sess(1);  curr_sess= curr_sess(2);
    sess_idx= contains(reward_condition.session,curr_sess);

    % restrict to tracks
    for thisT=1:3
        %% find reward
        reward= reward_condition.(['track' num2str(thisT)]){sess_idx};
        if strcmp(reward,'chocolate')
            curr_reward= "HIGH";
        elseif strcmp(reward,'diluted')
            curr_reward= "LOW";
        end

        %% find cells categories
        if thisT>1 % previous tracks only
            cell_prev_tracks= unique([place_fields_BAYESIAN.track(1:thisT-1).good_cells]);
            changing_cells= setxor(cell_prev_tracks,place_fields_BAYESIAN.track(thisT).good_cells);
            past_cells= intersect(changing_cells,cell_prev_tracks);
        else
            past_cells=[];
        end
        if thisT>1 % emerging cells
            cell_prev_tracks= unique([place_fields_BAYESIAN.track(1:thisT-1).good_cells]);
            changing_cells= setxor(cell_prev_tracks,place_fields_BAYESIAN.track(thisT).good_cells);
            novel_cells= intersect(changing_cells,place_fields_BAYESIAN.track(thisT).good_cells);
        else
            novel_cells= place_fields_BAYESIAN.track(thisT).good_cells;
        end
        if thisT>1 % cells that are/will be active on current track and another
            cell_prev_tracks= unique([place_fields_BAYESIAN.track(1:thisT-1).good_cells]);
            both_cells= intersect(cell_prev_tracks,place_fields_BAYESIAN.track(thisT).good_cells);
        else
            cell_future_tracks= unique([place_fields_BAYESIAN.track(thisT+1:end).good_cells]);
            both_cells= intersect(place_fields_BAYESIAN.track(thisT).good_cells,cell_future_tracks);
        end
        all_good_cells= place_fields_BAYESIAN.good_place_cells;

        %% get ratemap change between laps, and figure out replay events
        maxLaps=10;
        lap_counter=1;
        for thisLap=1:2:2*maxLaps
            % two full laps, separated in 2 , keeping only middle
            % end zone
            if thisLap+3 < length(lap_times(thisT).start)
                t_start= [lap_times(thisT).start(thisLap) lap_times(thisT).start(thisLap+2)];
                t_end= [lap_times(thisT).end(thisLap+1) lap_times(thisT).end(thisLap+3)];
    
                % get ratemap changes all cells
                [ratemaps,pkHz,pkLoc]= getRateMap(parameters,position,clusters,thisT,place_fields_BAYESIAN.track(thisT).good_cells,t_start,t_end);
                % keep only replays inside two zones
                localReplayTs= sorted_replay(thisT).event_time.track(thisT).behaviour;
                localReplayRefIdx= sorted_replay(thisT).ref_index.track(thisT).behaviour;
                keepIdx= localReplayTs >= min(lap_times(thisT).end_zone(thisLap).t) &  localReplayTs <= max(lap_times(thisT).end_zone(thisLap+1).t);
                localReplayTs(~keepIdx)=[];
                localReplayRefIdx(~keepIdx)=[];
    
                if thisT>1
                    remoteReplayTs= cell2mat(arrayfun(@(x) sorted_replay(x).event_time.track(thisT).behaviour,1:thisT-1,'UniformOutput',0));
                    remoteReplayRefIdx= cell2mat(arrayfun(@(x) sorted_replay(x).ref_index.track(thisT).behaviour,1:thisT-1,'UniformOutput',0));
                    remoteReplayTIdx= cell2mat(arrayfun(@(x) x*ones(size(sorted_replay(x).ref_index.track(thisT).behaviour)),1:thisT-1,'UniformOutput',0));
                    keepIdx= remoteReplayTs >= t_start(1) &  remoteReplayTs <= min(lap_times(thisT).end_zone(thisLap+1).t);
                    remoteReplayTs(~keepIdx)=[];
                    remoteReplayRefIdx(~keepIdx)=[];
                    remoteReplayTIdx(~keepIdx)=[];
                else
                    remoteReplayTs= []; remoteReplayRefIdx=[]; remoteReplayTIdx=[];
                end
                % for each replay event keep track of which cells were active
                spikesLocal=[];
                for thisL= 1:length(localReplayTs)
                    spkTmp= significant_replay_events.track(thisT).spikes{...
                                significant_replay_events.track(thisT).ref_index == localReplayRefIdx(thisL)};
                    spkTmp= unique(spkTmp(:,1)); % just care if active, ignore how many times it spiked for now
                    spikesLocal= [spikesLocal; spkTmp] ;
                end
                spikesRemote=[];
                for thisL= 1:length(remoteReplayTs)
                    spkTmp= significant_replay_events.track(remoteReplayTIdx(thisL)).spikes{...
                                significant_replay_events.track(remoteReplayTIdx(thisL)).ref_index == remoteReplayRefIdx(thisL)};
                    spkTmp= unique(spkTmp(:,1));
                    spikesRemote= [spikesRemote; spkTmp] ;
                end
    
                for thisCell=1:length(place_fields_BAYESIAN.track(thisT).good_cells)
                    cellid= place_fields_BAYESIAN.track(thisT).good_cells(thisCell);
                    if ismember(cellid,novel_cells)
                        cellcat= "novel";
                    elseif ismember(cellid,both_cells)
                        cellcat= "both";
                    else
                        cellcat= "unspecified";
                    end
                    availBins= ~isnan(ratemaps{thisCell,1}) & ~isnan(ratemaps{thisCell,2});
                    if sum(availBins)>=10 % at least 10binsto compare
                        fieldCorr= corr(ratemaps{thisCell,1}(availBins)', ratemaps{thisCell,2}(availBins)','type','pearson');
                    else
                        fieldCorr= NaN; % corr not reliable
                    end
                    peakDistShift= abs(pkLoc(thisCell,2) - pkLoc(thisCell,1));
                    peakHzShift= abs(pkHz(thisCell,2) - pkHz(thisCell,1));
                    numLocalActive= sum(spikesLocal == cellid);
                    numRemoteActive= sum(spikesRemote == cellid);
    
                    regressreplayChange.rat(COUNTER_K)= curr_rat;
                    regressreplayChange.session(COUNTER_K)= curr_sess;
                    regressreplayChange.reward(COUNTER_K)= curr_reward;
                    regressreplayChange.track(COUNTER_K)= thisT;
                    regressreplayChange.lap_number(COUNTER_K)= floor(thisLap/2)+1;
                    regressreplayChange.cellid(COUNTER_K)= cellid;
                    regressreplayChange.cellcat(COUNTER_K)= cellcat;
                    regressreplayChange.fieldCorr(COUNTER_K)= fieldCorr;
                    regressreplayChange.peakDistShift(COUNTER_K)= peakDistShift;
                    regressreplayChange.peakHzShift(COUNTER_K)= peakHzShift;
                    regressreplayChange.numLocalActive(COUNTER_K)= numLocalActive;
                    regressreplayChange.numRemoteActive(COUNTER_K)= numRemoteActive;
    
                    COUNTER_K= COUNTER_K+1;
                end
            end
        end
    end
end

save(fullfile('NEW_TABLES','changingMaps','regressReplayChange.mat'),'regressreplayChange');
writetable(regressreplayChange,fullfile('NEW_TABLES','changingMaps','regressReplayChange.csv'));
end


function [ratemaps,peakHz,peakLoc]= getRateMap(parameters,position,clusters,thisT,cellids,t_start,t_end)
% returns one rate map per [start stop]

ratemaps= cell(length(cellids),length(t_start));
peakHz= NaN(length(cellids),length(t_start));
peakLoc= NaN(length(cellids),length(t_start));

    if length(t_start) ~= length(t_end)
        error('wrong size inputs [start end]');
    end
    time_bin_width=position.t(2)-position.t(1);
    x_bin_edges = 0:parameters.x_bins_width_bayesian:100*position.linear(thisT).length; % forces x_bins to be from 0 to 200cm
    x_bin_centres = [(x_bin_edges(2)-parameters.x_bins_width_bayesian/2):parameters.x_bins_width_bayesian:(x_bin_edges(end-1)+parameters.x_bins_width_bayesian/2)];
    x_bins = 0:parameters.x_bins_width_bayesian:(100*position.linear(thisT).length); %bin position

    for thisSt=1:length(t_start)

    t_idx= position.t >= t_start(thisSt) & position.t <= t_end(thisSt);

    position_index = isnan(position.linear(thisT).linear);
    position_speed = abs(position.v_cm);
    position_speed(position_index) = NaN;  %make sure speed is NaN if position is NaN

    % Time spent at each x_bin (speed filtered)
    x_hist = time_bin_width.*histcounts(position.linear(thisT).linear(find(t_idx & position_speed> parameters.speed_threshold_laps...
             & position_speed<parameters.speed_threshold_max)),x_bin_edges); 

    % reduce to spike times from cells
    spikeCellsTs= clusters.spike_times(ismember(clusters.spike_id,cellids) & clusters.spike_times >= t_start(thisSt) & clusters.spike_times <= t_end(thisSt));
    spikeCellsId= clusters.spike_id(ismember(clusters.spike_id,cellids) & clusters.spike_times >= t_start(thisSt) & clusters.spike_times <= t_end(thisSt));
    
    position_during_spike = interp1(position.t,position.linear(thisT).linear,spikeCellsTs,'nearest'); %interpolates position into spike time
    speed_during_spike = interp1(position.t,position_speed,spikeCellsTs,'nearest');

    
    for thisCell=1:length(cellids)
            spike_hist = histcounts(position_during_spike(find(spikeCellsId==cellids(thisCell) & ...
                                                        speed_during_spike>parameters.speed_threshold_laps &...
                                                        speed_during_spike<parameters.speed_threshold_max)),x_bin_edges); % Changed bin_centre to bin_edges
            % ratemap
            ratemaps{thisCell,thisSt} = spike_hist./x_hist; 
            [peakHz(thisCell,thisSt),peakLoc(thisCell,thisSt)]= max(ratemaps{thisCell,thisSt});

    end
    end

end