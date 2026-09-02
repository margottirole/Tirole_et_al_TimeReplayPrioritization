function makeSuppFigure3(opts)
%% Figure S3
%% REQ TABLES
load(fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats','TRACKS_BEHAVIOUR.mat'))

%% NUMBER OF LAPS
figure;
nexttile; hold on;
title({'number of laps'})
data= TRACKS.num_laps;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                        fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_number_of_laps.csv'),...
                        fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_number_of_laps.csv'),...
                        'plot_individual',1);
ylabel('number of laps')
ylim([0 40]); 

%% TIME SPENT IMMOBILE (REWARD ZONE)
nexttile; hold on;
title({'time immobile','at reward sites'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_end_zones_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_total_imm_END.csv'),...
                            fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_total_imm_END.csv'),...
                            'plot_individual',1);
ylabel('time immobile per lap (s)'); 
ylim([0 40]); 

%% STOPPING SPEED
nexttile; hold on;
title('sub threshold speed')
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speedSLOW_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_stop_speed.csv'),...
                            fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_stop_speed.csv'),...
                            'plot_individual',1);
ylabel('speed per lap <5cm/s (cm/s)'); 
ylim([0 4])

%% TIME SPENT IMMOBILE (TOTAL)
nexttile; hold on;
title({'total time immobile','(anywhere)'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_total_imm.csv'),...
                            fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_total_imm.csv'),...
                            'plot_individual',1)
ylabel('time immobile per lap (s)');  
ylim([0 120])

%% TIME SPENT IMMOBILE (RUN ZONE)
nexttile; hold on;
title('time immobile (run zone)')
data= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_time_run_zones_immobile_per_min.csv'),...
                            fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_time_run_zones_immobile_per_min.csv'),...
                            'plot_individual',1)
ylabel('time immobile per min (s)'); ylim([0 50])


%% RUNNING SPEED
nexttile; hold on;
title({'running speed'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speed_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviourReplayRats','emmeans','behaviour_emmeans_run_speed.csv'),...
                            fullfile('NEW_TABLES','behaviourReplayRats','contrasts','behaviour_contrasts_run_speed.csv'),...
                            'plot_individual',1)
ylabel('speed per lap (cm/s)'); ylim([5 35]); 


end