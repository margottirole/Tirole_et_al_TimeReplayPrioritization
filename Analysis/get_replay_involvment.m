function replay_involvment= get_replay_involvment(folders)
% consider replay events on tracks only: local or remote
% past cells, active both and novel cells

load('reward_conditions.mat');
parameters= list_of_parameters;
replay_involvment= table;
COUNTER_K=1;
warning('off');

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

    for thisT=1:3
        %% find cells
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
            active_both_cells= intersect(cell_prev_tracks,place_fields_BAYESIAN.track(thisT).good_cells);
        else
            cell_future_tracks= unique([place_fields_BAYESIAN.track(thisT+1:end).good_cells]);
            active_both_cells= intersect(place_fields_BAYESIAN.track(thisT).good_cells,cell_future_tracks);
        end

        missedOutCells= setxor(place_fields_BAYESIAN.track(thisT).good_cells,[active_both_cells novel_cells]);
        if ~isempty(missedOutCells)
            error('check cell assignments');
        end

        %% find replay events
        localreplay_refIdx= sorted_replay(thisT).ref_index.track(thisT).behaviour;
        localreplay_time= sorted_replay(thisT).event_time.track(thisT).behaviour;
        if thisT>1
            remotePastReplay_refIdx= cell2mat(arrayfun(@(x) sorted_replay(x).ref_index.track(thisT).behaviour,1:thisT-1,'UniformOutput',0));
            remotePastReplay_TrackIdx= cell2mat(arrayfun(@(x) x*ones(size(sorted_replay(x).ref_index.track(thisT).behaviour)),1:thisT-1,'UniformOutput',0));
            remotePastReplay_time= cell2mat(arrayfun(@(x) sorted_replay(x).event_time.track(thisT).behaviour,1:thisT-1,'UniformOutput',0));
        else
            remotePastReplay_refIdx= [];
            remotePastReplay_TrackIdx=[];
            remotePastReplay_time=[];
        end

        %% now get involvment of cell categories in replay
        maxLaps=10; 
        % initialise vars
        prop_involvment_past_cells_local_lap= NaN(1,2*maxLaps);
        prop_involvment_both_cells_local_lap= NaN(1,2*maxLaps);
        prop_involvment_novel_cells_local_lap= NaN(1,2*maxLaps);
        prop_involvment_past_cells_remote_lap= NaN(1,2*maxLaps);
        prop_involvment_both_cells_remote_lap= NaN(1,2*maxLaps);
        prop_involvment_novel_cells_remote_lap= NaN(1,2*maxLaps);
        prop_past_cells_local_lap= NaN(1,2*maxLaps);
        prop_both_cells_local_lap= NaN(1,2*maxLaps);
        prop_novel_cells_local_lap= NaN(1,2*maxLaps);
        prop_past_cells_remote_lap= NaN(1,2*maxLaps);
        prop_both_cells_remote_lap= NaN(1,2*maxLaps);
        prop_novel_cells_remote_lap= NaN(1,2*maxLaps);

        % do half laps
        for thisLap=1:2*maxLaps
            if thisLap <= length(lap_times(thisT).start)
            % find events in lap
            lapLocalReplayIdx= localreplay_refIdx(localreplay_time >= lap_times(thisT).start(thisLap) & localreplay_time <= lap_times(thisT).end(thisLap));
            if ~isempty(remotePastReplay_refIdx)
                lapRemoteReplayIdx= remotePastReplay_refIdx(remotePastReplay_time >= lap_times(thisT).start(thisLap) & remotePastReplay_time <= lap_times(thisT).end(thisLap));
                lapRemoteReplayTrackIdx= remotePastReplay_TrackIdx(remotePastReplay_time >= lap_times(thisT).start(thisLap) & remotePastReplay_time <= lap_times(thisT).end(thisLap));
            else
                lapRemoteReplayIdx=[];
            end

            % find if spikes in replay events
            invPastCells_Localtmp=[]; invNovelCells_Localtmp=[]; invBothCells_Localtmp=[];
            for thisEvent=1:length(lapLocalReplayIdx)
                refIdx= significant_replay_events.track(thisT).ref_index == lapLocalReplayIdx(thisEvent);
                spikesEvent= significant_replay_events.track(thisT).spikes{refIdx}; % fist column is cellid
                if ~isempty(past_cells)
                    invPastCells_Localtmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),past_cells);
                end
                invNovelCells_Localtmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),novel_cells);
                invBothCells_Localtmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),active_both_cells);
            end
            invPastCells_Remotetmp=[]; invNovelCells_Remotetmp=[]; invBothCells_Remotetmp=[];
            for thisEvent=1:length(lapRemoteReplayIdx)
                refIdx= significant_replay_events.track(lapRemoteReplayTrackIdx(thisEvent)).ref_index == lapRemoteReplayIdx(thisEvent);
                spikesEvent= significant_replay_events.track(lapRemoteReplayTrackIdx(thisEvent)).spikes{refIdx}; % fist column is cellid
                if ~isempty(past_cells)
                    invPastCells_Remotetmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),past_cells);
                end
                invNovelCells_Remotetmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),novel_cells);
                invBothCells_Remotetmp(:,thisEvent)= arrayfun(@(x) any(ismember(spikesEvent(:,1),x)),active_both_cells);
            end
            % percentage of replays cells are active in, local
            prop_involvment_past_cells_local_lap(thisLap)= mean(sum(invPastCells_Localtmp,2)./numel([lapLocalReplayIdx ]));
            prop_involvment_novel_cells_local_lap(thisLap)= mean(sum(invNovelCells_Localtmp,2)./numel([lapLocalReplayIdx ]));
            prop_involvment_both_cells_local_lap(thisLap)= mean(sum(invBothCells_Localtmp,2)./numel([lapLocalReplayIdx ]));
            % remote
            prop_involvment_past_cells_remote_lap(thisLap)= mean(sum(invPastCells_Remotetmp,2)./numel([ lapRemoteReplayIdx]));
            prop_involvment_novel_cells_remote_lap(thisLap)= mean(sum(invNovelCells_Remotetmp,2)./numel([ lapRemoteReplayIdx]));
            prop_involvment_both_cells_remote_lap(thisLap)= mean(sum(invBothCells_Remotetmp,2)./numel([ lapRemoteReplayIdx]));

            % percentage of cells in replay, local
            totalCellsActive= sum([sum(invPastCells_Localtmp,1); sum(invBothCells_Localtmp,1); sum(invNovelCells_Localtmp,1)],1);
            if ~isempty(past_cells)
                prop_past_cells_local_lap(thisLap)= mean(sum(invPastCells_Localtmp,1)./totalCellsActive);
            end
            prop_both_cells_local_lap(thisLap)= mean(sum(invBothCells_Localtmp,1)./totalCellsActive);
            prop_novel_cells_local_lap(thisLap)= mean(sum(invNovelCells_Localtmp,1)./totalCellsActive);
            % remote
            totalCellsActive= sum([sum(invPastCells_Remotetmp,1); sum(invBothCells_Remotetmp,1); sum(invNovelCells_Remotetmp,1)],1);
            if ~isempty(past_cells)
                prop_past_cells_remote_lap(thisLap)= mean(sum(invPastCells_Remotetmp,1)./totalCellsActive);
            end
            prop_both_cells_remote_lap(thisLap)= mean(sum(invBothCells_Remotetmp,1)./totalCellsActive);
            prop_novel_cells_remote_lap(thisLap)= mean(sum(invNovelCells_Remotetmp,1)./totalCellsActive);
            end
        end

        %% stabilisation and FR with laps
        curr_lap=1;
        both_cells_corr= nan(1,maxLaps); past_cells_corr= nan(1,maxLaps); novel_cells_corr= nan(1,maxLaps);

        both_idx= ismember(place_fields_BAYESIAN.good_place_cells, active_both_cells);
        past_idx= ismember(place_fields_BAYESIAN.good_place_cells, past_cells);
        novel_idx= ismember(place_fields_BAYESIAN.good_place_cells, novel_cells);

        both_cells_FR= nan(sum(both_idx),maxLaps); past_cells_FR= nan(sum(past_idx),maxLaps); novel_cells_FR= nan(sum(novel_idx),maxLaps); 

         for thisLap=1:2:2*maxLaps % compare full laps, slide by 1 full lap

             if thisLap+3 <= length(lap_times(thisT).end)
                 t_start= [lap_times(thisT).start(thisLap) lap_times(thisT).start(thisLap+2)];
                 t_end= [lap_times(thisT).end(thisLap+1) lap_times(thisT).end(thisLap+3)];
       
                % get ratemap changes all cells
                [ratemaps,pkHz,pkLoc]= getRateMap(parameters,position,clusters,thisT,place_fields_BAYESIAN.good_place_cells,t_start,t_end);
    
                % pop vector version
                maps1= cell2mat(ratemaps(both_idx,1));
                maps2=  cell2mat(ratemaps(both_idx,2));
                both_cells_corr(curr_lap)= median(arrayfun(@(x) corr(maps1(:,x),maps2(:,x),'type','pearson'),1:size(maps1,2)),'omitmissing');   
    
                maps1= cell2mat(ratemaps(past_idx,1));
                maps2=  cell2mat(ratemaps(past_idx,2));
                past_cells_corr(curr_lap)= median(arrayfun(@(x) corr(maps1(:,x),maps2(:,x),'type','pearson'),1:size(maps1,2)),'omitmissing');   
    
                maps1= cell2mat(ratemaps(novel_idx,1));
                maps2=  cell2mat(ratemaps(novel_idx,2));
                novel_cells_corr(curr_lap)= median(arrayfun(@(x) corr(maps1(:,x),maps2(:,x),'type','pearson'),1:size(maps1,2)),'omitmissing');   
    
                % FR - overwrites a column each time but is correct I think
                both_cells_FR(:,curr_lap)= pkHz(both_idx,1);
                past_cells_FR(:,curr_lap)= pkHz(past_idx,1);
                novel_cells_FR(:,curr_lap)= pkHz(novel_idx,1);

             end
             curr_lap= curr_lap+1;

         end


        %% store in table
        replay_involvment.rat(COUNTER_K)= curr_rat;
        replay_involvment.session(COUNTER_K)= curr_sess;
        replay_involvment.track(COUNTER_K)= thisT;
        reward= reward_condition.(['track' num2str(thisT)]){sess_idx};
        if strcmp(reward,'chocolate')
            replay_involvment.reward(COUNTER_K)= "HIGH";
        elseif strcmp(reward,'diluted')
            replay_involvment.reward(COUNTER_K)= "LOW";
        end
        replay_involvment.numPastcells(COUNTER_K)= numel(past_cells);
        replay_involvment.numBothcells(COUNTER_K)= numel(active_both_cells);
        replay_involvment.numNovelcells(COUNTER_K)= numel(novel_cells);
        replay_involvment.prop_involvment_past_cells_local_lap{COUNTER_K} = prop_involvment_past_cells_local_lap; 
        replay_involvment.prop_involvment_both_cells_local_lap{COUNTER_K} = prop_involvment_both_cells_local_lap; 
        replay_involvment.prop_involvment_novel_cells_local_lap{COUNTER_K} = prop_involvment_novel_cells_local_lap; 
        replay_involvment.prop_involvment_past_cells_remote_lap{COUNTER_K} = prop_involvment_past_cells_remote_lap; 
        replay_involvment.prop_involvment_both_cells_remote_lap{COUNTER_K} = prop_involvment_both_cells_remote_lap; 
        replay_involvment.prop_involvment_novel_cells_remote_lap{COUNTER_K} = prop_involvment_novel_cells_remote_lap; 
        replay_involvment.prop_past_cells_local_lap{COUNTER_K} = prop_past_cells_local_lap; 
        replay_involvment.prop_both_cells_local_lap{COUNTER_K} = prop_both_cells_local_lap; 
        replay_involvment.prop_novel_cells_local_lap{COUNTER_K} = prop_novel_cells_local_lap; 
        replay_involvment.prop_past_cells_remote_lap{COUNTER_K} = prop_past_cells_remote_lap; 
        replay_involvment.prop_both_cells_remote_lap{COUNTER_K} = prop_both_cells_remote_lap; 
        replay_involvment.prop_novel_cells_remote_lap{COUNTER_K} = prop_novel_cells_remote_lap; 

        replay_involvment.both_cells_corr{COUNTER_K} = both_cells_corr;
        replay_involvment.past_cells_corr{COUNTER_K} = past_cells_corr;
        replay_involvment.novel_cells_corr{COUNTER_K} = novel_cells_corr;

        replay_involvment.both_cells_FR{COUNTER_K}= both_cells_FR;
        replay_involvment.past_cells_FR{COUNTER_K}= past_cells_FR;
        replay_involvment.novel_cells_FR{COUNTER_K}= novel_cells_FR;

        COUNTER_K= COUNTER_K+1;
    end
end

save(fullfile('NEW_TABLES','replay_involvment.mat'),'replay_involvment');

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