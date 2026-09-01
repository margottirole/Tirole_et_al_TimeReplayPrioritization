function plotScatterModelAllSessions(Replays,tauSeconds,tauResult,modelNames,opts)

sleepRate= Replays.sleepPOSTrate(:);
% retrieve strengths and models from tauResult
if tauResult.trainAgainst == "sleep"
    S= tauResult.Strengths{tauResult.tauGrid==tauSeconds};
end
models= tauResult.models(tauResult.tauGrid==tauSeconds,:);

numModels= length(models);
for m= 1:numModels
    nexttile; hold on;
    if ~isempty(tauResult.models{1,m})
        T= table(S(:,m),sleepRate,categorical(Replays.rat),categorical(Replays.session),'VariableNames',{'Strength','SleepRate','rat','session'});     
        predAll= predict(models{m},T);
    
        for i=1:3
            Tidx= Replays.track == i;
            scatter(predAll(Tidx), sleepRate(Tidx), 18, opts.cdata_rec{i}, 'filled', 'MarkerFaceAlpha', 0.7);
        end
        lims= [min([sleepRate predAll]) max([sleepRate predAll])];
        plot(lims,lims,'k:');

        RMSE= sqrt(mean((sleepRate - predAll).^2));
        ylabel('Observed sleep replay rate (events/s)');
        xlabel('Predicted sleep replay rate (events/s)');
        title({modelNames{m} ; ['R^2= ' num2str(models{m}.Rsquared.Adjusted,2) ', RMSE= ' num2str(RMSE,3)] ;['BIC= ' num2str(models{m}.ModelCriterion.BIC,1)]});

    end
end

end