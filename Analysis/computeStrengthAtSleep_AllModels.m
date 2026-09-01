function strength = computeStrengthAtSleep_AllModels(Replays,tauSeconds,trainAgainst)
% strength is a struct with S1,S2,S3...S[num models] vectors of replay
% strengths computed just prior to sleep

nRows= height(Replays);
S_localOnly= nan(nRows,1);
S_localPlusTracks= nan(nRows,1);
S_allEvents= nan(nRows,1);
S_increaseOnly= nan(nRows,1);
S_priorSleep= nan(nRows,1);
S_offline= nan(nRows,1);

for rowIdx= 1:nRows
    sleepBouts = Replays.SleepTs{rowIdx};
    if isempty(sleepBouts) || size(sleepBouts,2) < 2
        continue
    end
    if trainAgainst == "sleep"
        sleepStartClock = sleepBouts(1,1);
    end

    binCenters= Replays.binCtrs{rowIdx}(:); 
    dt= Replays.dt(rowIdx);

    % Build edges for histcounts based on bin centers
    binEdgesClock = [binCenters(1)-dt/2; binCenters + dt/2];
    binEdgesClock(binEdgesClock>sleepStartClock)=[];
    binCenters(binCenters>binEdgesClock(end))=[];

    localEventTimes= Replays.localOnlineEvents{rowIdx}(:);
    localEventTimes= localEventTimes(localEventTimes < sleepStartClock);

    subsequentEventTimes= Replays.subsequentEvents{rowIdx}(:);
    subsequentEventIDs= Replays.subsequentEvents_ID{rowIdx}(:);

    % only events on tracks (IDs 1-3)
    subsequentTrackEventTimes= subsequentEventTimes(ismember(subsequentEventIDs, 1:3));
    subsequentTrackEventTimes= subsequentTrackEventTimes(subsequentTrackEventTimes < sleepStartClock);

    % all subsequent events (tracks + rests)
    subsequentAllEventTimes= subsequentEventTimes(subsequentEventTimes < sleepStartClock);

    % offline only - rests 1-3
    restEvents= subsequentEventTimes((subsequentEventTimes >= Replays.restTs{rowIdx}(1,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(1,2)) | ...
        (subsequentEventTimes >= Replays.restTs{rowIdx}(2,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(2,2)) | ...
        (subsequentEventTimes >= Replays.restTs{rowIdx}(3,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(3,2)));

    % control - only rest3
    priorToSleepEventTimes= subsequentEventTimes((subsequentEventTimes >= Replays.restTs{rowIdx}(3,1) & subsequentEventTimes <= Replays.restTs{rowIdx}(3,2))...
                            & subsequentEventTimes < sleepStartClock);

    % counts per bin
    localCounts= histcounts(localEventTimes, binEdgesClock);
    trackCounts= histcounts(subsequentTrackEventTimes, binEdgesClock);
    allCounts= histcounts(subsequentAllEventTimes, binEdgesClock);
    priorSleep= histcounts(priorToSleepEventTimes, binEdgesClock);
    offlineCounts= histcounts(restEvents, binEdgesClock);

    % weights for decay to sleep start
    decayWeights = exp(-(sleepStartClock - binCenters)/tauSeconds);
    decayWeights(binCenters > sleepStartClock) = 0;

    % strengths at sleep
    S_localOnly(rowIdx)       = sum(localCounts' .* decayWeights);
    S_localPlusTracks(rowIdx) = sum((localCounts' + trackCounts') .* decayWeights);
    S_allEvents(rowIdx)       = sum((localCounts' + allCounts') .* decayWeights);
    S_priorSleep(rowIdx)      = sum(priorSleep' .* decayWeights);
    S_increaseOnly(rowIdx)    = sum(localCounts');
    S_offline(rowIdx)         = sum(offlineCounts' .* decayWeights);

    strength.S1= S_localOnly;
    strength.S2= S_localPlusTracks;
    strength.S3= S_allEvents;
    strength.S4= S_increaseOnly;
    strength.S5= S_priorSleep;
    strength.S6= S_offline;
end