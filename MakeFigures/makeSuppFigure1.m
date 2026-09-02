function makeSuppFigure1(opts)
%% Figure S1
%% REQ TABLES
% stats tables in NEW_TABLES\behaviour (generateTables.m for Figure 1)
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_BEHAVIOUR.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));

%% NUMBER OF LAPS
figure;
nexttile; hold on;
title({'number of laps'})
data= TRACKS.num_laps;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_number_of_laps.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_number_of_laps.csv'),...
                            'plot_individual',1);
ylabel('number of laps')
ylim([0 40]); 

%% TIME SPENT IMMOBILE (REWARD ZONE)
nexttile; hold on;
title({'time immobile','at reward sites'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_end_zones_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_total_imm_END.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_total_imm_END.csv'),...
                            'plot_individual',1);
ylabel('time immobile per lap (s)'); 
ylim([0 40]); 

%% STOPPING SPEED
nexttile; hold on;
title('immobility')
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speedSLOW_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_stop_speed.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_stop_speed.csv'),...
                            'plot_individual',1);
ylabel('speed per lap <5cm/s (cm/s)'); 
ylim([0 4])

%% TIME SPENT IMMOBILE (TOTAL)
nexttile; hold on;
title({'total time immobile','(anywhere)'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.time_immobile_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_total_imm.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_total_imm.csv'),...
                            'plot_individual',1)
ylabel('time immobile per lap (s)');  
ylim([0 120])

%% TIME SPENT IMMOBILE (RUN ZONE)
nexttile; hold on;
title('time immobile (run zone)')
data= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_time_run_zones_immobile_per_min.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_time_run_zones_immobile_per_min.csv'),...
                            'plot_individual',1)
ylabel('time immobile per min (s)'); ylim([0 50])


%% RUNNING SPEED
nexttile; hold on;
title({'running speed'})
data= cellfun(@(x) mean(x,'omitmissing'), TRACKS.speed_per_lap);
plotDataEmmeansContrasts(TRACKS,data,opts,...
                            fullfile('NEW_TABLES','behaviour','emmeans','behaviour_emmeans_run_speed.csv'),...
                            fullfile('NEW_TABLES','behaviour','contrasts','behaviour_contrasts_run_speed.csv'),...
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

%% LATENCY TO SLEEP
time_to_quiet= [];
time_to_sleep= []; cond={};
uniqueSess= unique(SLEEP.session);
for thisS=1:length(uniqueSess)
    idx= find(SLEEP.session == string(uniqueSess{thisS}));
    cond{thisS}= strjoin(SLEEP.reward(idx),'-');
    satiety(thisS)= sum(SLEEP.reward(idx) == "HIGH");
    time_to_quiet(thisS)= SLEEP.time_to_QUIET(idx(1));
    time_to_sleep(thisS)= min([SLEEP.time_to_NREM(idx(1)) SLEEP.time_to_REM(idx(1))]);
    isT3High(thisS) = SLEEP.reward(idx(3)) =="HIGH";
    speedProfile{thisS}= SLEEP.binnedSpeed_z{idx(1)};
    dominantState{thisS}= SLEEP.dominantState{idx(1)};
    
end
T=table(uniqueSess,cond',satiety',isT3High',time_to_quiet',time_to_sleep',speedProfile',dominantState',...
    'VariableNames',{'session','cond','satiety','isT3High','time_to_quiet','time_to_sleep','speedProfile','dominantState'});

T= sortrows(T,'isT3High','descend');
uniqueCond= unique(T.cond,'stable');

nexttile; hold on;
title('immobility before sleep')
% take only X first min
dataT3LOW= vertcat(T.speedProfile{~T.isT3High});
dataT3LOW= dataT3LOW(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
fill([1:size(dataT3LOW,2) fliplr(1:size(dataT3LOW,2))],...
    smooth([mean(dataT3LOW)-nansem(dataT3LOW)   fliplr(mean(dataT3LOW)+nansem(dataT3LOW))],10), ...
    opts.cdata_rew{1},'FaceAlpha',0.1,'EdgeColor','none')
p1= plot(smooth(mean(dataT3LOW),10),'Color',opts.cdata_rew{1},'LineWidth',1);
dataT3HIGH= vertcat(T.speedProfile{T.isT3High});
dataT3HIGH= dataT3HIGH(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
fill([1:size(dataT3HIGH,2) fliplr(1:size(dataT3HIGH,2))],...
    smooth([mean(dataT3HIGH)-nansem(dataT3HIGH)   fliplr(mean(dataT3HIGH)+nansem(dataT3HIGH))],10), ...
    opts.cdata_rew{2},'FaceAlpha',0.1,'EdgeColor','none')
p2= plot(smooth(mean(dataT3HIGH),10),'Color',opts.cdata_rew{2},'LineWidth',1);
ylabel('zscored speed'); xlabel('time (min)');
t_bins= SLEEP.statesTimeBinsCtrs{1};
xt= 1:20:length(t_bins);
xtl= t_bins(xt)/60;
xticks(xt); xticklabels(xtl);
ylim([-0.6 0.8])
legend([p1 p2], {'T3 LOW','T3 HIGH'},'Box','off','Location','northeast')

nexttile; hold on;
title('latency to sleep: last track')
% take only X first min
dataT3LOW= vertcat(T.dominantState{~T.isT3High});
dataT3LOW= dataT3LOW(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
plot(smooth(sum(dataT3LOW==3 | dataT3LOW==4),10),'Color',opts.cdata_rew{1},'LineWidth',1);
dataT3HIGH= vertcat(T.dominantState{T.isT3High});
dataT3HIGH= dataT3HIGH(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
plot(smooth(sum(dataT3HIGH==3 | dataT3HIGH==4),10),'Color',opts.cdata_rew{2},'LineWidth',1);
ylabel('number of sessions'); xlabel('time (min)');
t_bins= SLEEP.statesTimeBinsCtrs{1};
xt= 1:20:length(t_bins);
xtl= t_bins(xt)/60;
xticks(xt); xticklabels(xtl);
legend({'T3 LOW','T3 HIGH'},'Box','off','Location','southeast')


T= sortrows(T,'satiety','descend');
uniqueSet= unique(T.satiety,'stable');

nexttile; hold on;
title({'immobility before sleep:';'satiety'})
p=[];
for thisS=1:length(uniqueSet)
    idx= T.satiety == uniqueSet(thisS);
    dataCond= vertcat(T.speedProfile{idx});
    dataCond= dataCond(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
    if thisS==1
        fill([1:size(dataCond,2) fliplr(1:size(dataCond,2))],...
            smooth([mean(dataCond)-nansem(dataCond)   fliplr(mean(dataCond)+nansem(dataCond))],10), ...
            'k','FaceAlpha',0.1,'EdgeColor','none')
        p(thisS)= plot(smooth(mean(dataCond),10),'Color','k','LineWidth',1);
    else
        fill([1:size(dataCond,2) fliplr(1:size(dataCond,2))],...
            smooth([mean(dataCond)-nansem(dataCond)   fliplr(mean(dataCond)+nansem(dataCond))],10), ...
            'k','FaceAlpha',0.05,'EdgeColor','none')
        p(thisS)=plot(smooth(mean(dataCond),10),'Color','k','LineWidth',1,'LineStyle',':');
    end
end
ylabel('zscored speed '); xlabel('time (min)');
t_bins= SLEEP.statesTimeBinsCtrs{1};
xt= 1:20:length(t_bins);
xtl= t_bins(xt)/60;
xticks(xt); xticklabels(xtl);
legend(p,{'two HIGH tracks','two LOW tracks'},'Box','off')

nexttile;hold on;
title('latency to sleep: satiety')
for thisS=1:length(uniqueSet)
    idx= T.satiety == uniqueSet(thisS);
    dataCond= vertcat(T.dominantState{idx});
    dataCond= dataCond(:,SLEEP.statesTimeBinsCtrs{1} < 60*60);
    if thisS==1
        plot(smooth(sum(dataCond==3 | dataCond==4),10),'Color','k','LineWidth',1);
    else
        plot(smooth(sum(dataCond==3 | dataCond==4),10),'Color','k','LineWidth',1,'LineStyle',':');
    end
end
ylabel('number of sessions'); xlabel('time (min)')
xticks(xt); xticklabels(xtl);
legend({'two HIGH tracks','two LOW tracks'},'Box','off')

end