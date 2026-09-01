function plotModelSingleSession(Replays,ratStr,sessStr,tauSeconds,tauResult,modelNames,opts)

% find session in Replays
sessKey= strcat(string(Replays.rat),"_",string(Replays.session));
ratKey= strcat(string(ratStr),"_",string(sessStr));
rows= find(sessKey == ratKey);

if isempty(rows)
    error('No data found for rat %s session %s', string(ratStr), string(sessStr));
end

sleepRate= Replays.sleepPOSTrate(:);
% retrieve strengths and models from tauResult
SGlobal= tauResult.Strengths{tauResult.tauGrid==tauSeconds};
models= tauResult.models(tauResult.tauGrid==tauSeconds,:);
numModels= length(models);

predSleepSess= nan(numel(rows),3);
for m= 1:numModels
    if ~isempty(tauResult.models{tauResult.tauGrid==tauSeconds,m})
        T= table(SGlobal(:,m),sleepRate,categorical(Replays.rat),categorical(Replays.session),'VariableNames',{'Strength','SleepRate','rat','session'});     
        predAll= predict(models{m},T);
        predSleepSess(:,m)= predAll(rows);
    end
end

for i= 1:numel(rows) % retrieve data
    rowIdx= rows(i);
    thisTrack= Replays.track(rowIdx);

    [timeAxis, dt, ~, localCounts, subsequentTrackCounts, subsequentAllCounts, sleepPriorCounts, restCounts, sleepStartClock]= getCountsForRow(Replays, rowIdx, tauResult.trainAgainst);

    % Observed content rate over the session: local + all subsequent (events/s)
    observedCounts= localCounts + subsequentAllCounts;
    observedRate= observedCounts / dt;

    % Predicted strength traces
    [~, trace1]= strengthFromCounts(localCounts,dt,tauSeconds);
    [~, trace2]= strengthFromCounts(localCounts + subsequentTrackCounts,dt,tauSeconds);
    [~, trace3]= strengthFromCounts(localCounts + subsequentAllCounts,dt,tauSeconds);
    [~, trace4]= strengthFromCounts(localCounts,dt,inf); % inf = no decay
    [~, trace5]= strengthFromCounts(sleepPriorCounts,dt,tauSeconds);
    [~, trace6]= strengthFromCounts(restCounts,dt,tauSeconds);

    predRate1= trace1/dt;
    predRate2= trace2/dt;
    predRate3= trace3/dt;
    predRate4= trace4/dt;
    predRate5= trace5/dt;
    predRate6= trace6/dt;

    predRates{1}(:,i)= predRate1;
    predRates{2}(:,i)= predRate2;
    predRates{3}(:,i)= predRate3;
    predRates{4}(:,i)= predRate4;
    predRates{5}(:,i)= predRate5;
    predRates{6}(:,i)= predRate6;

    ySleep(i)= Replays.sleepPOSTrate(rowIdx);

    xMin= timeAxis/dt; 
    sessStart= min(xMin);
    xMin= xMin - sessStart;
    xMinAll= Replays.binCtrs{rowIdx}/dt - sessStart;

end

for m= 1:numModels
    nexttile; hold on;
    p=[];
    for i=1:3
        p(i)= plot(xMin,predRates{m}(:,i),'-','LineWidth',1.5,'Color',opts.cdata_rec{i}); 
    end
    ylim([0 1.5])

    yyaxis right
    for i=1:3
        plot(sleepStartClock/60 - sessStart+[0 15], [ySleep(i) ySleep(i)],'Color',opts.cdata_rec{i},'lineStyle','-','LineWidth', 2); % add observed sleep
    end
    ylim([0 0.07])
    xlim([xMin(find(Replays.binCtrs{rows(i)} >= Replays.trackTs{rows(i)}(1,1),1,'first')) sleepStartClock/60 - sessStart + 15])

    xlabel('Time (min)');
    ylabel('Events/s');
    title(modelNames{m});

    if i == 1
        legend(p,{'T1','T2','T3'}, 'Location','best','AutoUpdate',0);
    end

    % Tracks start/stop
    xline(Replays.trackTs{rowIdx}(:)/60 -sessStart,'k:','LineWidth',1);
    % Sleep start 
    xline(sleepStartClock/60-sessStart,'k--','LineWidth',1.5);

end
end


function [timeAxis, dt, binEdges, localCounts, subsequentTrackCounts, subsequentAllCounts, sleepPriorCounts, restCounts, sleepStartClock] = ...
            getCountsForRow(Replays, rowIdx,trainAgainst)

sleepBouts = Replays.SleepTs{rowIdx};         
if trainAgainst == "sleep"
    sleepStartClock = sleepBouts(1,1);         
end

timeAxis= Replays.binCtrs{rowIdx}';   
dt= Replays.dt(rowIdx); 
binEdges= [timeAxis(1)-dt/2; timeAxis+dt/2];

binEdges(binEdges>sleepStartClock)=[];
timeAxis(timeAxis>binEdges(end))=[];

% local events
localEventTimes= Replays.localOnlineEvents{rowIdx};
localCounts= histcounts(localEventTimes, binEdges)';

% subsequent tracks only
trackOnlyTimes= Replays.subsequentEvents{rowIdx}(ismember(Replays.subsequentEvents_ID{rowIdx},1:3))';
subsequentTrackCounts= histcounts(trackOnlyTimes,binEdges)';

% all subsequent events: tracks + rests
subsequentAllCounts = histcounts(Replays.subsequentEvents{rowIdx}, binEdges)';

% rest 3 
sleepPriorCounts= histcounts(Replays.subsequentEvents{rowIdx}(Replays.subsequentEvents{rowIdx} > Replays.trackTs{rowIdx}(3,2)),binEdges)';

% offline only - all rests
subsequentEventTimes= Replays.subsequentEvents{rowIdx};
restEvents= subsequentEventTimes((subsequentEventTimes >= Replays.restTs{rowIdx}(1,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(1,2)) | ...
            (subsequentEventTimes >= Replays.restTs{rowIdx}(2,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(2,2)) | ...
            (subsequentEventTimes >= Replays.restTs{rowIdx}(3,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(3,2)));
restCounts= histcounts(restEvents, binEdges)';

end


function [strengthAtSleep,strengthTrace] = strengthFromCounts(countVector,dtAxis,tauSeconds)

    if isinf(tauSeconds) % all events, no decay
        strengthTrace= cumsum(countVector(:));
    else
        alpha= exp(-dtAxis/tauSeconds);
        strengthTrace= filter(1, [1 -alpha],countVector(:));  
    end
    strengthAtSleep= strengthTrace(end);
end