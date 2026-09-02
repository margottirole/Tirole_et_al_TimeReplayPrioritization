function makeSuppFigure5(opts)
%% Figure S5
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

%%
figure;
% LOCAL REPLAY RATE
nexttile; hold on;
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.rateLocal_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','REWSITE','emmeans','LocalReplay_emmeans.csv'),...
                            fullfile('NEW_TABLES','REWSITE','contrasts','LocalReplay_contrasts.csv'),...
                            'plot_individual',1)
title({'Local replay rates';'at reward sites'})
ylabel('Event/s'); 
ylim([0 0.25]); 

% FWD REPLAY RATE
nexttile; hold on;
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.rateLocalFWD_per_lap_REWSITE);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','REWSITE','emmeans','LocalFWDLaps_emmeans.csv'),...
                            fullfile('NEW_TABLES','REWSITE','contrasts','LocalFWDLaps_contrasts.csv'),...
                            'plot_individual',1)
title({'Local forward replay rates';'at reward sites'})
ylabel('Event/s'); 
ylim([0 0.2]); 


% REV FWD REPLAY RATE
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.rateLocalREV_per_lap_REWSITE);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','REWSITE','emmeans','LocalREVLaps_emmeans.csv'),...
                            fullfile('NEW_TABLES','REWSITE','contrasts','LocalREVLaps_contrasts.csv'),...
                            'plot_individual',1)
title({'Local reverse replay rates';'at reward sites'})
ylabel('Event/s'); 
ylim([0 0.2]); 

% Cand EVENTS REPLAY RATE
nexttile; hold on;
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.rateSWR_per_lap_REWSITE);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','REWSITE','emmeans','SWR_emmeans.csv'),...
                            fullfile('NEW_TABLES','REWSITE','contrasts','SWR_contrasts.csv'),...
                            'plot_individual',1)
title({'Candidate event rates';'at reward sites'})
ylabel('Event/s'); 
ylim([0.1 0.8]); 

end
