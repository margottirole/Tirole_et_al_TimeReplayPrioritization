function plotReplayTimeline(TRACKS,SLEEP,REST,CANDIDATE,varargin)

p=inputParser;
addParameter(p,'plotTypeTracks','min'); % options are lap, min, quality
addParameter(p,'plotVar','tracks'); % options are tracks, tracks_only, reward, selective_reward
addParameter(p,'plotCand',1); 
parse(p,varargin{:});

plotTypeTracks= p.Results.plotTypeTracks;
plotVar= p.Results.plotVar;
plotCand= p.Results.plotCand;

if plotTypeTracks == "min"
    loc_var= 'local_rate_min_immobile';
    rem_n1_var= 'remote_n1_rate_min_immobile';
    rem_n2_var= 'remote_n2_rate_min_immobile';
    fut_n1_var= 'future_n1_rate_min_immobile';
    fut_n2_var= 'future_n1_rate_min_immobile';
    t_bins_track= 't_bins_min_immobile';
    laps_T= TRACKS.(t_bins_track){1}'/60;
elseif plotTypeTracks == "lap"
    loc_var= 'local_Lap_rate';
    rem_n1_var= 'remote_n1_Lap_rate';
    rem_n2_var= 'remote_n2_Lap_rate';
    fut_n1_var= 'future_n1_Lap_rate';
    fut_n2_var= 'future_n2_Lap_rate';
    laps_T= 1:length(TRACKS.local_Lap_rate{1});
elseif plotTypeTracks == "quality"
    loc_var= 'local_Lap_quality';
    rem_n1_var= 'remote_n1_quality';
    rem_n2_var= 'remote_n2_quality';
    fut_n1_var= 'future_n1_Lap_quality';
    fut_n2_var= 'future_n2_Lap_quality';
    laps_T= 1:length(TRACKS.local_Lap_rate{1});
end

% reward colours
load('colour palettes\ScientificColourMaps6\berlin\DiscretePalettes\berlin10.mat');
cdata_rew= [{berlin10(1,:)},...
       {berlin10(8,:)}];
REW= ["LOW","HIGH"];

% recency colours
load('colour palettes\ScientificColourMaps6\bamako\DiscretePalettes\bamako10.mat');
cdata_rec= [{bamako10(1,:)},...
       {bamako10(6,:)},...
       {bamako10(8,:)}];

%% now plot
hold on;
switch plotVar
    case 'offline_only'
        t_bins_pre= SLEEP.NREM_REM_PREbinCtrs{1}'/60;
        t_bins_Rest1= REST.RESTbinCtrsBinned{1}'/60;
        t_bins_Rest2= REST.RESTbinCtrsBinned{2}'/60;
        t_bins_Rest3= REST.RESTbinCtrsBinned{3}'/60;
        t_bins_post= SLEEP.NremRemPOSTbinCtrs{1}'/60;
        p=[];
        for thisReplayedTrack=1:3
            % during pre
            if plotTypeTracks ~= "quality"
                % dataPRE= cell2mat(SLEEP.awakeQuietPREreplayRate(SLEEP.track==thisReplayedTrack));
                dataPRE= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.track==thisReplayedTrack));
            else
                dataPRE= cell2mat(SLEEP.NREM_REM_PREreplayQuality(SLEEP.track==thisReplayedTrack));
            end

            % during rest 1-3
            if plotTypeTracks ~= "quality"
                dataRest1= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == thisReplayedTrack));
                dataRest2= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == thisReplayedTrack));        
                dataRest3= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == thisReplayedTrack));
            else
                dataRest1= cell2mat(REST.RESTreplayQualityBinned(REST.rest==1 & REST.track == thisReplayedTrack));
                dataRest2= cell2mat(REST.RESTreplayQualityBinned(REST.rest==2 & REST.track == thisReplayedTrack));        
                dataRest3= cell2mat(REST.RESTreplayQualityBinned(REST.rest==3 & REST.track == thisReplayedTrack));
            end
            % post - here sleep only
            if plotTypeTracks ~= "quality"
                dataPOST= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==thisReplayedTrack));
            else 
                dataPOST= cell2mat(SLEEP.NremRemPOSTreplayQuality(SLEEP.track==thisReplayedTrack));
            end
        
            sessMean= [mean(dataPRE,1,'omitmissing') inf mean(dataRest1,1,'omitmissing') inf...
                mean(dataRest2,1,'omitmissing') inf...
                mean(dataRest3,1,'omitmissing') inf mean(dataPOST,1,'omitmissing')];
    
            sessSem= [nansem(dataPRE) inf nansem(dataRest1) inf ...
                nansem(dataRest2) inf nansem(dataRest3) inf nansem(dataPOST)];
    
            valid= ~isinf(sessMean) ;
            idx= find(valid);
            breaks = [0, find(diff(idx) > 1), numel(idx)];
            for b = 1:numel(breaks)-1
                epochIdx = idx(breaks(b)+1 : breaks(b+1));
                mv = sessMean(epochIdx);
                sv = sessSem(epochIdx);
                x_fill = [epochIdx fliplr(epochIdx)];
                y_fill = [mv + sv fliplr(mv - sv)];
                patch(x_fill, y_fill, cdata_rec{thisReplayedTrack}, ...
                      'FaceAlpha', 0.2, ...   
                      'EdgeColor', 'none');
            end
    
            p(thisReplayedTrack)= plot(sessMean,'Color',cdata_rec{thisReplayedTrack},'LineWidth',2);
        end
        xline(find(isinf(sessMean)),'k:','LineWidth',1);
        xt= 1:length(sessMean);
        xt(isinf(sessMean))=[];
        xticks(xt); xticklabels([t_bins_pre t_bins_Rest1 t_bins_Rest2 t_bins_Rest3 t_bins_post]);
     
        if plotTypeTracks == "min"
            xlabel('time (minutes)');
        elseif plotTypeTracks == "lap"
             xlabel('lap number');
        end
        if plotTypeTracks ~= "quality"
            ylabel('replay rate');
        else
            ylabel('replay score');
        end
        yl= ylim;
        text(length(t_bins_pre)/2,yl(2),'sleep PRE');
        st= length(t_bins_pre);
        text(st + length(t_bins_Rest1)/2,yl(2),'Rest1');
        st= st + length(t_bins_Rest1)+1;
        text(st + length(t_bins_Rest2)/2,yl(2),'Rest2');
        st= st + length(t_bins_Rest2)+1;
        text(st + length(t_bins_Rest3)/2,yl(2),'Rest3');
        st= st + length(t_bins_Rest3);
        text(st + length(t_bins_post)/2,yl(2),'sleep POST');
        legend(p,{'replay T1','replay T2','replay T3'},'Box','off');


    case 'tracks'
    t_bins_pre= SLEEP.NREM_REM_PREbinCtrs{1}'/60;
    t_bins_Rest1= REST.RESTbinCtrsBinned{1}'/60;
    t_bins_Rest2= REST.RESTbinCtrsBinned{2}'/60;
    t_bins_Rest3= REST.RESTbinCtrsBinned{3}'/60;
    t_bins_post= SLEEP.NremRemPOSTbinCtrs{1}'/60;
    p=[];
    for thisReplayedTrack=1:3
        % during pre
        if plotTypeTracks ~= "quality"
            % dataPRE= cell2mat(SLEEP.awakeQuietPREreplayRate(SLEEP.track==thisReplayedTrack));
            dataPRE= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.track==thisReplayedTrack));
        else
            dataPRE= cell2mat(SLEEP.NREM_REM_PREreplayQuality(SLEEP.track==thisReplayedTrack));
        end
        
        % on tracks
        if thisReplayedTrack==1
            dataT1= cell2mat(TRACKS.(loc_var)(TRACKS.track==1)); % local_Lap_rate
            dataT2= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==2)); % remote_n1_Lap_rate
            dataT3= cell2mat(TRACKS.(rem_n2_var)(TRACKS.track==3)); % remote_n2_Lap_rate
        elseif thisReplayedTrack==2
            dataT1= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==1));
            dataT2= cell2mat(TRACKS.(loc_var)(TRACKS.track==2));
            dataT3= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==3));
        elseif thisReplayedTrack==3
            dataT1= cell2mat(TRACKS.(fut_n2_var)(TRACKS.track==1));
            dataT2= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==2));
            dataT3= cell2mat(TRACKS.(loc_var)(TRACKS.track==3));
        end
        
        % during rest 1-3
        if plotTypeTracks ~= "quality"
            dataRest1= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == thisReplayedTrack));
            dataRest2= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == thisReplayedTrack));        
            dataRest3= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == thisReplayedTrack));
        else
            dataRest1= cell2mat(REST.RESTreplayQualityBinned(REST.rest==1 & REST.track == thisReplayedTrack));
            dataRest2= cell2mat(REST.RESTreplayQualityBinned(REST.rest==2 & REST.track == thisReplayedTrack));        
            dataRest3= cell2mat(REST.RESTreplayQualityBinned(REST.rest==3 & REST.track == thisReplayedTrack));
        end

        % post - here sleep only
        if plotTypeTracks ~= "quality"
            dataPOST= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==thisReplayedTrack));
        else 
            dataPOST= cell2mat(SLEEP.NremRemPOSTreplayQuality(SLEEP.track==thisReplayedTrack));
        end
    
        sessMean= [mean(dataPRE,1,'omitmissing') inf mean(dataT1,1,'omitmissing') inf mean(dataRest1,1,'omitmissing') inf...
            mean(dataT2,1,'omitmissing') inf mean(dataRest2,1,'omitmissing') inf mean(dataT3,1,'omitmissing') inf...
            mean(dataRest3,1,'omitmissing') inf mean(dataPOST,1,'omitmissing')];

        sessSem= [nansem(dataPRE) inf nansem(dataT1) inf nansem(dataRest1) inf ...
            nansem(dataT2) inf nansem(dataRest2) inf nansem(dataT3) ...
            inf nansem(dataRest3) inf nansem(dataPOST)];

        valid= ~isinf(sessMean) ;
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, cdata_rec{thisReplayedTrack}, ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(thisReplayedTrack)= plot(sessMean,'Color',cdata_rec{thisReplayedTrack},'LineWidth',2);
        % errorbar(sessMean,[nansem(dataPRE) NaN nansem(dataT1) NaN nansem(dataRest1) NaN ...
        %     nansem(dataT2) NaN nansem(dataRest2) NaN nansem(dataT3) ...
        %     NaN nansem(dataRest3) NaN nansem(dataPOST)],'Color',cdata_rec{thisReplayedTrack},'LineStyle','none')
    end
    xline(find(isinf(sessMean)),'k:','LineWidth',1);
    xt= 1:length(sessMean);
    xt(isinf(sessMean))=[];
    xticks(xt); xticklabels([t_bins_pre laps_T t_bins_Rest1 laps_T t_bins_Rest2 laps_T t_bins_Rest3 t_bins_post]);
 
    if plotTypeTracks == "min"
        xlabel('time (minutes)');
    elseif plotTypeTracks == "lap"
         xlabel('lap number');
    end
    if plotTypeTracks ~= "quality"
        ylabel('replay rate');
    else
        ylabel('replay score');
    end
    yl= ylim;
    text(length(t_bins_pre)/2,yl(2),'sleep PRE');
    st= length(t_bins_pre);
    text(st + length(laps_T)/2,yl(2),'Track1');
    st= st +length(laps_T)+1;
    text(st + length(t_bins_Rest1)/2,yl(2),'Rest1');
    st= st + length(t_bins_Rest1)+1;
    text(st + length(laps_T)/2,yl(2),'Track2');
    st= st + length(laps_T)+1;
    text(st + length(t_bins_Rest2)/2,yl(2),'Rest2');
    st= st + length(t_bins_Rest2)+1;
    text(st + length(laps_T)/2,yl(2),'Track3');
    st= st + length(laps_T);
    text(st + length(t_bins_Rest3)/2,yl(2),'Rest3');
    st= st + length(t_bins_Rest3);
    text(st + length(t_bins_post)/2,yl(2),'sleep POST');
    
    if plotCand
        % add Cand events
        SWR_PRE= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "sleepPRE"});
        SWR_rest1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest1"});
        SWR_rest2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest2"});
        SWR_rest3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest3"});
        SWR_sleepPOST= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "sleepPOST"});
        if plotTypeTracks == "min"
            SWR_rate_T1= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==1));
            SWR_rate_T2= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==2));
            SWR_rate_T3= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==3));
        elseif plotTypeTracks == "lap"
            SWR_rate_T1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T1"});
            SWR_rate_T2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T2"});
            SWR_rate_T3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T3"});
        end
        yyaxis right
        sessMean= [mean(SWR_PRE,1,'omitmissing') inf mean(SWR_rate_T1,1,'omitmissing') inf mean(SWR_rest1,1,'omitmissing') inf...
                mean(SWR_rate_T2,1,'omitmissing') inf mean(SWR_rest2,1,'omitmissing') inf mean(SWR_rate_T3,1,'omitmissing') inf...
                mean(SWR_rest3,1,'omitmissing') inf mean(SWR_sleepPOST,1,'omitmissing')];

        sessSem= [nansem(SWR_PRE) inf nansem(SWR_rate_T1) inf nansem(SWR_rest1) inf ...
                nansem(SWR_rate_T2) inf nansem(SWR_rest2) inf nansem(SWR_rate_T3) ...
                inf nansem(SWR_rest3) inf nansem(SWR_sleepPOST)];

        valid= ~isinf(sessMean) ;
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, [0.7 0.7 0.7], ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(4)= plot(sessMean,'Color',[0.7 0.7 0.7],'LineWidth',2);
            % errorbar(sessMean,[nansem(SWR_PRE) NaN nansem(SWR_rate_T1) NaN nansem(SWR_rest1) NaN ...
            %     nansem(SWR_rate_T2) NaN nansem(SWR_rest2) NaN nansem(SWR_rate_T3) ...
            %     NaN nansem(SWR_rest3) NaN nansem(SWR_sleepPOST)],'Color',[0.7 0.7 0.7],'LineStyle','none')
        ylabel('Candidate event rate'); ylim([-0.2 0.99]); yticks([0:0.1:0.8])
        legend(p,{'replay T1','replay T2','replay T3','cand events'},'Box','off');
    else
        legend(p,{'replay T1','replay T2','replay T3'},'Box','off');
    end

    case 'tracks_only'
    p=[];
    for thisReplayedTrack=1:3
        
        % on tracks
        if thisReplayedTrack==1
            dataT1= cell2mat(TRACKS.(loc_var)(TRACKS.track==1)); % local_Lap_rate
            dataT2= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==2)); % remote_n1_Lap_rate
            dataT3= cell2mat(TRACKS.(rem_n2_var)(TRACKS.track==3)); % remote_n2_Lap_rate
        elseif thisReplayedTrack==2
            dataT1= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==1));
            dataT2= cell2mat(TRACKS.(loc_var)(TRACKS.track==2));
            dataT3= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==3));
        elseif thisReplayedTrack==3
            dataT1= cell2mat(TRACKS.(fut_n2_var)(TRACKS.track==1));
            dataT2= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==2));
            dataT3= cell2mat(TRACKS.(loc_var)(TRACKS.track==3));
        end
        
       
        sessMean= [mean(dataT1,1,'omitmissing') inf mean(dataT2,1,'omitmissing') inf mean(dataT3,1,'omitmissing')];

        sessSem= [nansem(dataT1) inf nansem(dataT2) inf nansem(dataT3)];

        valid= ~isinf(sessMean) ;
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, cdata_rec{thisReplayedTrack}, ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(thisReplayedTrack)= plot(sessMean,'Color',cdata_rec{thisReplayedTrack},'LineWidth',2);
    end
    xline(find(isinf(sessMean)),'k:','LineWidth',1);
    xt= 1:length(sessMean);
    xt(isinf(sessMean))=[];
    xticks(xt); xticklabels([laps_T laps_T laps_T ]);
 
    if plotTypeTracks == "min"
        xlabel('time (minutes)');
    elseif plotTypeTracks == "lap"
         xlabel('lap number');
    end
    if plotTypeTracks ~= "quality"
        ylabel('replay rate');
    else
        ylabel('replay score');
    end
    yl= ylim;
    st= 0;
    text(st + length(laps_T)/2,yl(2),'Track1');
    st= st +length(laps_T)+1;
    text(st + length(laps_T)/2,yl(2),'Track2');
    st= st + length(laps_T)+1;
    text(st + length(laps_T)/2,yl(2),'Track3');
    
    if plotCand
        if plotTypeTracks == "min"
            SWR_rate_T1= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==1));
            SWR_rate_T2= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==2));
            SWR_rate_T3= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==3));
        elseif plotTypeTracks == "lap"
            SWR_rate_T1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T1"});
            SWR_rate_T2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T2"});
            SWR_rate_T3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T3"});
        end
        yyaxis right
        sessMean= [mean(SWR_rate_T1,1,'omitmissing') inf mean(SWR_rate_T2,1,'omitmissing') inf mean(SWR_rate_T3,1,'omitmissing')];
        sessSem= [nansem(SWR_rate_T1) inf nansem(SWR_rate_T2) inf nansem(SWR_rate_T3)];

        valid= ~isinf(sessMean) ;
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, [0.7 0.7 0.7], ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(4)= plot(sessMean,'Color',[0.7 0.7 0.7],'LineWidth',2);
        ylabel('Candidate event rate'); ylim([-0.2 0.99]); yticks([0:0.1:0.8])
        legend(p,{'replay T1','replay T2','replay T3','cand events'},'Box','off');
    else
        legend(p,{'replay T1','replay T2','replay T3'},'Box','off');
    end

    case 'reward'
    % there is a much more efficient way to plot this
    t_bins_pre= SLEEP.NREM_REM_PREbinCtrs{1}'/60;
    t_bins_Rest1= REST.RESTbinCtrsBinned{1}'/60;
    t_bins_Rest2= REST.RESTbinCtrsBinned{2}'/60;
    t_bins_Rest3= REST.RESTbinCtrsBinned{3}'/60;
    t_bins_post= SLEEP.NremRemPOSTbinCtrs{1}'/60;
    p=[]; pl=[];
    for thisReplayedTrack=1:3
        % during pre
        dataPRE_LOW= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.track==thisReplayedTrack  & SLEEP.reward == "LOW"));
        dataPRE_HIGH= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.track==thisReplayedTrack  & SLEEP.reward == "HIGH"));
        % on tracks
        if thisReplayedTrack==1
            dataT1_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "LOW")); 
            dataT1_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "HIGH"));
            dataT2_LOW= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==2 & TRACKS.reward == "LOW")); 
            dataT2_HIGH= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==2 & TRACKS.reward == "HIGH")); 
            dataT3_LOW= cell2mat(TRACKS.(rem_n2_var)(TRACKS.track==3 & TRACKS.reward == "LOW")); 
            dataT3_HIGH= cell2mat(TRACKS.(rem_n2_var)(TRACKS.track==3 & TRACKS.reward == "HIGH")); 
        elseif thisReplayedTrack==2
            dataT1_LOW= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==1 & TRACKS.reward == "LOW"));
            dataT1_HIGH= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==1 & TRACKS.reward == "HIGH"));
            dataT2_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "LOW"));
            dataT2_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "HIGH"));
            dataT3_LOW= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==3 & TRACKS.reward == "LOW"));
            dataT3_HIGH= cell2mat(TRACKS.(rem_n1_var)(TRACKS.track==3 & TRACKS.reward == "HIGH"));
        elseif thisReplayedTrack==3
            dataT1_LOW= cell2mat(TRACKS.(fut_n2_var)(TRACKS.track==1 & TRACKS.reward == "LOW"));
            dataT1_HIGH= cell2mat(TRACKS.(fut_n2_var)(TRACKS.track==1 & TRACKS.reward == "HIGH"));
            dataT2_LOW= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==2 & TRACKS.reward == "LOW"));
            dataT2_HIGH= cell2mat(TRACKS.(fut_n1_var)(TRACKS.track==2 & TRACKS.reward == "HIGH"));
            dataT3_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "LOW"));
            dataT3_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "HIGH"));
        end
        
        % during rest 1-3
        dataRest1_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == thisReplayedTrack & REST.reward == "LOW"));
        dataRest1_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == thisReplayedTrack & REST.reward == "HIGH"));
        dataRest2_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == thisReplayedTrack & REST.reward == "LOW"));
        dataRest2_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == thisReplayedTrack & REST.reward == "HIGH"));
        dataRest3_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == thisReplayedTrack & REST.reward == "LOW"));
        dataRest3_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == thisReplayedTrack & REST.reward == "HIGH"));

        % post - here sleep only
        dataPOST_LOW= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==thisReplayedTrack & SLEEP.reward == "LOW"));
        dataPOST_HIGH= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==thisReplayedTrack & SLEEP.reward == "HIGH"));
            
        sessMeanT1LOW= [mean(dataPRE_LOW,1,'omitmissing') inf mean(dataT1_LOW,1,'omitmissing') inf mean(dataRest1_LOW,1,'omitmissing') inf...
            mean(dataT2_LOW,1,'omitmissing') inf mean(dataRest2_LOW,1,'omitmissing') inf mean(dataT3_LOW,1,'omitmissing') inf...
            mean(dataRest3_LOW,1,'omitmissing') inf mean(dataPOST_LOW,1,'omitmissing')];

        sessMeanT1HIGH= [mean(dataPRE_HIGH,1,'omitmissing') inf mean(dataT1_HIGH,1,'omitmissing') inf mean(dataRest1_HIGH,1,'omitmissing') inf...
            mean(dataT2_HIGH,1,'omitmissing') inf mean(dataRest2_HIGH,1,'omitmissing') inf mean(dataT3_HIGH,1,'omitmissing') inf...
            mean(dataRest3_HIGH,1,'omitmissing') inf mean(dataPOST_HIGH,1,'omitmissing')];

        sessMeanT2LOW= [mean(dataPRE_LOW,1,'omitmissing') inf mean(dataT2_LOW,1,'omitmissing') inf mean(dataRest1_LOW,1,'omitmissing') inf...
            mean(dataT2_LOW,1,'omitmissing') inf mean(dataRest2_LOW,1,'omitmissing') inf mean(dataT3_LOW,1,'omitmissing') inf...
            mean(dataRest3_LOW,1,'omitmissing') inf mean(dataPOST_LOW,1,'omitmissing')];

        sessMeanT2HIGH= [mean(dataPRE_HIGH,1,'omitmissing') inf mean(dataT2_HIGH,1,'omitmissing') inf mean(dataRest1_HIGH,1,'omitmissing') inf...
            mean(dataT2_HIGH,1,'omitmissing') inf mean(dataRest2_HIGH,1,'omitmissing') inf mean(dataT3_HIGH,1,'omitmissing') inf...
            mean(dataRest3_HIGH,1,'omitmissing') inf mean(dataPOST_HIGH,1,'omitmissing')];

        sessMeanT3LOW= [mean(dataPRE_LOW,1,'omitmissing') inf mean(dataT3_LOW,1,'omitmissing') inf mean(dataRest1_LOW,1,'omitmissing') inf...
            mean(dataT2_LOW,1,'omitmissing') inf mean(dataRest2_LOW,1,'omitmissing') inf mean(dataT3_LOW,1,'omitmissing') inf...
            mean(dataRest3_LOW,1,'omitmissing') inf mean(dataPOST_LOW,1,'omitmissing')];

        sessMeanT3HIGH= [mean(dataPRE_HIGH,1,'omitmissing') inf mean(dataT3_HIGH,1,'omitmissing') inf mean(dataRest1_HIGH,1,'omitmissing') inf...
            mean(dataT2_HIGH,1,'omitmissing') inf mean(dataRest2_HIGH,1,'omitmissing') inf mean(dataT3_HIGH,1,'omitmissing') inf...
            mean(dataRest3_HIGH,1,'omitmissing') inf mean(dataPOST_HIGH,1,'omitmissing')];
        
        
        semLOW= [nansem(dataPRE_LOW) inf nansem(dataT1_LOW) inf nansem(dataRest1_LOW) inf ...
            nansem(dataT2_LOW) inf nansem(dataRest2_LOW) inf nansem(dataT3_LOW) ...
            inf nansem(dataRest3_LOW) inf nansem(dataPOST_LOW)];
        semHIGH= [nansem(dataPRE_HIGH) inf nansem(dataT1_HIGH) inf nansem(dataRest1_HIGH) inf ...
            nansem(dataT2_HIGH) inf nansem(dataRest2_HIGH) inf nansem(dataT3_HIGH) ...
            inf nansem(dataRest3_HIGH) inf nansem(dataPOST_HIGH)];

        % valid= ~isinf(sessMeanLOW);
        % idx= find(valid);
        % breaks = [0, find(diff(idx) > 1), numel(idx)];
        % for b = 1:numel(breaks)-1
        %     epochIdx = idx(breaks(b)+1 : breaks(b+1));
        %     mvLOW = sessMeanLOW(epochIdx);
        %     svLOW = semLOW(epochIdx);
        %     mvHIGH = sessMeanHIGH(epochIdx);
        %     svHIGH = semHIGH(epochIdx);
        %     x_fill = [epochIdx; flipud(epochIdx)];
        %     y_fill = [mvLOW + svLOW  fliplr(mvLOW - svLOW)];
        %     patch(x_fill, y_fill, cdata_rew{1}, ...
        %           'FaceAlpha', 0.2, ...   
        %           'EdgeColor', 'none');
        %     y_fill = [mvHIGH + svHIGH  fliplr(mvHIGH - svHIGH)];
        %     patch(x_fill, y_fill, cdata_rew{2}, ...
        %           'FaceAlpha', 0.2, ...   
        %           'EdgeColor', 'none');
        % end

        if thisReplayedTrack ==1
            pl1= plot(sessMeanT1LOW,'Color',cdata_rew{1},'LineWidth',2);
            pl2= plot(sessMeanT1HIGH,'Color',cdata_rew{2},'LineWidth',2);
        elseif thisReplayedTrack ==2
            pl1= plot(sessMeanT1LOW,'Color',cdata_rew{1},'LineWidth',2,'LineStyle','--');
            pl2= plot(sessMeanT1HIGH,'Color',cdata_rew{2},'LineWidth',2,'LineStyle','--');
        elseif thisReplayedTrack ==3
            pl1= plot(sessMeanT1LOW,'Color',cdata_rew{1},'LineWidth',2,'LineStyle','-.');
            pl2= plot(sessMeanT1HIGH,'Color',cdata_rew{2},'LineWidth',2,'LineStyle','-.');
        end

        pl= [pl pl1 pl2];

        % xline(find(~valid),'k:','LineWidth',1);
        % errorbar(sessMeanLOW,semLOW,'Color',cdata_rew{1},'LineStyle','none')
        % errorbar(sessMeanHIGH,semHIGH,'Color',cdata_rew{2},'LineStyle','none')
    end

    legend(pl,{'T1-LOW','T1-HIGH','T2-LOW','T2-HIGH','T3-LOW','T3-HIGH'})
    
    xt= 1:length(sessMeanT1LOW);
    xt(isinf(sessMeanT1LOW))=[];
    xticks(xt); xticklabels([t_bins_pre laps_T t_bins_Rest1 laps_T t_bins_Rest2 laps_T t_bins_Rest3 t_bins_post]);
 
    if plotTypeTracks == "min"
        xlabel('time (minutes)');
    elseif plotTypeTracks == "lap"
         xlabel('lap number');
    end
    ylabel('replay rate');
    yl= ylim;
    text(length(t_bins_pre)/2,yl(2),'sleepPRE');
    st= length(t_bins_pre);
    text(st + length(laps_T)/2,yl(2),'Track1');
    st= st +length(laps_T)+1;
    text(st + length(t_bins_Rest1)/2,yl(2),'Rest1');
    st= st + length(t_bins_Rest1)+1;
    text(st + length(laps_T)/2,yl(2),'Track2');
    st= st + length(laps_T)+1;
    text(st + length(t_bins_Rest2)/2,yl(2),'Rest2');
    st= st + length(t_bins_Rest2)+1;
    text(st + length(laps_T)/2,yl(2),'Track3');
    st= st + length(laps_T);
    text(st + length(t_bins_Rest3)/2,yl(2),'Rest3');
    st= st + length(t_bins_Rest3);
    text(st + length(t_bins_post)/2,yl(2),'sleep POST');
    
    if plotCand
        % add Cand events
        SWR_PRE= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "PRE"});
        SWR_rest1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest1"});
        SWR_rest2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest2"});
        SWR_rest3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest3"});
        SWR_sleepPOST= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "sleepPOST"});
        if plotTypeTracks == "min"
            SWR_rate_T1= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==1));
            SWR_rate_T2= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==2));
            SWR_rate_T3= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==3));
        elseif plotTypeTracks == "lap"
            SWR_rate_T1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T1"});
            SWR_rate_T2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T2"});
            SWR_rate_T3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T3"});
        end
        yyaxis right
        sessMean= [mean(SWR_PRE,1,'omitmissing') inf mean(SWR_rate_T1,1,'omitmissing') inf mean(SWR_rest1,1,'omitmissing') inf...
                mean(SWR_rate_T2,1,'omitmissing') inf mean(SWR_rest2,1,'omitmissing') inf mean(SWR_rate_T3,1,'omitmissing') inf...
                mean(SWR_rest3,1,'omitmissing') inf mean(SWR_sleepPOST,1,'omitmissing')];

        sessSem= [nansem(SWR_PRE) inf nansem(SWR_rate_T1) inf nansem(SWR_rest1) inf ...
                nansem(SWR_rate_T2) inf nansem(SWR_rest2) inf nansem(SWR_rate_T3) ...
                inf nansem(SWR_rest3) inf nansem(SWR_sleepPOST)];

        valid= ~isinf(sessMean);
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, [0.7 0.7 0.7], ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(4)= plot(sessMean,'Color',[0.7 0.7 0.7],'LineWidth',2);
            % errorbar(sessMean,[nansem(SWR_PRE) NaN nansem(SWR_rate_T1) NaN nansem(SWR_rest1) NaN ...
            %     nansem(SWR_rate_T2) NaN nansem(SWR_rest2) NaN nansem(SWR_rate_T3) ...
            %     NaN nansem(SWR_rest3) NaN nansem(SWR_sleepPOST)],'Color',[0.7 0.7 0.7],'LineStyle','none')
        ylabel('Candidate event rate'); ylim([-0.2 0.99]); yticks([0:0.1:0.8])
        % legend(p,{'replay T1','replay T2','replay T3','cand events'},'Box','off');
    else
        % legend(p,{'replay T1','replay T2','replay T3'},'Box','off');
    end

    case 'selective_reward'
        % only plots some of the tracks (e.g. no remote) to declutter
        t_bins_pre= SLEEP.NREM_REM_PREbinCtrs{1}'/60;
        t_bins_Rest1= REST.RESTbinCtrsBinned{1}'/60;
        t_bins_Rest2= REST.RESTbinCtrsBinned{2}'/60;
        t_bins_Rest3= REST.RESTbinCtrsBinned{3}'/60;
        t_bins_post= SLEEP.NremRemPOSTbinCtrs{1}'/60;

        if plotTypeTracks ~= "quality"
            % during pre - get average?
            dataPRE_LOW= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.reward == "LOW"));
            dataPRE_HIGH= cell2mat(SLEEP.NREM_REM_PREreplayRate(SLEEP.reward == "HIGH"));
    
            dataT1_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "LOW")); 
            dataT1_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "HIGH"));
    
            dataT2_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "LOW")); 
            dataT2_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "HIGH"));
    
            dataT3_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "LOW")); 
            dataT3_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "HIGH"));
    
            % during rest 1-3 - most recent
            dataRest1_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == 1 & REST.reward == "LOW"));
            dataRest1_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==1 & REST.track == 1 & REST.reward == "HIGH"));
            dataRest2_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == 2 & REST.reward == "LOW"));
            dataRest2_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==2 & REST.track == 2 & REST.reward == "HIGH"));
            dataRest3_LOW= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == 3 & REST.reward == "LOW"));
            dataRest3_HIGH= cell2mat(REST.RESTreplayRateBinned(REST.rest==3 & REST.track == 3 & REST.reward == "HIGH"));
    
            % post - here sleep only - T3
            dataPOST_LOW= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==3 & SLEEP.reward == "LOW"));
            dataPOST_HIGH= cell2mat(SLEEP.NremRemPOSTreplayRate(SLEEP.track==3 & SLEEP.reward == "HIGH"));
        else
            % during pr
            dataPRE_LOW= cell2mat(SLEEP.NREM_REM_PREreplayQuality(SLEEP.reward == "LOW"));
            dataPRE_HIGH= cell2mat(SLEEP.NREM_REM_PREreplayQuality(SLEEP.reward == "HIGH"));
    
            dataT1_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "LOW")); 
            dataT1_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==1 & TRACKS.reward == "HIGH"));
    
            dataT2_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "LOW")); 
            dataT2_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==2 & TRACKS.reward == "HIGH"));
    
            dataT3_LOW= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "LOW")); 
            dataT3_HIGH= cell2mat(TRACKS.(loc_var)(TRACKS.track==3 & TRACKS.reward == "HIGH"));
    
            % during rest 1-3 - most recent
            dataRest1_LOW= cell2mat(REST.RESTreplayQualityBinned(REST.rest==1 & REST.track == 1 & REST.reward == "LOW"));
            dataRest1_HIGH= cell2mat(REST.RESTreplayQualityBinned(REST.rest==1 & REST.track == 1 & REST.reward == "HIGH"));
            dataRest2_LOW= cell2mat(REST.RESTreplayQualityBinned(REST.rest==2 & REST.track == 2 & REST.reward == "LOW"));
            dataRest2_HIGH= cell2mat(REST.RESTreplayQualityBinned(REST.rest==2 & REST.track == 2 & REST.reward == "HIGH"));
            dataRest3_LOW= cell2mat(REST.RESTreplayQualityBinned(REST.rest==3 & REST.track == 3 & REST.reward == "LOW"));
            dataRest3_HIGH= cell2mat(REST.RESTreplayQualityBinned(REST.rest==3 & REST.track == 3 & REST.reward == "HIGH"));
    
            % post - here sleep only - T3
            dataPOST_LOW= cell2mat(SLEEP.NremRemPOSTreplayQuality(SLEEP.track==3 & SLEEP.reward == "LOW"));
            dataPOST_HIGH= cell2mat(SLEEP.NremRemPOSTreplayQuality(SLEEP.track==3 & SLEEP.reward == "HIGH"));
        end
            
        sessMeanLOW= [mean(dataPRE_LOW,1,'omitmissing') inf mean(dataT1_LOW,1,'omitmissing') inf mean(dataRest1_LOW,1,'omitmissing') inf...
            mean(dataT2_LOW,1,'omitmissing') inf mean(dataRest2_LOW,1,'omitmissing') inf mean(dataT3_LOW,1,'omitmissing') inf...
            mean(dataRest3_LOW,1,'omitmissing') inf mean(dataPOST_LOW,1,'omitmissing')];

        sessMeanHIGH= [mean(dataPRE_HIGH,1,'omitmissing') inf mean(dataT1_HIGH,1,'omitmissing') inf mean(dataRest1_HIGH,1,'omitmissing') inf...
            mean(dataT2_HIGH,1,'omitmissing') inf mean(dataRest2_HIGH,1,'omitmissing') inf mean(dataT3_HIGH,1,'omitmissing') inf...
            mean(dataRest3_HIGH,1,'omitmissing') inf mean(dataPOST_HIGH,1,'omitmissing')];
    
        semLOW= [nansem(dataPRE_LOW) inf nansem(dataT1_LOW) inf nansem(dataRest1_LOW) inf ...
            nansem(dataT2_LOW) inf nansem(dataRest2_LOW) inf nansem(dataT3_LOW) ...
            inf nansem(dataRest3_LOW) inf nansem(dataPOST_LOW)];
        semHIGH= [nansem(dataPRE_HIGH) inf nansem(dataT1_HIGH) inf nansem(dataRest1_HIGH) inf ...
            nansem(dataT2_HIGH) inf nansem(dataRest2_HIGH) inf nansem(dataT3_HIGH) ...
            inf nansem(dataRest3_HIGH) inf nansem(dataPOST_HIGH)];

        valid= ~isinf(sessMeanLOW);
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mvLOW = sessMeanLOW(epochIdx);
            svLOW = semLOW(epochIdx);
            mvHIGH = sessMeanHIGH(epochIdx);
            svHIGH = semHIGH(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mvLOW + svLOW fliplr(mvLOW - svLOW)];
            patch(x_fill, y_fill, cdata_rew{1}, ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
            y_fill = [mvHIGH + svHIGH fliplr(mvHIGH - svHIGH)];
            patch(x_fill, y_fill, cdata_rew{2}, ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        plot(sessMeanLOW,'Color',cdata_rew{1},'LineWidth',2);
        plot(sessMeanHIGH,'Color',cdata_rew{2},'LineWidth',2);

    xline(find(isinf(sessMeanLOW)),'k:','LineWidth',1);
    xt= 1:length(sessMeanLOW);
    xt(isinf(sessMeanLOW))=[];
    xticks(xt); xticklabels([t_bins_pre laps_T t_bins_Rest1 laps_T t_bins_Rest2 laps_T t_bins_Rest3 t_bins_post]);
 
    if plotTypeTracks == "min"
        xlabel('time (minutes)');
    elseif plotTypeTracks == "lap"
         xlabel('lap number');
    end
    if plotTypeTracks ~= "quality"
        ylabel('replay rate');
    else
        ylabel('replay score');
    end
    yl= ylim;
    text(length(t_bins_pre)/2,yl(2),'sleepPRE');
    st= length(t_bins_pre);
    text(st + length(laps_T)/2,yl(2),'Track1');
    st= st +length(laps_T)+1;
    text(st + length(t_bins_Rest1)/2,yl(2),'Rest1');
    st= st + length(t_bins_Rest1)+1;
    text(st + length(laps_T)/2,yl(2),'Track2');
    st= st + length(laps_T)+1;
    text(st + length(t_bins_Rest2)/2,yl(2),'Rest2');
    st= st + length(t_bins_Rest2)+1;
    text(st + length(laps_T)/2,yl(2),'Track3');
    st= st + length(laps_T);
    text(st + length(t_bins_Rest3)/2,yl(2),'Rest3');
    st= st + length(t_bins_Rest3);
    text(st + length(t_bins_post)/2,yl(2),'sleep POST');
    
    if plotCand
        % add Cand events
        SWR_PRE= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "PRE"});
        SWR_rest1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest1"});
        SWR_rest2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest2"});
        SWR_rest3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "Rest3"});
        SWR_sleepPOST= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "sleepPOST"});
        if plotTypeTracks == "min"
            SWR_rate_T1= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==1));
            SWR_rate_T2= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==2));
            SWR_rate_T3= cell2mat(TRACKS.cand_events_rate_min_immobile(TRACKS.track==3));
        elseif plotTypeTracks == "lap"
            SWR_rate_T1= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T1"});
            SWR_rate_T2= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T2"});
            SWR_rate_T3= vertcat(CANDIDATE.SWR_lap_rate{CANDIDATE.epoch == "T3"});
        end
        yyaxis right
        sessMean= [mean(SWR_PRE,1,'omitmissing') inf mean(SWR_rate_T1,1,'omitmissing') inf mean(SWR_rest1,1,'omitmissing') inf...
                mean(SWR_rate_T2,1,'omitmissing') inf mean(SWR_rest2,1,'omitmissing') inf mean(SWR_rate_T3,1,'omitmissing') inf...
                mean(SWR_rest3,1,'omitmissing') inf mean(SWR_sleepPOST,1,'omitmissing')];

        sessSem= [nansem(SWR_PRE) inf nansem(SWR_rate_T1) inf nansem(SWR_rest1) inf ...
                nansem(SWR_rate_T2) inf nansem(SWR_rest2) inf nansem(SWR_rate_T3) ...
                inf nansem(SWR_rest3) inf nansem(SWR_sleepPOST)];

        valid= ~isinf(sessMean);
        idx= find(valid);
        breaks = [0, find(diff(idx) > 1), numel(idx)];
        for b = 1:numel(breaks)-1
            epochIdx = idx(breaks(b)+1 : breaks(b+1));
            mv = sessMean(epochIdx);
            sv = sessSem(epochIdx);
            x_fill = [epochIdx fliplr(epochIdx)];
            y_fill = [mv + sv fliplr(mv - sv)];
            patch(x_fill, y_fill, [0.7 0.7 0.7], ...
                  'FaceAlpha', 0.2, ...   
                  'EdgeColor', 'none');
        end

        p(4)= plot(sessMean,'Color',[0.7 0.7 0.7],'LineWidth',2);
            % errorbar(sessMean,[nansem(SWR_PRE) NaN nansem(SWR_rate_T1) NaN nansem(SWR_rest1) NaN ...
            %     nansem(SWR_rate_T2) NaN nansem(SWR_rest2) NaN nansem(SWR_rate_T3) ...
            %     NaN nansem(SWR_rest3) NaN nansem(SWR_sleepPOST)],'Color',[0.7 0.7 0.7],'LineStyle','none')
        ylabel('Candidate event rate'); ylim([-0.2 0.99]); yticks([0:0.1:0.8])
        % legend(p,{'replay T1','replay T2','replay T3','cand events'},'Box','off');
    else
        % legend(p,{'replay T1','replay T2','replay T3'},'Box','off');
    end
end

set(gca,'TickDir','out')
end