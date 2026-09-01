function makeFigure1(opts)
%% Figure1
% panels A and B are schematics - no code

%% REQ TABLES
% 'NEW_TABLES\behaviour\Rbehaviour.csv
% 'NEW_TABLES\behaviour\Rbehaviour_perLap.csv'
foodPref= readtable(fullfile(opts.dataFolder,'NEW_TABLES','foodPref.csv'));
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_BEHAVIOUR.mat'));

%% PANEL C - REWARD PREFERENCE
warning('off');
figure;
nexttile;
title({'Preference test:';'HIGH vs LOW'});
foodPref.pref_index2= foodPref.percent_subs1 ./ (foodPref.percent_subs1 + foodPref.percent_subs2);
prefrats= unique(foodPref.RAT); 
for thisRat=1:length(prefrats)
    pref= foodPref.pref_index2(foodPref.test_type == "chocolate vs 1x dilution" & ...
        foodPref.RAT == string(prefrats{thisRat}));
    pretty_boxplot(pref,'marker',opts.Mrks{thisRat},'positions',thisRat,'cdata',{[0 0 0]},'marker_alpha',0);
end
yline(0.5,'k:'); yticks(0:0.5:1);
xticks(1:5); xticklabels(prefrats);  ylim([0 1])
ylabel('preference index'); set(gca,'Box','off')

%% PANEL D - NUMBER OF LAPS
nexttile; hold on;
title('Number of laps')
data= TRACKS.num_laps;
REW_outerShift= [-0.4 0.4];
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
ylabel('number of laps'); xlabel('Reward')
ylim([5 25]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})

%% PANEL E - TIME SPENT IMMOBILE (REWARD SITES)
nexttile; hold on;
title('Time immobile reward sites')
data= cellfun(@(x) nanmean(x), TRACKS.time_end_zones_immobile_per_lap);
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
ylabel('time immobile per lap (s)');  xlabel('Reward')
ylim([0 30]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})

%% PANEL D - SUBTHRESHOLD SPEED
nexttile; hold on;
title('stopping speed')
data= cellfun(@nanmean, TRACKS.speedSLOW_per_lap);
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
ylabel('stopping speed per lap (cm/s)');  xlabel('Reward')
ylim([1 2.7]); xlim([-1 1]); xticks(REW_outerShift); xticklabels({'LOW','HIGH'})
warning('on');
end