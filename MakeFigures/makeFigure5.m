function makeFigure5(opts)
%% Figure 5

%% PRE REQ
% obtain table replay rates
load(fullfile(opts.dataFolder,'NEW_TABLES','Replay_Decay_Model','ReplaysTable.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','Replay_Decay_Model','tauResults_trainSleep.mat'));
% print best tau
tau_best_global = tauResult.tau_best_byTotalBIC;
disp(['Tau= ' num2str(tau_best_global/60)])

%% PLOT
modelNames= {'Model 1: local only',...
    'Model 2: all online events',...
    'Model 3: all events (online and offline)',...
    'Model 5: local only, no decay',...
    'Model 6: Rest3 only',...
    'Model 4: offline only'};
numModels= length(modelNames);
modelColors= colormap('cool');
cIdx= round(linspace(1,size(modelColors,1),3));
modelColors = [modelColors(cIdx,:);...
                0*[1 1 1];...
                0.5*[1 0.5 1];...
                0.7*[0.5 1 1]];

figure;
for m=1:size(tauResult.BIC,2)
    m2= size(tauResult.BIC,2) - m +1; % plot models last, controls first
    nexttile(1); hold on;
    p(m)= plot(tauResult.tauGrid/60,tauResult.BIC(:,m2),'Color',modelColors(m2,:),'LineWidth',2);
    xline(tau_best_global/60,'k:');
    xlabel('tau'); ylabel('BIC');
    title('BIC')

    nexttile(2); hold on;
    plot(tauResult.tauGrid/60,tauResult.adjR2(:,m2),'Color',modelColors(m2,:),'LineWidth',2);
    xline(tau_best_global/60,'k:');
    xlabel('tau'); ylabel('adjR2')
    title('adjusted R2')

    nexttile(3); hold on;
    plot(tauResult.tauGrid/60,tauResult.AIC(:,m2),'Color',modelColors(m2,:),'LineWidth',2);
    xline(tau_best_global/60,'k:');
    xlabel('tau'); ylabel('AIC')
    title('AIC')
end
legend(p,fliplr(modelNames),'Box','off')

%% PANEL D - single session model plots
tauResult.trainAgainst= 'sleep';
row_idx=43;
ratStr= Replays.rat(row_idx);
sessStr= Replays.session(row_idx);
plotModelSingleSession(Replays,ratStr,sessStr,tau_best_global,tauResult,modelNames,opts);

%% PANEL E - scatter plots
plotScatterModelAllSessions(Replays,tau_best_global,tauResult,modelNames,opts);

end