function bayesian_decoding_error(varargin)
% INPUTS [ALL OPTIONAL, will run defaults if no inputs]: 
%               input as argument ('name', variable) pairs
%               'method': 'leave one out', 'cross_tracks'

% this code extracts RUN periods (v > 5cm/s) during laps (back and forth) 
% then creates a training and test set for the bayesian decoder
% creates cumulative distribution curves and confusion matrices
parameters= list_of_parameters;

p = inputParser;
addParameter(p,'method','leave one out',@ischar);
addParameter(p,'bin_size',parameters.x_bins_width_bayesian,@ismatrix);
parse(p,varargin{:});
% makes variables a bit shorter to call...
method= p.Results.method;
bin_size= p.Results.bin_size;

switch method
    case 'leave one out'
        disp('running leave one out')
        load('extracted_laps.mat');
        if p.Results.bin_size == parameters.x_bins_width_bayesian
            load('extracted_place_fields_BAYESIAN.mat');
            place_fields= place_fields_BAYESIAN;
            clear place_fields_BAYESIAN;
        elseif p.Results.bin_size == parameters.x_bins_width
            load('extracted_place_fields.mat');
        end
        disp('finding laps...')
        timestep= mean(diff(lap_times(1).lap(1).t));
        for this_track=1:length(lap_times)
            typ= mod(length(lap_times(this_track).lap),2);
            if typ % odd number of laps
                start_idx= 1:2:length(lap_times(this_track).lap)-1;
                stop_idx= 2:2:length(lap_times(this_track).lap)-1;
            else % even number of laps
                start_idx= 1:2:length(lap_times(this_track).lap);
                stop_idx= 2:2:length(lap_times(this_track).lap);
            end
            lap_idx{this_track}= [start_idx' stop_idx'];
            
            % initialise variables
            t_segments_test{this_track}= [];
            test_track_id{this_track}= [];
            test_lap_id{this_track}= [];
            pos1= []; t1= [];
            t_test{this_track}= []; pos_test{this_track}= [];
            
            for this_lap=1:length(start_idx)
                % find RUN periods
                RUN_idx1= lap_times(this_track).lap(start_idx(this_lap)).v_cm > parameters.speed_threshold_laps; % one way
                RUN_idx2= lap_times(this_track).lap(stop_idx(this_lap)).v_cm > parameters.speed_threshold_laps; % return
                % of those find start and stops
                end_gaps1= find(diff(RUN_idx1)== -1);
                start_gaps1= find(diff(RUN_idx1)== 1)+1;
                if ~isempty(end_gaps1) && ~isempty(start_gaps1)
                    if (~isempty(end_gaps1) && isempty(start_gaps1)) || (start_gaps1(1) > end_gaps1(1))
                        start_gaps1= [find(RUN_idx1 == 1,1,'first') start_gaps1];
                    end
                    if start_gaps1(end) > end_gaps1(end)
                        end_gaps1= [end_gaps1 find(RUN_idx1 == 1,1,'last')];
                    end
                    seg1=[]; pos1=[]; t1=[]; k1=1;
                    for this_seg=1:length(start_gaps1)
                        if (start_gaps1(this_seg)+ ceil(parameters.run_bin_width/timestep)) <= end_gaps1(this_seg) % needs to be at least one bin for decoding
                            % keep start:stop
                            seg1= [seg1; start_gaps1(this_seg) end_gaps1(this_seg)]; 
                            % store position and timestamps
                            pos1{k1}= lap_times(this_track).lap(start_idx(this_lap)).x(start_gaps1(this_seg):end_gaps1(this_seg));
                            t1{k1}= lap_times(this_track).lap(start_idx(this_lap)).t(start_gaps1(this_seg):end_gaps1(this_seg));
                            k1= k1+1;
                        end
                    end
                else
                    seg1=[]; pos1=[]; t1=[];
                end
                
                % same for return bit of the lap
                end_gaps2= find(diff(RUN_idx2)== -1);
                start_gaps2= find(diff(RUN_idx2)== 1)+1;
                if ~isempty(end_gaps2) && ~isempty(start_gaps2)
                    if (~isempty(end_gaps2) && isempty(start_gaps2)) || (start_gaps2(1) > end_gaps2(1)) 
                        start_gaps2= [find(RUN_idx2 == 1,1,'first') start_gaps2];
                    end
                    if start_gaps2(end) > end_gaps2(end)
                        end_gaps2= [end_gaps2 find(RUN_idx2 == 1,1,'last')];
                    end
                    seg2=[]; pos2=[]; t2=[]; k2=1;
                    for this_seg=1:length(start_gaps2)
                        if (start_gaps2(this_seg)+ ceil(parameters.run_bin_width/timestep)) <= end_gaps2(this_seg) % needs to be at least one bin for decoding
                            % keep start:stop
                            seg2= [seg2; start_gaps2(this_seg) end_gaps2(this_seg)];
                            % store position and timestamps
                            pos2{k2}= lap_times(this_track).lap(stop_idx(this_lap)).x(start_gaps2(this_seg):end_gaps2(this_seg));
                            t2{k2}= lap_times(this_track).lap(stop_idx(this_lap)).t(start_gaps2(this_seg):end_gaps2(this_seg));
                            k2= k2+1;
                        end
                    end
                else 
                    seg2=[]; pos2=[]; t2=[];
                end
               
                ts1= lap_times(this_track).lap(start_idx(this_lap)).t(seg1);
                ts2= lap_times(this_track).lap(stop_idx(this_lap)).t(seg2);
                t_segments_test{this_track}= [t_segments_test{this_track}; ts1 ; ts2];
                test_track_id{this_track}= [test_track_id{this_track}; this_track*ones(size(ts1,1),1) ;  this_track*ones(size(ts2,1),1)];
                test_lap_id{this_track}= [test_lap_id{this_track}; start_idx(this_lap)*ones(size(ts1,1),1)  ; stop_idx(this_lap)*ones(size(ts2,1),1)];
                t_test{this_track}= [t_test{this_track} t1 t2];
                pos_test{this_track}= [pos_test{this_track} pos1 pos2];

            end
        end
        
        % calculate place_fields for training set (and test set)
        disp('calculating lap place fields..')
        for this_track=1:length(lap_times)
            this_track
            for this_lap=1:length(lap_idx{this_track})
                % this_lap
                test_indices= test_lap_id{this_track}== lap_idx{this_track}(this_lap,1) | test_lap_id{this_track}== lap_idx{this_track}(this_lap,2);
                lap_test= cell(1,length(lap_times));
                laps_training= lap_test;
                lap_test{this_track}= t_segments_test{this_track}(test_indices,:);
                laps_training{this_track}= t_segments_test{this_track}(~test_indices,:);

                place_fields_test= calculate_place_fields_epochs(bin_size,lap_test);
                place_fields_test.track= place_fields_test.track(this_track);
                place_fields_training= calculate_place_fields_epochs(bin_size,laps_training);
                place_fields_training.track(this_track)= place_fields_training.track(this_track);
                %
                remaining_idx= [1:length(place_fields.track)]; 
                remaining_idx(this_track)= [];
                fnames= fieldnames(place_fields_training.track);
                fnames(strcmp(fnames,'field_boundaries'))=[];
                for ii=1:length(remaining_idx)
                    place_fields.track(remaining_idx(ii)).total_time= diff(place_fields.track(remaining_idx(ii)).time_window);
                    for jj=1:length(fnames)
                        place_fields_training.track(remaining_idx(ii)).(fnames{jj})= place_fields.track(remaining_idx(ii)).(fnames{jj});
                    end
                end
                
                if ~isfield(place_fields_training.track,'x_bin_edges')
                    keyboard;
                end
                 % spike count
                bayesian_spike_count_test= spike_count([],t_segments_test{this_track}(test_indices,1)',t_segments_test{this_track}(test_indices,2)','N','laps');
              
                % decoding
                est_temp = bayesian_decoding(place_fields_training,bayesian_spike_count_test,'N');
                
                % find position on track
                pos= [pos_test{this_track}{test_indices}];
                t= [t_test{this_track}{test_indices}];

                % discretise to the position bins used in the decoding
                discrete_position = NaN(size(pos));
                discrete_position = discretize(pos,place_fields_test.track.x_bin_edges); %group position points in bins delimited by edges
                index = find(~isnan(discrete_position));
                discrete_position(index) = est_temp(this_track).position_bin_centres(discrete_position(index)); %creates new positions based on centre of bins
                interp_discrete_pos= interp1(t,discrete_position, [bayesian_spike_count_test.run_epochs.run_time_centered], 'nearest');
                interp_pos= interp1(t,pos, [bayesian_spike_count_test.run_epochs.run_time_centered], 'nearest');

                % calculate error
                estimated_position_test(this_track).run_epochs(this_lap).run_time_edges(1,:)= [est_temp(this_track).run_epochs.run_time_edges];
                estimated_position_test(this_track).run_epochs(this_lap).run_time_centered(1,:)= [est_temp(this_track).run_epochs.run_time_centered];
                estimated_position_test(this_track).run_epochs(this_lap).run{1,1}= [est_temp(this_track).run_epochs.run];
                estimated_position_test(this_track).run_epochs(this_lap).peak_position(1,:)= [est_temp(this_track).run_epochs.peak_position];
                estimated_position_test(this_track).run_epochs(this_lap).run_bias(1,:)= [est_temp(this_track).run_epochs.run_bias];
                estimated_position_test(this_track).run_epochs(this_lap).max_prob(1,:)= [est_temp(this_track).run_epochs.max_prob];
                estimated_position_test(this_track).run_epochs(this_lap).discrete_run_error(1,:)= abs([est_temp(this_track).run_epochs.peak_position]-interp_discrete_pos);
                estimated_position_test(this_track).run_epochs(this_lap).run_error(1,:)= abs([est_temp(this_track).run_epochs.peak_position]-interp_pos);
                estimated_position_test(this_track).run_epochs(this_lap).pos_interp(1,:)= interp_pos;
                estimated_position_test(this_track).run_epochs(this_lap).discrete_pos_interp(1,:)= interp_discrete_pos;

            end
            
            estimated_position_test(this_track).position_bin_centres= est_temp.position_bin_centres;
            estimated_position_test(this_track).error_thresh = parameters.x_bins_width_bayesian; % 10cm - 1 bin
            decodedPos= [estimated_position_test(this_track).run_epochs.peak_position];
            realPos= [estimated_position_test(this_track).run_epochs.discrete_pos_interp];
            estimated_position_test(this_track).percent_small_error= 100*sum(abs(decodedPos-realPos)<=2*parameters.x_bins_width_bayesian)/numel(realPos); % current or next bin
            estimated_position_test(this_track).median_error= median(abs(decodedPos-realPos),"all","omitmissing");

        end
        
       switch bin_size
           case parameters.x_bins_width_bayesian
                save('estimated_position_leave_one_out.mat','estimated_position_test');  
           case parameters.x_bins_width
                save('estimated_position_leave_one_out_SMALL.mat','estimated_position_test');  
           otherwise
                save(['estimated_position_leave_one_out_' num2str(bin_size) 'cm.mat'],'estimated_position_test');  
       end  
end
end
