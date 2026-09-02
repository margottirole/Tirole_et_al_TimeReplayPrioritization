function decodingErrors= getDecodingErrorsLaps(folders)

data_folder= pwd; % need it because of bayesian decoding code
load('reward_conditions.mat');
parameters= list_of_parameters;
decodingErrors= table;
DEC_K=1;
nShuff=1;

delimPosTracks= [1:20; 21:40; 41:60];

for this_folder=1:length(folders)

    cd(fullfile(data_folder,folders{this_folder}));
    disp(this_folder)

    % load bayesian decoding, laps and speed
    load(fullfile(folders{this_folder},'estimated_position.mat'));
    load(fullfile(folders{this_folder},'extracted_laps.mat'));
    load(fullfile(folders{this_folder},'extracted_position.mat'));
    load(fullfile(folders{this_folder},'extracted_place_fields_BAYESIAN.mat'));
    load(fullfile(folders{this_folder},'bayesian_spike_count.mat'));

    n= bayesian_spike_count.n.run;

    curr_sess= strsplit(folders{this_folder},'\');
    curr_rat= curr_sess(1);  curr_sess= curr_sess(2);
    sess_idx= contains(reward_condition.session,curr_sess);

    for thisTrack=1:length(estimated_position)

        t_binsDecoding= estimated_position(thisTrack).run_time_centered;
        posterior= vertcat(estimated_position(:).run); % sums to 1
        pos_bins_edges= 0:mean(diff(estimated_position(thisTrack).position_bin_centres)):max(estimated_position(thisTrack).position_bin_centres)+mean(diff(estimated_position(thisTrack).position_bin_centres));
        discrete_pos= discretize(position.linear(thisTrack).linear,pos_bins_edges);
        realPos= interp1(position.t,discrete_pos,t_binsDecoding,'nearest'); % 1 to 20
        speedDecoding= interp1(position.t,position.v_cm,t_binsDecoding);

        numLaps= floor(lap_times(thisTrack).total_number_of_laps/2);
        maxLaps= 10;
             
        % initialise vars
        percentDecodeLocal= NaN(1,2*maxLaps);percentDecodeRemoteN1= NaN(1,2*maxLaps); percentDecodeRemoteN2= NaN(1,2*maxLaps);
        percentDecodeFutureN1= NaN(1,2*maxLaps); percentDecodeFutureN2= NaN(1,2*maxLaps);
        meanProbLocal= NaN(1,2*maxLaps); meanDistLocal= NaN(1,2*maxLaps); meanProbRemoteN1= NaN(1,2*maxLaps);
        meanProbRemoteN2= NaN(1,2*maxLaps); meanProbFutureN1= NaN(1,2*maxLaps); meanProbFutureN2= NaN(1,2*maxLaps);
        meanBiasLocal= NaN(1,2*maxLaps); meanBiasRemoteN1= NaN(1,2*maxLaps); meanBiasRemoteN2= NaN(1,2*maxLaps);
        meanBiasFutureN1= NaN(1,2*maxLaps); meanBiasFutureN2= NaN(1,2*maxLaps);
        meanBiasLocalAllBins= NaN(1,2*maxLaps); meanBiasRemoteN1AllBins= NaN(1,2*maxLaps); meanBiasRemoteN2AllBins= NaN(1,2*maxLaps);
        meanBiasFutureN1AllBins= NaN(1,2*maxLaps); meanBiasFutureN2AllBins= NaN(1,2*maxLaps);

        for thisLap=1:1:2*maxLaps % half laps
            currLap= floor(thisLap/2)+1;
            % find time bins during lap, where v>5cm/s
            if (thisLap)<=2*numLaps
            t_Lap= [lap_times(thisTrack).start(thisLap) lap_times(thisTrack).end(thisLap)];
            keepIdx= speedDecoding >= parameters.speed_threshold_laps & ...
                (t_binsDecoding >= t_Lap(1) & t_binsDecoding <= t_Lap(2));

            % for each bin, figure out where the MAP is: which track (and position)
            % first track is 1-20, track 2: 21-40, track 3: 41-60
            [maxProb,maxProb_pos]= max(posterior(:,keepIdx),[],1);

            % also get replay bias current track/rest
            otherTrackBins= delimPosTracks;
            otherTrackBins(ismember(otherTrackBins,delimPosTracks(thisTrack,:)))=[];
            decodBias= sum(posterior(delimPosTracks(thisTrack,:),keepIdx));

            realPosLap= realPos(keepIdx);
            currTrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack,:));
            percentDecodeLocal(currLap)= sum(currTrackBins)/numel(maxProb_pos);
            meanProbLocal(currLap)= mean(maxProb(currTrackBins));
            meanBiasLocalAllBins(currLap)= mean(decodBias);
            meanBiasLocal(currLap)= mean(decodBias(currTrackBins));
            meanDistLocal(currLap)=  mean(abs(maxProb_pos(currTrackBins) - (20*(thisTrack-1)+realPosLap(currTrackBins))));
            if thisTrack > 1
                remoteN1TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack-1,:));
                percentDecodeRemoteN1(currLap)= sum(remoteN1TrackBins)/numel(maxProb_pos);
                meanProbRemoteN1(currLap)= mean(maxProb(remoteN1TrackBins));
                decodBiasTmp= sum(posterior(delimPosTracks(thisTrack-1,:),keepIdx));
                meanBiasRemoteN1AllBins(currLap)= mean(decodBiasTmp);
                meanBiasRemoteN1(currLap)= mean(decodBiasTmp(remoteN1TrackBins));
            end
            if thisTrack > 2
                remoteN2TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack-2,:));
                percentDecodeRemoteN2(currLap)= sum(remoteN2TrackBins)/numel(maxProb_pos);
                meanProbRemoteN2(currLap)= mean(maxProb(remoteN2TrackBins));
                decodBiasTmp= sum(posterior(delimPosTracks(thisTrack-2,:),keepIdx));
                meanBiasRemoteN2AllBins(currLap)= mean(decodBiasTmp);
                meanBiasRemoteN2(currLap)= mean(decodBiasTmp(remoteN2TrackBins));
            end
            if thisTrack < 3
                futureN1TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack+1,:));
                percentDecodeFutureN1(currLap)= sum(futureN1TrackBins)/numel(maxProb_pos);
                meanProbFutureN1(currLap)= mean(maxProb(futureN1TrackBins));
                decodBiasTmp= sum(posterior(delimPosTracks(thisTrack+1,:),keepIdx));
                meanBiasFutureN1AllBins(currLap)= mean(decodBiasTmp);
                meanBiasFutureN1(currLap)= mean(decodBiasTmp(futureN1TrackBins));
            end
            if thisTrack < 2
                futureN2TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack+2,:));
                percentDecodeFutureN2(currLap)= sum(futureN2TrackBins)/numel(maxProb_pos);
                meanProbFutureN2(currLap)= mean(maxProb(futureN2TrackBins));
                decodBiasTmp= sum(posterior(delimPosTracks(thisTrack+2,:),keepIdx));
                meanBiasFutureN2AllBins(currLap)= mean(decodBiasTmp);
                meanBiasFutureN2(currLap)= mean(decodBiasTmp(futureN2TrackBins));
            end  
            end
        end

        %
        decodingErrors.rat(DEC_K)= curr_rat;
        decodingErrors.session(DEC_K)= curr_sess;
        decodingErrors.track(DEC_K)= thisTrack;
        reward= reward_condition.(['track' num2str(thisTrack)]){sess_idx};
        if strcmp(reward,'chocolate')
            decodingErrors.reward(DEC_K)= "HIGH";
        elseif strcmp(reward,'diluted')
            decodingErrors.reward(DEC_K)= "LOW";
        end
        decodingErrors.percentDecodeLocal{DEC_K}= percentDecodeLocal;
        decodingErrors.meanProbLocal{DEC_K}= meanProbLocal;
        decodingErrors.meanBiasLocalAllBins{DEC_K}= meanBiasLocalAllBins;
        decodingErrors.meanBiasLocal{DEC_K}= meanBiasLocal;
        decodingErrors.meanDistLocal{DEC_K}= meanDistLocal;

        decodingErrors.percentDecodeRemoteN1{DEC_K}= percentDecodeRemoteN1;
        decodingErrors.meanProbRemoteN1{DEC_K}= meanProbRemoteN1;
        decodingErrors.meanBiasRemoteN1AllBins{DEC_K}= meanBiasRemoteN1AllBins;
        decodingErrors.meanBiasRemoteN1{DEC_K}= meanBiasRemoteN1;
        decodingErrors.percentDecodeRemoteN2{DEC_K}= percentDecodeRemoteN2;
        decodingErrors.meanProbRemoteN2{DEC_K}= meanProbRemoteN2;
        decodingErrors.meanBiasRemoteN2AllBins{DEC_K}= meanBiasRemoteN2AllBins;
        decodingErrors.meanBiasRemoteN2{DEC_K}= meanBiasRemoteN2;

        decodingErrors.percentDecodeFutureN1{DEC_K}= percentDecodeFutureN1;
        decodingErrors.meanProbFutureN1{DEC_K}= meanProbFutureN1;
        decodingErrors.meanBiasFutureN1AllBins{DEC_K}= meanBiasFutureN1AllBins;
        decodingErrors.meanBiasFutureN1{DEC_K}= meanBiasFutureN1;
        decodingErrors.percentDecodeFutureN2{DEC_K}= percentDecodeFutureN2;
        decodingErrors.meanProbFutureN2{DEC_K}= meanProbFutureN2;
        decodingErrors.meanBiasFutureN2AllBins{DEC_K}= meanBiasFutureN2AllBins;
        decodingErrors.meanBiasFutureN2{DEC_K}= meanBiasFutureN2;

        %%%%% CELL ID SHUFFLE %%%%%
        % initialise vars
        percentDecodeLocal= NaN(nShuff,2*maxLaps);percentDecodeRemoteN1= NaN(nShuff,2*maxLaps); percentDecodeRemoteN2= NaN(nShuff,2*maxLaps);
        percentDecodeFutureN1= NaN(nShuff,2*maxLaps); percentDecodeFutureN2= NaN(nShuff,2*maxLaps);
        meanProbLocal= NaN(nShuff,2*maxLaps); meanDistLocal= NaN(nShuff,2*maxLaps); meanProbRemoteN1= NaN(nShuff,2*maxLaps);
        meanProbRemoteN2= NaN(nShuff,2*maxLaps); meanProbFutureN1= NaN(nShuff,2*maxLaps); meanProbFutureN2= NaN(nShuff,2*maxLaps);
        meanBiasLocal= NaN(nShuff,2*maxLaps); meanBiasRemoteN1= NaN(nShuff,2*maxLaps); meanBiasRemoteN2= NaN(nShuff,2*maxLaps);
        meanBiasFutureN1= NaN(nShuff,2*maxLaps); meanBiasFutureN2= NaN(nShuff,2*maxLaps);
        meanBiasLocalAllBins= NaN(nShuff,2*maxLaps); meanBiasRemoteN1AllBins= NaN(nShuff,2*maxLaps); meanBiasRemoteN2AllBins= NaN(nShuff,2*maxLaps);
        meanBiasFutureN1AllBins= NaN(nShuff,2*maxLaps); meanBiasFutureN2AllBins= NaN(nShuff,2*maxLaps);

        place_field_index= place_fields_BAYESIAN.good_place_cells; 
        for thisShuff=1:nShuff
            % shuffle cell ids within other two tracks
            allTracks=1:3;
            place_fields_Shuff= place_fields_BAYESIAN;
            otherTracks= find(~ismember(allTracks,thisTrack));
            for thatTrack=1:length(otherTracks)
                shuffIdx= randsample(place_field_index,length(place_field_index),0);
                place_fields_Shuff.track(otherTracks(thatTrack)).raw(place_field_index) = place_fields_Shuff.track(otherTracks(thatTrack)).raw(shuffIdx);
            end
            estimated_positionShuff=[];
            for thisT=1:3
                all_place_fields= vertcat(place_fields_Shuff.track(thisT).raw{place_field_index});
                estimated_positionShuff= [estimated_positionShuff; reconstructFast(n,all_place_fields,parameters.run_bin_width)];
            end
            posteriorShuff = estimated_positionShuff./sum(estimated_positionShuff,1);

            for thisLap= 1:1:2*maxLaps 
                currLap= floor(thisLap/2)+1;
                if (thisLap+1)<=2*numLaps
                % find time bins during lap, where v>5cm/s
                t_Lap= [lap_times(thisTrack).start(thisLap) lap_times(thisTrack).end(thisLap)];
                keepIdx= speedDecoding >= parameters.speed_threshold_laps & ...
                    (t_binsDecoding >= t_Lap(1) & t_binsDecoding <= t_Lap(2));
    
                % for each bin, figure out where the MAP is: which track (and position)
                % first track is 1-20, track 2: 21-40, track 3: 41-60
                [maxProb,maxProb_pos]= max(posteriorShuff(:,keepIdx),[],1);
    
                % also get replay bias current track/rest
                otherTrackBins= delimPosTracks;
                otherTrackBins(ismember(otherTrackBins,delimPosTracks(thisTrack,:)))=[];
                decodBias= sum(posteriorShuff(delimPosTracks(thisTrack,:),keepIdx));

                realPosLap= realPos(keepIdx);
    
                currTrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack,:));
                percentDecodeLocal(thisShuff,currLap)= sum(currTrackBins)/numel(maxProb_pos);
                meanProbLocal(thisShuff,currLap)= mean(maxProb(currTrackBins));
                meanBiasLocalAllBins(thisShuff,currLap)= mean(decodBias);
                meanBiasLocal(thisShuff,currLap)= mean(decodBias(currTrackBins));
                meanDistLocal(thisShuff,currLap)=  mean(abs(maxProb_pos(currTrackBins) - (20*(thisTrack-1)+realPosLap(currTrackBins))));
                if thisTrack > 1
                    remoteN1TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack-1,:));
                    percentDecodeRemoteN1(thisShuff,currLap)= sum(remoteN1TrackBins)/numel(maxProb_pos);
                    meanProbRemoteN1(thisShuff,currLap)= mean(maxProb(remoteN1TrackBins));
                    decodBiasTmp= sum(posteriorShuff(delimPosTracks(thisTrack-1,:),keepIdx));
                    meanBiasRemoteN1AllBins(thisShuff,currLap)= mean(decodBiasTmp);
                    meanBiasRemoteN1(thisShuff,currLap)= mean(decodBiasTmp(remoteN1TrackBins));
                end
                if thisTrack > 2
                    remoteN2TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack-2,:));
                    percentDecodeRemoteN2(thisShuff,currLap)= sum(remoteN2TrackBins)/numel(maxProb_pos);
                    meanProbRemoteN2(thisShuff,currLap)= mean(maxProb(remoteN2TrackBins));
                    decodBiasTmp= sum(posteriorShuff(delimPosTracks(thisTrack-2,:),keepIdx));
                    meanBiasRemoteN2AllBins(thisShuff,currLap)= mean(decodBiasTmp);
                    meanBiasRemoteN2(thisShuff,currLap)= mean(decodBiasTmp(remoteN2TrackBins));
                end
                if thisTrack < 3
                    futureN1TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack+1,:));
                    percentDecodeFutureN1(thisShuff,currLap)= sum(futureN1TrackBins)/numel(maxProb_pos);
                    meanProbFutureN1(thisShuff,currLap)= mean(maxProb(futureN1TrackBins));
                    decodBiasTmp= sum(posteriorShuff(delimPosTracks(thisTrack+1,:),keepIdx));
                    meanBiasFutureN1AllBins(thisShuff,currLap)= mean(decodBiasTmp);
                    meanBiasFutureN1(thisShuff,currLap)= mean(decodBiasTmp(futureN1TrackBins));
                end
                if thisTrack < 2
                    futureN2TrackBins= ismember(maxProb_pos,delimPosTracks(thisTrack+2,:));
                    percentDecodeFutureN2(thisShuff,currLap)= sum(futureN2TrackBins)/numel(maxProb_pos);
                    meanProbFutureN2(thisShuff,currLap)= mean(maxProb(futureN2TrackBins));
                    decodBiasTmp= sum(posteriorShuff(delimPosTracks(thisTrack+2,:),keepIdx));
                    meanBiasFutureN2AllBins(thisShuff,currLap)= mean(decodBiasTmp);
                    meanBiasFutureN2(thisShuff,currLap)= mean(decodBiasTmp(futureN2TrackBins));
                end  
                end
            end
        end
        decodingErrors.percentDecodeLocal_Shuff{DEC_K}= percentDecodeLocal;
        decodingErrors.meanProbLocal_Shuff{DEC_K}= meanProbLocal;
        decodingErrors.meanBiasLocalAllBins_Shuff{DEC_K}= meanBiasLocalAllBins;
        decodingErrors.meanBiasLocal_Shuff{DEC_K}= meanBiasLocal;
        decodingErrors.meanDistLocal_Shuff{DEC_K}= meanDistLocal;

        decodingErrors.percentDecodeRemoteN1_Shuff{DEC_K}= percentDecodeRemoteN1;
        decodingErrors.meanProbRemoteN1_Shuff{DEC_K}= meanProbRemoteN1;
        decodingErrors.meanBiasRemoteN1AllBins_Shuff{DEC_K}= meanBiasRemoteN1AllBins;
        decodingErrors.meanBiasRemoteN1_Shuff{DEC_K}= meanBiasRemoteN1;
        decodingErrors.percentDecodeRemoteN2_Shuff{DEC_K}= percentDecodeRemoteN2;
        decodingErrors.meanProbRemoteN2_Shuff{DEC_K}= meanProbRemoteN2;
        decodingErrors.meanBiasRemoteN2AllBins_Shuff{DEC_K}= meanBiasRemoteN2AllBins;
        decodingErrors.meanBiasRemoteN2_Shuff{DEC_K}= meanBiasRemoteN2;

        decodingErrors.percentDecodeFutureN1_Shuff{DEC_K}= percentDecodeFutureN1;
        decodingErrors.meanProbFutureN1_Shuff{DEC_K}= meanProbFutureN1;
        decodingErrors.meanBiasFutureN1AllBins_Shuff{DEC_K}= meanBiasFutureN1AllBins;
        decodingErrors.meanBiasFutureN1_Shuff{DEC_K}= meanBiasFutureN1;
        decodingErrors.percentDecodeFutureN2_Shuff{DEC_K}= percentDecodeFutureN2;
        decodingErrors.meanProbFutureN2_Shuff{DEC_K}= meanProbFutureN2;
        decodingErrors.meanBiasFutureN2AllBins_Shuff{DEC_K}= meanBiasFutureN2AllBins;
        decodingErrors.meanBiasFutureN2_Shuff{DEC_K}= meanBiasFutureN2;

        DEC_K= DEC_K+1;
    end

    cd(data_folder)
end

save(fullfile(opts.dataFolder,'NEW_TABLES','DECODING_ERRORS_LAPS.mat'),'decodingErrors');

end