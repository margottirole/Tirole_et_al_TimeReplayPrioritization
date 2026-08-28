function sort_all_candidate_events(varargin)

% doesn't really matter, only used for events that have passed threshold
if ~isempty(varargin)
    switch varargin{1}
        case 'wcorr'
            load('significant_replay_events_wcorr.mat');
        case 'linear'
            load('significant_replay_events_linear.mat');
        case 'spearman'
            load('significant_replay_events_spearman.mat');
    end
else
    disp('loading wcorr by default')
    load('significant_replay_events_wcorr.mat');
end
            
load('time_range.mat');

% take all events with significant ripple power without track active cell
% spiking requirement
all_events_above_threshold= significant_replay_events.all_reactivations_times; 

bin_size= 60;
fields= {'ref_index','event_time','HIST'};
for this_field=1:length(fields)
    sorted_candidate_events.(fields{this_field}).sleepPRE=[];
    sorted_candidate_events.(fields{this_field}).awakePRE=[];
    sorted_candidate_events.(fields{this_field}).sleepPOST=[];
    sorted_candidate_events.(fields{this_field}).awakePOST=[];

    sorted_candidate_events.(fields{this_field}).awakeNotQuietRestPRE=[];
    sorted_candidate_events.(fields{this_field}).quietRestPRE=[];
    sorted_candidate_events.(fields{this_field}).NREM_PRE=[];
    sorted_candidate_events.(fields{this_field}).REM_PRE=[];
    sorted_candidate_events.(fields{this_field}).quietOnly_PRE=[];
    sorted_candidate_events.(fields{this_field}).awakeNotQuietRestPOST=[];
    sorted_candidate_events.(fields{this_field}).quietRestPOST=[];
    sorted_candidate_events.(fields{this_field}).NREM_POST=[];
    sorted_candidate_events.(fields{this_field}).REM_POST=[];
    sorted_candidate_events.(fields{this_field}).quietOnly_POST=[];

    sorted_candidate_events.(fields{this_field}).pre=[];
    sorted_candidate_events.(fields{this_field}).post=[];

    for this_track=1:size(time_range.track,1)
        sorted_candidate_events.(fields{this_field}).track(this_track).behaviour=[];
        sorted_candidate_events.(fields{this_field}).immobilityTRACK(this_track).behaviour=[];
        if strcmp(fields{this_field},'HIST')
            sorted_candidate_events.(fields{this_field}).track(this_track).count=[];
            sorted_candidate_events.(fields{this_field}).immobilityTRACK(this_track).count=[];
        end
    end
    for this_rest=1:size(time_range.rest,1)
        sorted_candidate_events.(fields{this_field}).rest(this_rest).rest= [];
        sorted_candidate_events.(fields{this_field}).immobilityREST(this_rest).rest=[]; 
        sorted_candidate_events.(fields{this_field}).awakeREST(this_rest).rest= [];
        sorted_candidate_events.(fields{this_field}).sleepREST(this_rest).rest=[];
        
       if strcmp(fields{this_field},'HIST')
            sorted_candidate_events.(fields{this_field}).rest(this_rest).count= [];
            sorted_candidate_events.(fields{this_field}).immobilityREST(this_rest).count=[];
       end
    end
end

for i=1:length(all_events_above_threshold)
    % TRACK 
        for this_track=1:size(time_range.track,1)
             % immobility
            for this_epoch=1:size(time_range.immobilityTRACK(this_track).track,1)
                if all_events_above_threshold(i)>= time_range.immobilityTRACK(this_track).track(this_epoch,1) && all_events_above_threshold(i) < time_range.immobilityTRACK(this_track).track(this_epoch,2)
                    sorted_candidate_events.event_time.immobilityTRACK(this_track).behaviour= [sorted_candidate_events.event_time.immobilityTRACK(this_track).behaviour all_events_above_threshold(i)];
                    sorted_candidate_events.ref_index.immobilityTRACK(this_track).behaviour= [sorted_candidate_events.ref_index.immobilityTRACK(this_track).behaviour i];
                end
            end
            % awake 
                if all_events_above_threshold(i)>= time_range.track(this_track,1) && all_events_above_threshold(i) < time_range.track(this_track,2)
                    sorted_candidate_events.event_time.track(this_track).behaviour= [sorted_candidate_events.event_time.track(this_track).behaviour all_events_above_threshold(i)];
                    sorted_candidate_events.ref_index.track(this_track).behaviour= [sorted_candidate_events.ref_index.track(this_track).behaviour i];
                end
        end
    
    % REST
         %  EITHER
         for this_rest=1:size(time_range.rest,1)  
            if all_events_above_threshold(i)>= time_range.rest(this_rest,1) && all_events_above_threshold(i) < time_range.rest(this_rest,2)
                sorted_candidate_events.event_time.rest(this_rest).rest= [sorted_candidate_events.event_time.rest(this_rest).rest all_events_above_threshold(i)];
                sorted_candidate_events.ref_index.rest(this_rest).rest= [sorted_candidate_events.ref_index.rest(this_rest).rest i];
            end
             %  immobility
             for this_epoch=1:size(time_range.immobilityREST(this_rest).rest,1)
                if all_events_above_threshold(i)>= time_range.immobilityREST(this_rest).rest(this_epoch,1) && all_events_above_threshold(i) < time_range.immobilityREST(this_rest).rest(this_epoch,2)
                    sorted_candidate_events.event_time.immobilityREST(this_rest).rest= [sorted_candidate_events.event_time.immobilityREST(this_rest).rest all_events_above_threshold(i)];
                    sorted_candidate_events.ref_index.immobilityREST(this_rest).rest= [sorted_candidate_events.ref_index.immobilityREST(this_rest).rest i];
                end
             end     
             % awake
              for this_epoch=1:size(time_range.awakeREST(this_rest).rest,1)  
                if all_events_above_threshold(i)>= time_range.awakeREST(this_rest).rest(this_epoch,1) && all_events_above_threshold(i) < time_range.awakeREST(this_rest).rest(this_epoch,2)
                    sorted_candidate_events.event_time.awakeREST(this_rest).rest= [sorted_candidate_events.event_time.rest(this_rest).rest all_events_above_threshold(i)];
                    sorted_candidate_events.ref_index.awakeREST(this_rest).rest= [sorted_candidate_events.ref_index.rest(this_rest).rest i];
                end
             end
             %sleep
              for this_epoch=1:size(time_range.sleepREST(this_rest).rest,1)  
                if all_events_above_threshold(i)>= time_range.sleepREST(this_rest).rest(this_epoch,1) && all_events_above_threshold(i) < time_range.sleepREST(this_rest).rest(this_epoch,2)
                    sorted_candidate_events.event_time.sleepREST(this_rest).rest= [sorted_candidate_events.event_time.sleepREST(this_rest).rest all_events_above_threshold(i)];
                    sorted_candidate_events.ref_index.sleepREST(this_rest).rest= [sorted_candidate_events.ref_index.sleepREST(this_rest).rest i];
                end
              end
         end
     
     
    % PRE
      var= {'awakeNotQuietRestPRE','quietRestPRE','NREM_PRE','REM_PRE','quietOnly_PRE'...
        'awakeNotQuietRestPOST','quietRestPOST','NREM_POST','REM_POST','pre','post','quietOnly_POST'};
      for thisc=1:length(var)
        for this_epoch=1:size(time_range.(var{thisc}),1)
            if all_events_above_threshold(i)>= time_range.(var{thisc})(this_epoch,1) && all_events_above_threshold(i) < time_range.(var{thisc})(this_epoch,2)
                sorted_candidate_events.event_time.(var{thisc})= [sorted_candidate_events.event_time.(var{thisc}) all_events_above_threshold(i)];
                sorted_candidate_events.ref_index.(var{thisc})= [sorted_candidate_events.ref_index.(var{thisc}) i];
            end
        end
      end

        % - SLEEP
        for this_epoch=1:size(time_range.sleepPRE,1)
            if all_events_above_threshold(i)>= time_range.sleepPRE(this_epoch,1) && all_events_above_threshold(i) < time_range.sleepPRE(this_epoch,2)
                sorted_candidate_events.event_time.sleepPRE= [sorted_candidate_events.event_time.sleepPRE all_events_above_threshold(i)];
                sorted_candidate_events.ref_index.sleepPRE= [sorted_candidate_events.ref_index.sleepPRE i];
            end
        end
        % - AWAKE
        for this_epoch=1:size(time_range.awakePRE,1)
            if all_events_above_threshold(i)>= time_range.awakePRE(this_epoch,1) && all_events_above_threshold(i) < time_range.awakePRE(this_epoch,2)
                sorted_candidate_events.event_time.awakePRE= [sorted_candidate_events.event_time.awakePRE all_events_above_threshold(i)];
                sorted_candidate_events.ref_index.awakePRE= [sorted_candidate_events.ref_index.awakePRE i];
            end
        end
    
        % POST - SLEEP
        for this_epoch=1:size(time_range.sleepPOST,1)
            if all_events_above_threshold(i)>= time_range.sleepPOST(this_epoch,1) && all_events_above_threshold(i) < time_range.sleepPOST(this_epoch,2)
                sorted_candidate_events.event_time.sleepPOST= [sorted_candidate_events.event_time.sleepPOST all_events_above_threshold(i)];
                sorted_candidate_events.ref_index.sleepPOST= [sorted_candidate_events.ref_index.sleepPOST i];
            end
        end

        % POST - AWAKE
        for this_epoch=1:size(time_range.awakePOST,1)
            if all_events_above_threshold(i)>= time_range.awakePOST(this_epoch,1) && all_events_above_threshold(i) < time_range.awakePOST(this_epoch,2)
                sorted_candidate_events.event_time.awakePOST= [sorted_candidate_events.event_time.awakePOST all_events_above_threshold(i)];
                 sorted_candidate_events.ref_index.awakePOST= [sorted_candidate_events.ref_index.awakePOST i];
            end
        end
end

%% get histograms
bin_width=60;
for this_track=1:size(time_range.track,1)
    % immobility
    time_bin_edges= [0:bin_width:bin_width*ceil(max(time_range.immobilityTRACK_CUMULATIVE(this_track).behaviour(:,2))/bin_width)];
    
    sorted_candidate_events.cumulative_event_time.immobilityTRACK(this_track).behaviour= interpolate_cumulative_time(time_range.immobilityTRACK_CUMULATIVE(this_track).behaviour,...
            time_range.immobilityTRACK(this_track).track,sorted_candidate_events.event_time.immobilityTRACK(this_track).behaviour);  
        
    sorted_candidate_events.HIST.immobilityTRACK(this_track).count= histcounts(sorted_candidate_events.cumulative_event_time.immobilityTRACK(this_track).behaviour,time_bin_edges);
    sorted_candidate_events.HIST.immobilityTRACK(this_track).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;        
    sorted_candidate_events.CUMULATIVE.immobilityTRACK(this_track).count=  cumsum(sorted_candidate_events.HIST.immobilityTRACK(this_track).count);
    sorted_candidate_events.CUMULATIVE.immobilityTRACK(this_track).time_bins_centres= time_bin_edges(1:end-1)+bin_width/2;
    % awake
    time_bin_edges= [0:bin_width:bin_width*ceil(max(time_range.track_CUMULATIVE(this_track).behaviour(:,2))/bin_width)];
    
    sorted_candidate_events.cumulative_event_time.track(this_track).behaviour= interpolate_cumulative_time(time_range.track_CUMULATIVE(this_track).behaviour,...
            time_range.track(this_track,:),sorted_candidate_events.event_time.track(this_track).behaviour);  
        
    sorted_candidate_events.HIST.track(this_track).count= histcounts(sorted_candidate_events.cumulative_event_time.track(this_track).behaviour,time_bin_edges);
    sorted_candidate_events.HIST.track(this_track).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;        
    sorted_candidate_events.CUMULATIVE.track(this_track).count=  cumsum(sorted_candidate_events.HIST.track(this_track).count);
    sorted_candidate_events.CUMULATIVE.track(this_track).time_bins_centres= time_bin_edges(1:end-1)+bin_width/2;
end

for this_rest=1:size(time_range.rest,1)
    % rest - either
    time_bin_edges= time_range.rest(this_rest,1):bin_size:time_range.rest(this_rest,2);
    sorted_candidate_events.HIST.rest(this_rest).count= histcounts(sorted_candidate_events.event_time.rest(this_rest).rest,time_bin_edges);
    sorted_candidate_events.HIST.rest(this_rest).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;
    
    % immobility
    time_bin_edges= [0:bin_width:bin_width*ceil(max(time_range.immobilityREST_CUMULATIVE(this_rest).rest(:,2))/bin_width)]; 
    sorted_candidate_events.cumulative_event_time.immobilityREST(this_rest).rest= interpolate_cumulative_time(time_range.immobilityREST_CUMULATIVE(this_rest).rest,...
            time_range.immobilityREST(this_rest).rest,sorted_candidate_events.event_time.immobilityREST(this_rest).rest);      
    sorted_candidate_events.HIST.immobilityREST(this_rest).count= histcounts(sorted_candidate_events.cumulative_event_time.immobilityREST(this_rest).rest,time_bin_edges);
    sorted_candidate_events.HIST.immobilityREST(this_rest).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;  
    sorted_candidate_events.CUMULATIVE.immobilityREST(this_rest).count=  cumsum(sorted_candidate_events.HIST.immobilityREST(this_rest).count);
    sorted_candidate_events.CUMULATIVE.immobilityREST(this_rest).time_bins_centres= time_bin_edges(1:end-1)+bin_width/2;   
    % awake
    time_bin_edges= [0:bin_width:bin_width*ceil(max(time_range.awakeREST_CUMULATIVE(this_rest).rest(:,2))/bin_width)]; 
    sorted_candidate_events.cumulative_event_time.awakeREST(this_rest).rest= interpolate_cumulative_time(time_range.awakeREST_CUMULATIVE(this_rest).rest,...
            time_range.awakeREST(this_rest).rest,sorted_candidate_events.event_time.awakeREST(this_rest).rest);      
    sorted_candidate_events.HIST.awakeREST(this_rest).count= histcounts(sorted_candidate_events.cumulative_event_time.awakeREST(this_rest).rest,time_bin_edges);
    sorted_candidate_events.HIST.awakeREST(this_rest).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;  
    sorted_candidate_events.CUMULATIVE.awakeREST(this_rest).count=  cumsum(sorted_candidate_events.HIST.awakeREST(this_rest).count);
    sorted_candidate_events.CUMULATIVE.awakeREST(this_rest).time_bins_centres= time_bin_edges(1:end-1)+bin_width/2;
    % sleep
    time_bin_edges= [0:bin_width:bin_width*ceil(max(time_range.sleepREST_CUMULATIVE(this_rest).rest(:,2))/bin_width)]; 
    if ~isempty(time_bin_edges)
        sorted_candidate_events.cumulative_event_time.sleepREST(this_rest).rest= interpolate_cumulative_time(time_range.sleepREST_CUMULATIVE(this_rest).rest,...
                time_range.sleepREST(this_rest).rest,sorted_candidate_events.event_time.sleepREST(this_rest).rest);      
        sorted_candidate_events.HIST.sleepREST(this_rest).count= histcounts(sorted_candidate_events.cumulative_event_time.sleepREST(this_rest).rest,time_bin_edges);
        sorted_candidate_events.HIST.sleepREST(this_rest).time_bin_centres= time_bin_edges(1:end-1)+ bin_size/2;  
        sorted_candidate_events.CUMULATIVE.sleepREST(this_rest).count=  cumsum(sorted_candidate_events.HIST.sleepREST(this_rest).count);
        sorted_candidate_events.CUMULATIVE.sleepREST(this_rest).time_bins_centres= time_bin_edges(1:end-1)+bin_width/2;
    else
         sorted_candidate_events.cumulative_event_time.sleepREST(this_rest).rest= [];      
        sorted_candidate_events.HIST.sleepREST(this_rest).count= [];
        sorted_candidate_events.HIST.sleepREST(this_rest).time_bin_centres= [];  
        sorted_candidate_events.CUMULATIVE.sleepREST(this_rest).count=  [];
        sorted_candidate_events.CUMULATIVE.sleepREST(this_rest).time_bins_centres= [];
    end
end


save('sorted_candidate_events.mat','sorted_candidate_events');

end


function cumulative_event_times=interpolate_cumulative_time(cumulative_time,time, event_times)
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