function sleepStager(varargin)
% Detects Wake / Quiet / NREM / REM when animal is in the rest pot  
% output: extracted_sleep_state_REM_NREM.mat
load('extracted_position.mat');
load('extracted_CSC.mat');
load('extracted_clusters.mat');

lfp_t_OG= CSC(1).CSCtime';
lfp_Theta_OG= CSC({CSC.channel_label} == "best_theta").CSCraw;
lfp_Delta_OG= CSC({CSC.channel_label} == "best_delta").CSCraw;
mua_ts_OG= clusters.spike_times;
clear CSC clusters

% load pre-saved thresholds or define for the first time
if exist('extracted_sleep_state_REM_NREM.mat','file')
    load('extracted_sleep_state_REM_NREM.mat');
    speed_thresh_z= sleep_state.thresholds.speed_thresh_z; 
    soft_speed_thresh_z= sleep_state.thresholds.soft_speed_thresh_z;
    thetaDeltaRatio_thresh= sleep_state.thresholds.thetaDeltaRatio_thresh; 
    nremThetaDelta_thresh=sleep_state.thresholds.nremThetaDelta_thresh;
    remThetaDelta_thresh= sleep_state.thresholds.remThetaDelta_thresh; 
else
    % modify the below to fit data better if needed (generally because animals have a tendency to move more or less)
    speed_thresh_z= -0.5; % z-scored speed threshold 
    soft_speed_thresh_z= 0;
    thetaDeltaRatio_thresh= 0.8; % theta/delta
    nremThetaDelta_thresh=-0.1; 
    remThetaDelta_thresh= 0.1; 
end
% following params shouldn't really change
min_immobile_dur= 10;% s minimum immobility bout
min_nrem_dur= 5;% s minimum NREM bout 
min_rem_dur= 2;% s minimum REM bout 
theta_band= [6 10];% Hz
delta_band= [1 4];% Hz
smooth_win= 15;% s smoothing window for envelopes, speed, MUA
mua_bin= 0.01;% s bin for high-res MUA if needed

% keep only sleep-pot times and restrict position to pot
inPot = ~isnan(position.sleepbox);
t= position.t(inPot);
v_cm = position.v_cm(inPot);

% create time vector
lfp_mask= lfp_t_OG >= t(1) & lfp_t_OG <= t(end);
lfp_t= lfp_t_OG(lfp_mask);

time_vector= t(:);
dt_time= median(diff(time_vector));
lfp_fs= 1 / median(diff(lfp_t));

% restrict LFP and MUA to same interval and bandpass filter
[bD,aD]= butter(3, delta_band/(lfp_fs/2), 'bandpass');
lfp_delta= filtfilt(bD,aD,lfp_Delta_OG);
env_delta= abs(hilbert(lfp_delta));

[bT,aT]= butter(3, theta_band/(lfp_fs/2), 'bandpass');
lfp_theta= filtfilt(bT,aT,lfp_Theta_OG);
env_theta= abs(hilbert(lfp_theta));

mua_ts= mua_ts_OG(mua_ts_OG >= t(1) & mua_ts_OG <= t(end));

lfp_Theta= lfp_theta(lfp_mask);
lfp_Delta= lfp_delta(lfp_mask);
env_delta= env_delta(lfp_mask);
env_theta= env_theta(lfp_mask);

% Speed 
nsamples_speed= max(1, round(30 / dt_time));
speed_raw= interp1(t, v_cm, time_vector, 'linear');
speed= movmean(speed_raw, nsamples_speed, 'omitnan');
speed_z= zscore(speed);

% LFP envelopes and theta/delta ratio

% smooth envelopes
Nenv = max(1, round(smooth_win * lfp_fs));
env_delta_s= movmean(env_delta, Nenv);
env_theta_s= movmean(env_theta, Nenv);

% resample to time_vector
env_delta_t= interp1(lfp_t, env_delta_s, time_vector, 'linear');
env_theta_t= interp1(lfp_t, env_theta_s, time_vector, 'linear');

% ratio and z
tdr= env_theta_t./(env_delta_t + eps);
tdrp_z= (env_theta_t - env_delta_t)./(env_delta_t + env_theta_t);
tdr_z= zscore(tdr);

% MUA rate
edges_c= time_vector(1)-smooth_win/2 : 0.1 : time_vector(end)+smooth_win/2;
mua_counts_c= histcounts(mua_ts, edges_c);
bin_centers_c= edges_c(1:end-1) + diff(edges_c)/2;
mua_rate_c= mua_counts_c/0.1;
mua_rate_s= interp1(bin_centers_c, mua_rate_c, time_vector, 'linear', 0);

Nmua= max(1, round(smooth_win/dt_time));
mua_rate_s= movmean(mua_rate_s, Nmua, 'omitnan');
mua_rate_z= zscore(mua_rate_s);

% Immobility mask
min_samples= round(min_immobile_dur/dt_time);
imm_mask= speed_z < speed_thresh_z;
% remove short immobile fragments
imm_mask= imm_mask & bwareaopen(imm_mask, min_samples);

% assign states
% 0 = Wake, 1 = Quiet rest, 2 = NREM, 3 = REM
state= nan(numel(time_vector),1);
is_high_tdr= tdr_z > thetaDeltaRatio_thresh;% threshold as before
is_nrem= imm_mask & tdrp_z <= nremThetaDelta_thresh & ~is_high_tdr;
is_rem= imm_mask & tdrp_z >= remThetaDelta_thresh & is_high_tdr;
is_qrest= (speed_z <= soft_speed_thresh_z) & ~(is_nrem | is_rem);
is_wake= ~imm_mask;

state(is_wake)= 0;
state(is_qrest)= 1;
state(is_nrem)= 2;
state(is_rem)= 3;

% reassign short bouts to neighbours for NREM then REM 
state= reassign_short_bouts(state, 2, min_nrem_dur,dt_time);
state= reassign_short_bouts(state, 3, min_rem_dur,dt_time);

% Plot
figure;
ax1 = subplot(5,1,1);
plot(lfp_t, lfp_Theta_OG(lfp_mask), 'r'); hold on;
plot(lfp_t, lfp_Delta_OG(lfp_mask), 'b');
ylabel('LFP'); title('Raw LFPs');legend({'Theta','Delta'});
xlim([time_vector(1) time_vector(end)]);

ax2 = subplot(5,1,2);
plot(time_vector, speed_z, 'k'); hold on;
% plot(time_vector, speed,'b');
yline(speed_thresh_z, 'k:');
ylabel('z-speed'); legend({'smoothed speed'});
xlim([time_vector(1) time_vector(end)]);

ax3 = subplot(5,1,3);
% plot(time_vector, zscore(env_delta_t), 'b'); hold on;
% plot(time_vector, zscore(env_theta_t), 'r');
plot(time_vector, zscore(env_theta_t ./ (env_delta_t + eps)), 'm');
yline(thetaDeltaRatio_thresh,'k:')
ylabel('Envelope z'); legend({'Theta/Delta env',});
xlim([time_vector(1) time_vector(end)]);

ax4 = subplot(5,1,4);
plot(time_vector, tdrp_z, 'm'); ylabel('Theta/Delta z');
yline(nremThetaDelta_thresh,'k:')
yline(remThetaDelta_thresh,'m:'); ylim([-1 1])
legend({'(Theta-Delta)/(theta+Delta)'});
xlim([time_vector(1) time_vector(end)]);

ax5 = subplot(5,1,5);
plot(time_vector, state, 'LineWidth', 1.8);
yticks(0:4);
yticklabels({'Wake','Quiet','NREM','REM'});
ylim([-0.5 3.5]);
ylabel('state'); title('State (0=Wake,1=QuietRest,2=NREM,3=REM)');
xlim([time_vector(1) time_vector(end)]);

linkaxes([ax1 ax2 ax3 ax4 ax5], 'x');

% Bin states
bin_edges= time_vector(1)-0.05 : 0.1 : time_vector(end)+0.05; 
bin_centers= bin_edges(1:end-1) + diff(bin_edges)/2;

state_binned = nan(numel(bin_centers),1);
for ib = 1:numel(bin_centers)
    inbin = time_vector >= bin_edges(ib) & time_vector < bin_edges(ib+1);
    if any(inbin)
        svals = state(inbin);
        svals = svals(~isnan(svals));
        if ~isempty(svals)
            state_binned(ib) = mode(svals);
        end
    end
end

%interpolate back to original position.t 
state_interp = interp1(time_vector, state, position.t, 'nearest');

% return start/stop ts
unique_states = unique(state(~isnan(state)));
state_indices = struct();
for vs = 1:numel(unique_states)
    val = unique_states(vs);
    mask = (state_interp == val);
    cc = bwconncomp(mask);
    ranges = zeros(cc.NumObjects,2);
    for k = 1:cc.NumObjects
        idxs = cc.PixelIdxList{k};
        ranges(k,1) = position.t(min(idxs)); % start time
        ranges(k,2) = position.t(max(idxs)); % stop time
    end
    fld = sprintf('state_%g', val);
    state_indices.(fld) = ranges;
end

% compute time slept per epoch
%find contiguous pot segments on original position.t
onTrack_full = ~isnan(position.linear(1).linear) | ...
                ~isnan(position.linear(2).linear) | ...
                ~isnan(position.linear(3).linear);
inPot_full = ~onTrack_full;
ccp = bwconncomp(inPot_full);

nEpochs = 5;
time_slept = struct();
for s = 1:nEpochs
    idxs = ccp.PixelIdxList{s};
    tstart = position.t(min(idxs));
    tend= position.t(max(idxs));
    % within this epoch, count time where state_interp is NREM (2) or REM (3)
    inpot_mask = position.t >= tstart & position.t <= tend;
    if any(inpot_mask)
        slept_seconds = sum((state_interp(inpot_mask)==2 | state_interp(inpot_mask)==3)) * median(diff(position.t));
    else
        slept_seconds = 0;
    end
    if s == 1
        key = 'PRE';
    elseif s == nEpochs
        key = 'POST';
    else
        key = sprintf('REST%d', s-1);
    end
    time_slept.(key) = slept_seconds;
end

% save
legendStates = {{'Wake',0}, {'Quiet',1}, {'NREM',2}, {'REM',3}};
thresholds = struct();
thresholds.speed_thresh_z = speed_thresh_z;
thresholds.soft_speed_thresh_z = soft_speed_thresh_z;
thresholds.nremThetaDelta_thresh = nremThetaDelta_thresh;
thresholds.remThetaDelta_thresh = remThetaDelta_thresh;
thresholds.thetaDeltaRatio_thresh = thetaDeltaRatio_thresh;
thresholds.min_immobile_dur = min_immobile_dur;
thresholds.min_nrem_dur = min_nrem_dur;
thresholds.min_rem_dur = min_rem_dur;
thresholds.smooth_win = smooth_win;
thresholds.mua_bin = mua_bin;

sleep_state = struct();
sleep_state.time_binned= bin_centers(:);
sleep_state.state_binned= state_binned(:);
sleep_state.time= time_vector(:);
sleep_state.state = state(:);
sleep_state.state_interp= state_interp(:);
sleep_state.state_indices = state_indices;
sleep_state.time_slept= time_slept;
sleep_state.legend= legendStates;
sleep_state.thresholds= thresholds;

save('extracted_sleep_state_REM_NREM','sleep_state');
end

function state = reassign_short_bouts(state, target_label, min_dur,dt_time)

mask = (state == target_label);
cc = bwconncomp(mask);
for k = 1:cc.NumObjects
    idx = cc.PixelIdxList{k};
    bout_dur = numel(idx) * dt_time;
    if bout_dur < min_dur
        % find neighbor states
        first = idx(1); last = idx(end);
        prev_idx = first - 1;
        next_idx = last + 1;
        prev_state = NaN; next_state = NaN;
        if prev_idx >= 1
            prev_state = state(prev_idx);
        end
        if next_idx <= numel(state)
            next_state = state(next_idx);
        end
        %  assignto neighbor if both neighbors have the same state label
        if ~isnan(prev_state) && ~isnan(next_state) && prev_state == next_state && prev_state ~= target_label
            state(idx) = prev_state;
        elseif ~isnan(prev_state) && prev_state ~= target_label && (isnan(next_state) || prev_state ~= next_state)
            state(idx) = prev_state;
        elseif ~isnan(next_state) && next_state ~= target_label
            state(idx) = next_state;
        else
            % otherwise attribute as quiet rest
            state(idx) = 1;
        end
    end
end

end