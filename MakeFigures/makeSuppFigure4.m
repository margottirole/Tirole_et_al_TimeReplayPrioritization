function makeSuppFigure4(opts)
%% Figure S4
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

figure;
%% PRE
nexttile; hold on;
title('replay: PRE (overall)');
data= SLEEP.PREreplayRate;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','emmeans_PRE_overall.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','contrasts_PRE_overall.csv'),...
                            'plot_individual',1)
ylabel('Event/s'); 
ylim([0 0.025]); 

nexttile; hold on;
title('replay: sleep PRE (overall)');
data= cellfun(@mean, SLEEP.sleepPREreplayRate);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','emmeans_SleepPRE_overall.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','contrasts_SleepPRE_overall.csv'),...
                            'plot_individual',1)
ylabel('Event/s'); 
ylim([0 0.025]); 

%% TRACKS
nexttile; hold on
title('Candidate events on tracks');
data= cellfun(@mean, TRACKS.rateSWR_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','SWR_emmeans.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','SWR_contrasts.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0.2 0.6]); 

nexttile; hold on;
title('local replay');
data= cellfun(@mean, TRACKS.rateLocal_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','LocalReplay_emmeans.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','LocalReplay_contrasts.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.25]); 

nexttile; hold on;
title('local FWD replay');
data= cellfun(@mean, TRACKS.rateLocalFWD_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','LocalFWDLaps_emmeans.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','LocalFWDLaps_contrasts.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.12]); 

nexttile; hold on;
title('local REV replay');
data= cellfun(@mean, TRACKS.rateLocalREV_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','LocalREVLaps_emmeans.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','LocalREVLaps_contrasts.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.12]); 

%% RESTS
for thisR=1:3
    nexttile; hold on;
    title(['replay: REST' num2str(thisR)]);
    data= REST.replayRate(REST.rest == thisR);
    plotDataEmmeansContrasts(TRACKS,data,opts,...
                                fullfile('NEW_TABLES','replay','emmeans',['emmeans_Rest' num2str(thisR) '.csv']),...
                                fullfile('NEW_TABLES','replay','contrasts',['contrasts_Rest' num2str(thisR) '.csv']),...
                                'plot_individual',1);
    ylabel('Event/s'); 
    ylim([0 0.11]);
end

%% sleep POST
nexttile; hold on;
title('replay: POST (overall)');
data= SLEEP.POSTreplayRate_overall;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','emmeans_POST_overall.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','contrasts_POST_overall.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.06]);

nexttile; hold on;
title('replay: sleep POST first 15 min');
data= cell2mat(SLEEP.NremRemPOSTreplayRate_0_to_900);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','emmeans_SleepPOST_firstXmin.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','contrasts_SleepPOST_firstXmin.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.09]);

nexttile; hold on;
title('replay: sleep POST (overall)');
data= SLEEP.sleepPOSTreplayRate_overall;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','replay','emmeans','emmeans_SleepPOST_overall.csv'),...
                            fullfile('NEW_TABLES','replay','contrasts','contrasts_SleepPOST_overall.csv'),...
                            'plot_individual',1);
ylabel('Event/s'); 
ylim([0 0.09]);

end