function tauResult = runGlobalTauScan(Replays,tauGrid,trainAgainst)

numModels=6;
if trainAgainst == "sleep"
    sleepRate= Replays.sleepPOSTrate(:); % events/s
end

sessKey= strcat(string(Replays.rat),"_",string(Replays.session));
nTau= numel(tauGrid);

adjR2= nan(nTau,numModels);
AIC= nan(nTau,numModels);
BIC= nan(nTau,numModels);
modelFits= cell(nTau,numModels);
S_all= cell(nTau,numModels);
S_all_Sleep= cell(nTau,numModels);

parfor it=1:nTau % speed up
    tau= tauGrid(it);

    strength_sleep= computeStrengthAtSleep_AllModels(Replays, tau, "sleep");
    % could be better organised..
    S_all_Sleep{it} = [strength_sleep.S1, strength_sleep.S2, strength_sleep.S3, strength_sleep.S4, strength_sleep.S5, strength_sleep.S6];

    if trainAgainst == "sleep"
        S_all{it}= S_all_Sleep{it};
    end
    
    for m= 1:numModels

        S= S_all{it}(:,m);
        if sum(S) > 0 
   
            T= table(S,sleepRate,categorical(Replays.rat),categorical(Replays.session),'VariableNames',{'Strength','SleepRate','rat','session'});

            formulaT= 'SleepRate ~ Strength + (session|rat)';
            mdl= fitlme(T,formulaT);
    
            adjR2(it,m)= mdl.Rsquared.Adjusted;
            AIC(it,m)= mdl.ModelCriterion.AIC;
            BIC(it,m)= mdl.ModelCriterion.BIC;
    
            modelFits(it,m)= {mdl};
        end
    end
end

modelsToUse= 1:3; % other models (controls) are weird to use for estimation
% Combine across models
totalBIC = sum(BIC(:,modelsToUse), 2, 'omitnan');     % smaller is better
totalAIC = sum(AIC(:,modelsToUse), 2, 'omitnan');

% Choose global tau -> min BIC
[~, idxBestBIC] = min(totalBIC);

tauResult.tauGrid= tauGrid;
tauResult.trainAgainst= trainAgainst;
tauResult.adjR2= adjR2;
tauResult.AIC= AIC;
tauResult.BIC= BIC;
tauResult.totalBIC= totalBIC;
tauResult.totalAIC= totalAIC;

% predicted can be rederived from mdl fits
tauResult.models= modelFits;
tauResult.Strengths= S_all_Sleep;

tauResult.tau_best_byTotalBIC = tauGrid(idxBestBIC);

end