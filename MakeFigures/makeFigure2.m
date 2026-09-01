function makeFigure2(opts)
%% Figure2
% PARAMS
% for imagesc plots
N = 256; 
cdata_whiteblue = [linspace(1,0,N).' linspace(1,0,N).' ones(N,1)]; 
white = [1, 1, 1];
load(fullfile(opts.dataFolder,'colour palettes','ScientificColourMaps6','berlin','DiscretePalettes','berlin10.mat'));
brown = berlin10(8,:);
cdata_whitebrown = (1 - linspace(0, 1, N)') .* white + linspace(0, 1, N)' .* brown;
REW_outerShift= [-0.4 0.4];

%% PRE REQ tables
% 'NEW_TABLES\replay\RLocalReplayLaps.csv'
% 'NEW_TABLES\replay\RSWRLaps.csv'
% 'NEW_TABLES\replay\RLocalFWDLaps.csv'
% 'NEW_TABLES\replay\RLocalREVLaps.csv'
% 'NEW_TABLES\replay\RRest1.csv','NEW_TABLES\replay\RRest2.csv','NEW_TABLES\replay\RRest3.csv'
% 'NEW_TABLES\replay\RsleepPOSTreplayRate_overall.csv'
% 'NEW_TABLES\replay\RPOSTreplayRate_overall.csv'
% 'NEW_TABLES\replay\LocalReplay_fixed_effects_speedLap.csv'
% 'NEW_TABLES\replay\LocalReplay_fixed_effects_all.csv'

load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));

%% PANEL C - Local replay x speed
warning('off');
figure;
nexttile; hold on;
dt= table; kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocal_per_lap{ii});
    for ll=1:numLaps
            dt.rat(kk)= TRACKS.rat(ii);
            dt.track(kk)= TRACKS.track(ii);
            dt.session(kk)= TRACKS.session_number(ii);
            dt.reward(kk)= TRACKS.reward(ii);
            dt.lap_number(kk)= ll;
            dt.event_rate(kk)= TRACKS.rateLocal_per_lap{ii}(ll);
            dt.duration(kk)= TRACKS.time_immobile_per_lap{ii}(ll);
            dt.speed(kk)= TRACKS.speed_imm_per_lap{ii}(ll);
            kk=kk+1;
    end
end
nBins = 4;
edges = [0.5:0.5:3.5]; 
binCenters = (edges(1:end-1) + edges(2:end))/2;
uSess = unique(dt.session);
sessMeans = nan(numel(uSess), numel(edges)-1);
for s = 1:numel(uSess)
    idxS = dt.session == uSess(s);
    for b = 1:numel(edges)-1
        idxB = idxS & dt.speed >= edges(b) & dt.speed < edges(b+1);
        if any(idxB)
            sessMeans(s,b) = mean(dt.event_rate(idxB), 'omitnan');
        end
    end
end
meanAcrossSess = mean(sessMeans, 1, 'omitnan');
semAcrossSess  = std(sessMeans, 0, 1, 'omitnan') ./ sqrt(sum(isfinite(sessMeans),1));
errorbar(binCenters, meanAcrossSess, semAcrossSess, 'k.', 'LineWidth', 1.5);
plot(binCenters, meanAcrossSess, 'k-', 'LineWidth', 1.5);
xlim([0 4])
xlabel('speed (cm/s)');
ylabel('event/s');
box off; title('local replay')
% simple regression
mdl= fitlm(binCenters,meanAcrossSess,'linear');
T= table;
T.y= 'sub threshold speed';
T.beta= mdl.Coefficients.Estimate(2);
T.SE= mdl.Coefficients.SE(2);
T.df= mdl.DFE;
T.t= mdl.Coefficients.tStat(2);
T.p= mdl.Coefficients.pValue(2);
writetable(T,fullfile(opts.dataFolder,'NEW_TABLES','replay','localReplayQuiescenceMdl.csv'));

%% PANEL D - replay rates during POST x speed
nexttile; hold on;
% {{'Wake',0}, {'Quiet',1}, {'NREM',2}, {'REM',3}};
allStatesPOST= [SLEEP.dominantState{:}];
allBinnedRatesPOST= [SLEEP.binnedRateAllTracks{:}];
allBinnedSpeedPOST= [SLEEP.binnedSpeed_z{:}];
edgesQ= linspace(-0.5,1.5,5);
binCentersQ = (edgesQ(1:end-1) + edgesQ(2:end))/2;
edgesS= linspace(-1,0,3);
binCentersS = (edgesS(1:end-1) + edgesS(2:end))/2;
sessMeansQ = nan(height(SLEEP)/3, numel(edgesQ)-1);
sessMeansS= nan(height(SLEEP)/3, numel(edgesS)-1);
dt=table; k=1;
for i=1:3:height(SLEEP) % each session is same as all events
    for b = 1:numel(edgesQ)-1
        idxQ = SLEEP.binnedSpeed_z{i} >= edgesQ(b) & SLEEP.binnedSpeed_z{i} < edgesQ(b+1) & ...
            (SLEEP.dominantState{i} == 0 | SLEEP.dominantState{i} == 1);
        sessMeansQ(floor(i/3)+1,b) = mean(SLEEP.binnedRateAllTracks{i}(idxQ),'omitmissing');

        dt.rat(k)= string(SLEEP.rat{i});
        dt.session(k)= string(SLEEP.session{i});
        dt.rate(k)= sessMeansQ(floor(i/3)+1,b);
        dt.speed_z(k)= binCentersQ(b);
        k=k+1;
    end
    for b = 1:numel(edgesS)-1
        idxS = SLEEP.binnedSpeed_z{i} >= edgesS(b) & SLEEP.binnedSpeed_z{i} < edgesS(b+1) & ...
            (SLEEP.dominantState{i} == 3 | SLEEP.dominantState{i} == 4);
        sessMeansS(floor(i/3)+1,b) = mean(SLEEP.binnedRateAllTracks{i}(idxS),'omitmissing');
    end
end
meanAcrossSessQ = mean(sessMeansQ, 1, 'omitnan');
semAcrossSessQ  = std(sessMeansQ, 0, 1, 'omitnan') ./ sqrt(sum(isfinite(sessMeansQ),1));
meanAcrossSessS = mean(sessMeansS, 1, 'omitnan');
semAcrossSessS  = std(sessMeansS, 0, 1, 'omitnan') ./ sqrt(sum(isfinite(sessMeansS),1));
errorbar(binCentersQ, meanAcrossSessQ, semAcrossSessQ, 'k', 'LineWidth', 1.5);
errorbar(binCentersS, meanAcrossSessS, semAcrossSessS, 'm', 'LineWidth', 1.5);
legend({'quiescence','sleep'},'Box','off','Location','northeast');
xlabel('zscores speed POST');
ylabel('event/s');
title('replay rates POST')

mdl= fitlme(dt,'rate ~ speed_z + (1|rat) + (1|rat:session)');
T= table;
T.y= 'z-scored speed';
T.beta= mdl.Coefficients.Estimate(2);
T.SE= mdl.Coefficients.SE(2);
T.df= mdl.DFE;
T.t= mdl.Coefficients.tStat(2);
T.p= mdl.Coefficients.pValue(2);
writetable(T,fullfile(opts.dataFolder,'NEW_TABLES','replay','replayQuiescencePOSTMdl.csv'));

%% PANEL E - estimated effects speed and reward
nexttile; hold on;
fixedEffSpeedLap= readtable(fullfile(opts.dataFolder,'NEW_TABLES','replay','LocalReplay_fixed_effects_speedLap.csv'));
speedEst= fixedEffSpeedLap.Estimate(fixedEffSpeedLap.Var1=="speed");
speedSE= fixedEffSpeedLap.Std_Error(fixedEffSpeedLap.Var1=="speed");
plot([1 1],[speedEst-speedSE speedEst+speedSE],'k','LineWidth',2);
plot(1,speedEst,'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','k','MarkerSize',10);
yline(0,'k:','LineWidth',1.5)

fixedEffSREwLap= readtable(fullfile(opts.dataFolder,'NEW_TABLES','replay','LocalReplay_fixed_effects_all.csv'));
rewEst= fixedEffSREwLap.Estimate(fixedEffSREwLap.Var1=="reward1");
rewSE= fixedEffSREwLap.Std_Error(fixedEffSREwLap.Var1=="reward1");
plot([2 2],[rewEst-rewSE rewEst+rewSE],'k','LineWidth',2);
plot(2,rewEst,'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','k','MarkerSize',10);
ylabel('local replay rate emmeans')
ylim([-0.03 0.01]); xlim([0.5 2.5]);
yticks([-0.01:0.01:0.01])
title('local replay modulation');
xticks([1 2]); xticklabels({'speed','reward'})
set(gca,'Box','off')

%% PANEL F - heatmaps replay counts per lap and time bin inside stop epoch
nexttile; hold on;
title('Local replay: LOW')
var= 'Local_replay_Lap_Num_cumulSec';
varSpeed= 'Local_binnedSpeed_lap_cumulSec';
idx= find(TRACKS.reward == "LOW");
dataLOW= {}; speedLOW= {}; tImmLOW= {}; numLapsToPlot= 20;
for ss=1:length(idx)
    dataLOW{ss}= NaN(numLapsToPlot,40);   
    speedLOW{ss}= NaN(numLapsToPlot,40);   
    tImmLOW{ss}= NaN(numLapsToPlot,1);
    sz=  size(TRACKS.(var){idx(ss)});
    dataLOW{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.(var){idx(ss)}(1:min(sz(1),numLapsToPlot),:);
    speedLOW{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.(varSpeed){idx(ss)}(1:min(sz(1),numLapsToPlot),:);
    tImmLOW{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.maxStopTime_lap_cumulSec{idx(ss)}(1:min(sz(1),numLapsToPlot));
end
dataCatLOW= nansum(cat(3,dataLOW{:}),3);
speedCatLOW= nanmean(cat(3,speedLOW{:}),3);
tImmCatLOW= nansum(cat(3,tImmLOW{:}),3);
imagesc(dataCatLOW,'AlphaData',~isnan(dataCatLOW));
set(gca,'YDir','reverse')
colormap(gca,cdata_whiteblue)
xlim([0 size(dataCatLOW,2)]+0.5); ylim([0 size(dataCatLOW,1)]+0.5)
xticks(0:10:40); xticklabels(0:5:20);
yticks([1 10 20])
xlabel('time (s)'); ylabel('half lap')
clim([0 5]); colorbar;

nexttile; hold on;
title('Local replay: HIGH')
idx= find(TRACKS.reward == "HIGH");
dataHIGH= {}; speedHIGH= {}; tImmHIGH={};
for ss=1:length(idx)
    dataHIGH{ss}= NaN(numLapsToPlot,40);
    speedHIGH{ss}= NaN(numLapsToPlot,40);
    tImmHIGH{ss}= NaN(numLapsToPlot,1);
    sz=  size(TRACKS.(var){idx(ss)});

    dataHIGH{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.(var){idx(ss)}(1:min(sz(1),numLapsToPlot),:);
    speedHIGH{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.(varSpeed){idx(ss)}(1:min(sz(1),numLapsToPlot),:);
    tImmHIGH{ss}(1:min(sz(1),numLapsToPlot),:)= TRACKS.maxStopTime_lap_cumulSec{idx(ss)}(1:min(sz(1),numLapsToPlot));

end
dataCatHIGH= nansum(cat(3,dataHIGH{:}),3);
speedCatHIGH= nanmean(cat(3,speedHIGH{:}),3);
tImmCatHIGH= nansum(cat(3,tImmHIGH{:}),3);
imagesc(dataCatHIGH,'AlphaData',~isnan(dataCatHIGH));
set(gca,'YDir','reverse')
colormap(gca,cdata_whitebrown)
xlim([0 size(dataCatHIGH,2)]+0.5); ylim([0 size(dataCatHIGH,1)]+0.5)
xticks(0:10:40); xticklabels(0:5:20);
yticks([1 10 20])
xlabel('time (s)'); ylabel('half lap')
clim([0 5]);colorbar;

nexttile; hold on;
fill([1:40 fliplr(1:40)],[mean(dataCatHIGH,1,'omitmissing')-nansem(dataCatHIGH) fliplr(mean(dataCatHIGH,1,'omitmissing')+nansem(dataCatHIGH))],...
    opts.cdata_rew{2},'FaceAlpha',0.5,'EdgeColor','none')
fill([1:40 fliplr(1:40)],[mean(dataCatLOW,1,'omitmissing')-nansem(dataCatLOW) fliplr(mean(dataCatLOW,1,'omitmissing')+nansem(dataCatLOW))],...
    opts.cdata_rew{1},'FaceAlpha',0.5,'EdgeColor','none')
plot(mean(dataCatHIGH,1,'omitmissing'),'Color',opts.cdata_rew{2},'LineWidth',2);
plot(mean(dataCatLOW,1,'omitmissing'),'Color',opts.cdata_rew{1},'LineWidth',2);
xlabel('time (s)'); ylabel('mean counts')

%% PANEL G - LOCAL REPLAY RATE x reward
nexttile; hold on;
title('Local replay rates');
data= cellfun(@mean, TRACKS.rateLocal_per_lap);
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.replay_rats)
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    else
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k', ...
            'MarkerFaceColor','w')
    end
end
ylabel('Event/s');  xlabel('Reward')
ylim([0.02 0.2]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})

%% PANEL G inset - FWD REV REPLAY RATES x reward
nexttile; hold on;
data= cellfun(@mean, TRACKS.rateLocalFWD_per_lap);
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.replay_rats)
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    else
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k', ...
            'MarkerFaceColor','w')
    end
end
ylabel('Event/s');  xlabel('Reward')
ylim([0 0.1]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})
title('Forward replay');

nexttile; hold on;
data= cellfun(@mean, TRACKS.rateLocalREV_per_lap);
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.replay_rats)
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    else
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k', ...
            'MarkerFaceColor','w')
    end
end
ylabel('Event/s');  xlabel('Reward')
ylim([0 0.1]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})
title('Reverse replay');

%% PANEL H - SLEEP REPLAY RATE in sleep POST x reward
nexttile; hold on;
data= SLEEP.sleepPOSTreplayRate_overall;
for thisRat=1:length(opts.rats)
    if ismember(opts.rats{thisRat},opts.replay_rats)
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
            'MarkerFaceColor',[0.5 0.5 0.5])
    else
        plot(REW_outerShift,...
            arrayfun(@(x) mean(data(TRACKS.reward == opts.REW(x) & TRACKS.rat== string(opts.rats{thisRat}))),1:2),...
            'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',opts.Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k', ...
            'MarkerFaceColor','w')
    end
end
ylabel('Event/s');  xlabel('Reward')
ylim([0 0.05]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})
title('SleepPOST replay');

warning('on');
end