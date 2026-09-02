function makeSuppFigure6(opts)
%% Figure S6
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

%% SHOW TIMELINES
figure;
nexttile; hold on;
plotReplayTimeline(TRACKS,SLEEP,REST,CANDIDATE,'plotVar','selective_reward','plotCand',0,'plotTypeTracks','quality');
ylim([0.4 1]); ylabel('weighted correlation');

nexttile; hold on;
plotReplayTimeline(TRACKS,SLEEP,REST,CANDIDATE,'plotVar','tracks','plotCand',0,'plotTypeTracks','quality');
ylim([0.4 1]); ylabel('weighted correlation');

%% REPLAY QUALITY
nexttile; hold on;
title('local replay quality')
data= TRACKS.Local_replay_meanWScore;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                        fullfile('NEW_TABLES','quality','emmeans','quality_emmeans_Localquality.csv'),...
                        fullfile('NEW_TABLES','quality','contrasts','quality_contrasts_Localquality.csv'),...
                        'plot_individual',1);
ylabel('weighted correlation'); ylim([0.4 1])
xlabel('Track')

nexttile; hold on
title('local forward replay quality')
data= TRACKS.LocalForward_replay_meanWScore;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                        fullfile('NEW_TABLES','quality','emmeans','quality_emmeans_LocalFWDquality.csv'),...
                        fullfile('NEW_TABLES','quality','contrasts','quality_contrasts_LocalFWDquality.csv'),...
                        'plot_individual',1);
ylabel('weighted correlation'); ylim([0.4 1])
xlabel('Track')

nexttile; hold on
title('local reverse replay qualitys')
data= TRACKS.LocalReverse_replay_meanWScore;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                         fullfile('NEW_TABLES','quality','emmeans','quality_emmeans_LocalREVquality.csv'),...
                        fullfile('NEW_TABLES','quality','contrasts','quality_contrasts_LocalREVquality.csv'),...
                        'plot_individual',1);
ylabel('weighted correlation'); ylim([0.4 1])
xlabel('Track')

nexttile; hold on;
dataPAST= mean([TRACKS.remote_n1_replay_meanWScore TRACKS.remote_n2_replay_meanWScore],2,'omitmissing');
dataLOCAL= TRACKS.Local_replay_meanWScore;
dataFUTURE= mean([TRACKS.future_n1_replay_meanWScore TRACKS.future_n2_replay_meanWScore],2,'omitmissing');
pretty_boxplot([dataPAST dataLOCAL dataFUTURE]);
xticklabels({'PAST','LOCAL','FUTURE'})
ylim([0.4 1])
title('replay type')

[p,tbl,stats] = kruskalwallis([dataPAST dataLOCAL dataFUTURE],[],'off');
c= multcompare(stats,'CriticalValueType','tukey-kramer','Display','off');


end