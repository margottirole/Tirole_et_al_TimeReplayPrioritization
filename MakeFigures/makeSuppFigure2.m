function makeSuppFigure2(opts)
%% Figure S2
%% REQ TABLES
speedThresh= 2;
load(fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'TRACKS_BEHAVIOUR.mat'))

%% NUMBER OF LAPS
figure;
nexttile; hold on;
title({'number of laps'})
data= TRACKS.num_laps;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                        fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_number_of_laps.csv'),...
                        fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_number_of_laps.csv'),...
                        'plot_individual',1);
ylabel('number of laps')
ylim([0 40]); 

%% TIME SPENT IMMOBILE (REWARD ZONE)
nexttile; hold on;
title({'time immobile','at reward sites'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_end_zones_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_total_imm_END.csv'),...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_total_imm_END.csv'),...
                            'plot_individual',1);
ylabel('time immobile per lap (s)'); 
ylim([0 40]); 

%% STOPPING SPEED
nexttile; hold on;
title('immobility')
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speedSLOW_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_stop_speed.csv'),...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_stop_speed.csv'),...
                            'plot_individual',1);
ylabel('speed per lap <5cm/s (cm/s)'); 
ylim([0 4])

%% TIME SPENT IMMOBILE (TOTAL)
nexttile; hold on;
title({'total time immobile','(anywhere)'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_total_imm.csv'),...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_total_imm.csv'),...
                            'plot_individual',1)
ylabel('time immobile per lap (s)');  
ylim([0 120])

%% TIME SPENT IMMOBILE (RUN ZONE)
nexttile; hold on;
title('time immobile (run zone)')
data= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_time_run_zones_immobile_per_min.csv'),...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_time_run_zones_immobile_per_min.csv'),...
                            'plot_individual',1)
ylabel('time immobile per min (s)'); ylim([0 50])


%% RUNNING SPEED
nexttile; hold on;
title({'running speed'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speed_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'emmeans','behaviour_emmeans_run_speed.csv'),...
                            fullfile('NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'contrasts','behaviour_contrasts_run_speed.csv'),...
                            'plot_individual',1)
ylabel('speed per lap (cm/s)'); ylim([5 35]); 


%% DISTRIBUTION SPEEDS
nexttile; hold on;
title({'stopping speed'})
var= 'Local_binnedSpeed_lap_cumulSec';
dataCat= []; dataMean=[];
for thisR=1:2
    idx= find(TRACKS.reward==opts.REW(thisR));
    speed= {}; 
    for ss=1:length(idx)
        speed{ss}= NaN(10,40);
        sz=  size(TRACKS.(var){idx(ss)});
        for ll=1:10
            speed{ss}(1:min(sz(1),10),:)= TRACKS.(var){idx(ss)}(1:min(sz(1),10),:);
        end
    end
    dataCat{thisR}= mean(cat(3,speed{:}),3,'omitmissing');
    dataMean(thisR,:)= mean(dataCat{thisR},1,'omitmissing');
    
    fill([1:size(dataMean,2) fliplr([1:size(dataMean,2)])],...
        [dataMean(thisR,:) - nansem(dataCat{thisR}) fliplr(dataMean(thisR,:) + nansem(dataCat{thisR}) )],opts.cdata_rew{thisR},...
        'FaceAlpha',0.2,'EdgeColor','none')
    plot(dataMean(thisR,:),'Color',opts.cdata_rew{thisR},'LineWidth',1.5);
end
xticks(0:10:40); xticklabels(0:5:20);
xlabel('cumulative stopping time'); ylabel('speed cm/s')
title('stopping speed distributions')


end