function makeFigure3(opts)
%% Figure3

%% PRE REQ tables
% 'NEW_TABLES\replay\RLocalReplayLaps.csv'
% 'NEW_TABLES\RSWRLaps.csv'
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));

dt= readtable(fullfile(opts.dataFolder,'NEW_TABLES','replay','sleepPOSTcumulTime.csv'));
% run stats
mdl= fitlme(dt,'rate ~ time + (1|rat) + (1|rat:session)');
T= table;
T.y= 'cumulative time in sleep ';
T.beta= mdl.Coefficients.Estimate(2);
T.SE= mdl.Coefficients.SE(2);
T.df= mdl.DFE;
T.t= mdl.Coefficients.tStat(2);
T.p= mdl.Coefficients.pValue(2);
writetable(T,fullfile(opts.dataFolder,'NEW_TABLES','replay','replayTimeSleepPOSTMdl.csv'));

%% run stats for cand events (local replay already ran for fig 2)
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','replay');
r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_FULL.R');    

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script,wd_path,'RSWRLaps.csv','','SWR');
[status, out] = system(cmd);
if status ~= 0
  error('RSWR call failed:\n%s', out);
end

%% PANEL A - TIMELINE on tracks
figure;
nexttile;
plotReplayTimeline(TRACKS,SLEEP,REST,CANDIDATE,'plotVar','tracks_only','plotTypeTracks','lap','plotCand',0);
ylabel('Event/s'); xlabel('laps ')

%% PANEL B - Candidate events x recency
nexttile; hold on
data= cellfun(@mean, TRACKS.rateSWR_per_lap);
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.rats)
        
        plot(1:3,...
            arrayfun(@(x) mean(data(TRACKS.track == x & TRACKS.rat== string(opts.rats{thisRat}))),1:3),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    end
end
ylabel('Event/s');  xlabel('Track')
ylim([0.1 0.4]); xlim([0 4]); xticks(1:3); xticks(1:3); %xticklabels({'T1','T2','T3'})
title('Candidate Events')

%% PANEL C - Local replay x recency
nexttile; hold on
data= cellfun(@mean, TRACKS.rateLocal_per_lap);
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.rats)
        plot(1:3,...
            arrayfun(@(x) mean(data(TRACKS.track == x & TRACKS.rat== string(opts.rats{thisRat}))),1:3),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    end
end
ylabel('Event/s');  xlabel('Track')
ylim([0.05 0.15]); xlim([0 4]); xticks(1:3); xticks(1:3); %xticklabels({'T1','T2','T3'})
title('Local replay')

%% PANEL D - Local/remote replay as fraction of candidate events x recency
nexttile; hold on
fractionLocal= TRACKS.Local_replay_number ./ CANDIDATE.SWR_number(ismember(CANDIDATE.epoch,{'T1','T2','T3'}));
fractionremoten1= TRACKS.remote_n1_replay_number ./ CANDIDATE.SWR_number(ismember(CANDIDATE.epoch,{'T1','T2','T3'}));
fractionremoten2= TRACKS.remote_n2_replay_number ./ CANDIDATE.SWR_number(ismember(CANDIDATE.epoch,{'T1','T2','T3'}));
tmpLoc= [fractionLocal(TRACKS.track==1) fractionLocal(TRACKS.track==2) fractionLocal(TRACKS.track==3)];
tmpRem1= [fractionremoten1(TRACKS.track==1) fractionremoten1(TRACKS.track==2) fractionremoten1(TRACKS.track==3)];
tmpRem2= [fractionremoten2(TRACKS.track==1) fractionremoten2(TRACKS.track==2) fractionremoten2(TRACKS.track==3)];
b= bar([mean(tmpLoc); mean(tmpRem1) ; mean(tmpRem2)]','stacked','EdgeColor','flat','LineWidth',2,'FaceColor','none');
b(1).CData= cell2mat(opts.cdata_rec');
b(2).CData= repmat([0.5 0.5 0.5],3,1); b(2).LineWidth=1.5;
b(3).CData= repmat([0.7 0.7 0.7],3,1); b(3).LineWidth=1.5;
title('local + remote replay fraction');
ylabel('# replays / # Cand Events'); ylim([0 0.61])
xlabel('track'); xticks(1:3)
legend({'local','online remote'})

%% PANEL E + G - timeline during rest epochs and sleep POST
nexttile; hold on;
plotReplayTimeline(TRACKS,SLEEP,REST,CANDIDATE,'plotVar','offline_only','plotTypeTracks','min','plotCand',0);
ylabel('Event/s'); xlabel('laps ')

%% PANEL F - cumulative number of replay events before sleep (and fraction local/remote)
nexttile; hold on;
numEventsBeforeSleep= TRACKS.total_events_beforeSleepPOST;
numEventsLocal= TRACKS.totalLocal_events_beforeSleepPOST;
numEventsRemote= TRACKS.totalRemote_events_beforeSleepPOST;
tmpNumLocal= [numEventsLocal(TRACKS.track==1) numEventsLocal(TRACKS.track==2) numEventsLocal(TRACKS.track==3)];
tmpNumRemote= [numEventsRemote(TRACKS.track==1) numEventsRemote(TRACKS.track==2) numEventsRemote(TRACKS.track==3)];
b= bar(mean(tmpNumLocal),'EdgeColor','flat','LineWidth',2,'FaceColor','none');
b= bar([mean(tmpNumLocal); mean(tmpNumRemote)]','stacked','EdgeColor','flat','LineWidth',2,'FaceColor','none');
b(1).CData= cell2mat(opts.cdata_rec');
b(2).CData= cell2mat(opts.cdata_rec'); b(2).LineWidth=2;
xticks(1:3); xlabel('track'); ylabel('counts');
title('counts prior to sleep'); set(gca,'Box','off')

end