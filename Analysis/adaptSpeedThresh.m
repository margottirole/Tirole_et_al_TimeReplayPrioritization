function TRACKS= adaptSpeedThresh(folders,speedThresh)

load('reward_conditions_ALL.mat');
parameters= list_of_parameters;
warning('off')

TRACKS= table;
TRACK_k= 1;

data_folder= pwd;
for this_folder=1:length(folders)

    cd([data_folder '\' folders{this_folder}]);
    load('extracted_laps.mat');
    load('extracted_position.mat');

    curr_sess= strsplit(folders{this_folder},'\');
    curr_rat= curr_sess(1);  curr_sess= curr_sess(2);
    sess_idx= contains(reward_condition.session,curr_sess);

    for thisTrack=1:length(lap_times)
    
            TRACKS.rat(TRACK_k)= curr_rat;
            TRACKS.session(TRACK_k)= curr_sess;
            TRACKS.session_number(TRACK_k)= reward_condition.session_number(sess_idx);
            TRACKS.track(TRACK_k)= thisTrack;
            reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
            if strcmp(reward,'chocolate')
                TRACKS.reward{TRACK_k}= 'HIGH';
            elseif strcmp(reward,'diluted')
                TRACKS.reward{TRACK_k}= 'LOW';
            end
    
            % BEHAVIOUR
            TRACKS.num_laps(TRACK_k)= lap_times(thisTrack).total_number_of_laps/2;
            TRACKS.time_on_track_min(TRACK_k)= (lap_times(thisTrack).end(end)-lap_times(thisTrack).start(1))/60;
            TRACKS.total_num_laps_per_min(TRACK_k)= TRACKS.num_laps(TRACK_k)/TRACKS.time_on_track_min(TRACK_k);
            % lap per min
            t= [lap_times(thisTrack).start(1):60:lap_times(thisTrack).end(end)] ;
            num_lap_min= [];
            for ii=1:length(t)-1
                    num_lap_min(ii)= sum(lap_times(thisTrack).end' <= t(ii+1));
            end
            TRACKS.cumul_num_lap_per_min{TRACK_k}= num_lap_min;
    
            numLaps= floor(length(lap_times(thisTrack).lap)/2);
            % total time immobile each zones
            endZones= lap_times(thisTrack).end_zones_coord;
            v_cm = position.v_cm;
            x= position.linear(thisTrack).linear;
            low_speed_idx= v_cm < speedThresh & ...
                             ~isnan(x) & ...
                            ((x>=endZones(1,1) & x<=endZones(1,2)) | (x>=endZones(2,1) & x<=endZones(2,2)));
            [start_idx,stop_idx]= getIntervals(low_speed_idx);
            TRACKS.time_end_zones_immobile(TRACK_k)= sum(position.t(stop_idx)- position.t(start_idx));
            % total time immobile per lap
            imm_per_lap= arrayfun(@(x) length(find(lap_times(thisTrack).lap(x).v_cm < speedThresh))*0.04,1:length(lap_times(thisTrack).lap));
            TRACKS.median_time_immobile_per_lap(TRACK_k)= median(imm_per_lap);
            imm_per_lap= arrayfun(@(x) sum(imm_per_lap(x:x+1)),1:2:numLaps*2);
            TRACKS.time_immobile_per_lap{TRACK_k}= imm_per_lap;
    
            % END ZONES time spent immobile per lap
            imm_per_lap= arrayfun(@(x) length(find(lap_times(thisTrack).end_zone(x).v_cm < speedThresh))*0.04,1:length(lap_times(thisTrack).end_zone));
            TRACKS.time_end_zones_immobile_per_lap{TRACK_k}= imm_per_lap;
            % END ZONES position during imm
            x_bin_edges = 0:parameters.x_bins_width:200;
            v_end= [lap_times(thisTrack).end_zone.v_cm];
            x_end= [lap_times(thisTrack).end_zone.x];
            pos_imm= x_end(v_end< speedThresh);
            TRACKS.POS_end_zones_immobile_per_lap{TRACK_k}= 0.04*histcounts(pos_imm,x_bin_edges);
            
            % RUN ZONES time immobile
            low_speed_idx= v_cm < speedThresh & ~isnan(x) & ...
                            (x>endZones(1,2) & x<endZones(2,1));
            [start_idx,stop_idx]= getIntervals(low_speed_idx);
            TRACKS.time_run_zones_immobile(TRACK_k)= sum(position.t(stop_idx)- position.t(start_idx));
            imm_per_lap= arrayfun(@(x) length(find(lap_times(thisTrack).run_zone(x).v_cm < speedThresh))*0.04,1:length(lap_times(thisTrack).run_zone));
            TRACKS.time_run_zones_immobile_per_lap{TRACK_k}= imm_per_lap;
           
            % RUN ZONES position during imm
            x_end= [lap_times(thisTrack).run_zone.x];
            v_end= [lap_times(thisTrack).run_zone.v_cm];
            pos_imm= x_end(v_end< speedThresh);
            TRACKS.POS_run_zones_immobile_per_lap{TRACK_k}= 0.04*histcounts(pos_imm,x_bin_edges);
    
            % speed per lap
            speed_per_lap= arrayfun(@(x) median(lap_times(thisTrack).lap(x).v_cm(lap_times(thisTrack).lap(x).v_cm>speedThresh)),1:length(lap_times(thisTrack).lap));
            TRACKS.median_speed_per_lap(TRACK_k)= median(speed_per_lap);
            speed_per_lap= arrayfun(@(x) median(speed_per_lap(x:x+1)),1:2:numLaps*2);
            TRACKS.speed_per_lap{TRACK_k}= speed_per_lap;
    
            % speedslow_per_lap= arrayfun(@(x) median(lap_times(thisTrack).lap(x).v_cm(lap_times(thisTrack).lap(x).v_cm<=speedThresh)),1:length(lap_times(thisTrack).lap));
            speedslow_per_lap= arrayfun(@(x) median(lap_times(thisTrack).end_zone(x).v_cm(lap_times(thisTrack).end_zone(x).v_cm<=speedThresh)),1:length(lap_times(thisTrack).end_zone));
            speedslow_per_lap= arrayfun(@(x) median(speedslow_per_lap(x:x+1)),1:2:numLaps*2);
            TRACKS.speedSLOW_per_lap{TRACK_k}= speedslow_per_lap;
    
            % speed immobile
            speed_imm_per_lap= arrayfun(@(x) median(lap_times(thisTrack).lap(x).v_cm(lap_times(thisTrack).lap(x).v_cm<=speedThresh)),1:length(lap_times(thisTrack).lap));
            speed_imm_per_lap= arrayfun(@(x) nanmedian(speed_imm_per_lap(x:x+1)),1:2:numLaps*2);
            TRACKS.speed_imm_per_lap{TRACK_k}= speed_imm_per_lap;

            % stopping speeds distr
            [binnedSpeed_lap,~]= get_events_lap_cumul_stopTime(speedThresh,lap_times,thisTrack);
            TRACKS.Local_binnedSpeed_lap_cumulSec{TRACK_k}= binnedSpeed_lap;


            TRACK_k= TRACK_k+1;
    end
end

cd(data_folder)
end




function [binnedSpeed_lap,maxStopTime_lap]= get_events_lap_cumul_stopTime(speedThresh,lap_times,thisTrack)
% Get distribution of replay rates as a function of cumulative stop time

    binEdges= [0:0.5:20];
    binCtrs= binEdges(1:end-1)+mean(diff(binEdges))/2;
    numLaps= floor(lap_times(thisTrack).total_number_of_laps/2);
    binnedSpeed_lap= NaN(numLaps,length(binCtrs));
    maxStopTime_lap= NaN(numLaps,length(binCtrs));
    k=1;
    for this_lap=1:2:2*numLaps
        % for each zone in a lap (2 zones per lap) get cumulative stopping
        % time
        binnedSpeed_lapZone= NaN(2,length(binCtrs));
        maxStopTime_lapZone= NaN(2,length(binCtrs));
        for ii=1:2
            lap_t= [lap_times(thisTrack).end_zone(this_lap+ii-1).t];
            lap_v= [lap_times(thisTrack).end_zone(this_lap+ii-1).v_cm];
            stopping_log= lap_v < speedThresh;

            [start_idx,stop_idx]= getIntervals(stopping_log);
            stops= [lap_t(start_idx)' lap_t(stop_idx)'];
            stop_dur= cumsum(stops(:,2)- stops(:,1));
            stop_dur2= [[ 0; stop_dur(1:end-1)] stop_dur(1:end)];

            % get speed in cumulative stops
            stop_v= lap_v(stopping_log);
            stop_t= lap_t(stopping_log);
            cum_time = nan(size(stop_t));
            for i = 1:size(stops,1)
                % indices of samples within this stop
                idx = stop_t >= stops(i,1) & stop_t < stops(i,2);
                if ~any(idx), continue; end
                % map to cumulative stop time
                t_rel = stop_t(idx) - stops(i,1);  % relative within this stop
                total_stop_len = stops(i,2) - stops(i,1);
                cum_len = stop_dur2(i,2) - stop_dur2(i,1);
                % scale to cumulative duration segment
                cum_time(idx) = stop_dur2(i,1) + (t_rel / total_stop_len) * cum_len;
            end
            % Remove samples not in any stop
            valid = ~isnan(cum_time);
            cum_time = cum_time(valid);
            stop_v = stop_v(valid);
            % Compute median speed in each cumulative-time bin
            [~,~,binIdx] = histcounts(cum_time, binEdges);
            if ~isempty(binIdx)
                binnedSpeed_lapZone(ii,:) = accumarray(binIdx(binIdx>0)', stop_v(binIdx>0)', [numel(binEdges)-1, 1], @median, NaN)';
            else
                binnedSpeed_lapZone(ii,:) = NaN;
            end

            maxStopTime_lapZone(ii,:)= histcounts(max(stop_dur),binEdges);
        end

        binnedSpeed_lap(k,:)= nanmedian(binnedSpeed_lapZone);
        maxStopTime_lap(k,:)= nansum(maxStopTime_lapZone);
        k= k+1;
    end

end