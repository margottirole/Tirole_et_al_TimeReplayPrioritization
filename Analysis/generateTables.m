function generateTables(opts,foldersALL,foldersREPLAY)

parameters= list_of_parameters;

% General: generate tables [CANDIDATE,TRACKS,REST,SLEEP]
% fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat');
% fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat');
% fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat');
% fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat');

get_replay_rates_all_epochs(foldersREPLAY,'wcorr');

%% Figure 1 - Behaviour
% fullfile('NEW_TABLES','behaviour\Rbehaviour.csv
% fullfile('NEW_TABLES','behaviour\Rbehaviour_perLap.csv'
% fullfile(opts.dataFolder,'NEW_TABLES','foodPref.csv');
% fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_BEHAVIOUR.mat');

TRACKS= adaptSpeedThresh(foldersALL,parameters.speed_threshold_laps);
save(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_BEHAVIOUR.mat'),'TRACKS');

dt= table; 
dt.rat= TRACKS.rat;
dt.session= TRACKS.session_number;
dt.track= TRACKS.track;
dt.reward= TRACKS.reward;
dt.number_of_laps= TRACKS.num_laps;
dt.number_of_laps_per_min= TRACKS.total_num_laps_per_min;
dt.time_run_zones_immobile= TRACKS.time_run_zones_immobile;
dt.time_run_zones_immobile_per_min= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','behaviour','Rbehaviour.csv'));

dt= table; 
kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.speed_per_lap{ii});
    for ll=1:numLaps
        dt.rat(kk)= TRACKS.rat(ii);
        dt.track(kk)= TRACKS.track(ii);
        dt.session(kk)= TRACKS.session_number(ii);
        dt.reward(kk)= TRACKS.reward(ii);
        dt.total_imm(kk)= TRACKS.time_immobile_per_lap{ii}(ll);  
        dt.total_imm_END(kk)= TRACKS.time_end_zones_immobile_per_lap{ii}(ll);
        dt.run_speed(kk)= TRACKS.speed_per_lap{ii}(ll);
        dt.stop_speed(kk)= TRACKS.speedSLOW_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','behaviour','Rbehaviour_perLap.csv'));

% run stats
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','behaviour'); % working dir for R
r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_behaviour_FULL.R'); % script to run
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path, 'Rbehaviour.csv', '');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path , 'Rbehaviour_perLap.csv', '');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

%% Figure 2 - replay rates and behavioural state
% fullfile('NEW_TABLES','replay\RLocalReplayLaps.csv'
% fullfile('NEW_TABLES','replay\RSWRLaps.csv'
% fullfile('NEW_TABLES','replay\RLocalFWDLaps.csv'
% fullfile('NEW_TABLES','replay\RLocalREVLaps.csv'
% fullfile('NEW_TABLES','replay\RRest1.csv',fullfile('NEW_TABLES','replay\RRest2.csv',fullfile('NEW_TABLES','replay\RRest3.csv'
% fullfile('NEW_TABLES','replay\RsleepPOSTreplayRate_overall.csv'
% fullfile('NEW_TABLES','replay\RPOSTreplayRate_overall.csv'
% fullfile('NEW_TABLES','replay\LocalReplay_fixed_effects_speedLap.csv'
% fullfile('NEW_TABLES','replay\LocalReplay_fixed_effects_all.csv'

load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

dt= table; kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocal_per_lap{ii});
    for ll=1:numLaps
            dt.rat(kk)= TRACKS.rat(ii);
            dt.track(kk)= TRACKS.track(ii);
            dt.session(kk)= TRACKS.session_number(ii);
            dt.reward(kk)= TRACKS.reward(ii);
            dt.lap_number(kk)= ll;
            dt.event_rate(kk)= TRACKS.rateLocal_per_lap{ii}(ll);
            dt.duration(kk)= TRACKS.time_immobile_per_lap{ii}(ll);
            dt.speed(kk)= TRACKS.speed_imm_per_lap{ii}(ll);
            kk=kk+1;
    end
end
mean_speed= mean(dt.speed);
mean_lap_number= mean(dt.lap_number);
dt.speed= dt.speed - mean_speed;
dt.mean_speed= repmat(mean_speed,height(dt),1);
dt.lap_number= dt.lap_number - mean_lap_number;
dt.mean_lap_number= repmat(mean_lap_number,height(dt),1);
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','RLocalReplayLaps.csv'));

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocal_per_lap{ii});
    for ll=1:numLaps
        dt.event_rate(kk)= TRACKS.rateSWR_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','RSWRLaps.csv'))

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocalFWD_per_lap{ii});
    for ll=1: numLaps
        dt.event_rate(kk)= TRACKS.rateLocalFWD_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','RLocalFWDLaps.csv'))

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocalREV_per_lap{ii});
    for ll=1:numLaps
        dt.event_rate(kk)= TRACKS.rateLocalREV_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','RLocalREVLaps.csv'))

dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= SLEEP.sleepPOSTreplayRate_overall; 
write(dt,fullfile(opts.dataFolder,'NEW_TABLES','replay','RsleepPOSTreplayRate_overall.csv'));
    
dt.rate= SLEEP.POSTreplayRate_overall; 
write(dt,fullfile(opts.dataFolder,'NEW_TABLES','replay','RPOSTreplayRate_overall.csv'));

% run stats
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','replay');
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end
r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_FULL.R');    

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RSWRLaps.csv','','SWR');
[status, out] = system(cmd);
if status ~= 0
  error('RSWR call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalReplayLaps.csv','','LocalReplay');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalReplay call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalFWDLaps.csv','','LocalFWDLaps');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalFWDLaps call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalREVLaps.csv','','LocalREVLaps');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalREVLaps call failed:\n%s', out);
end

r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_restFULL.R');   
for thisR=1:3
    cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'],opts.R_BIN, r_script, wd_path,['RRest' num2str(thisR) '.csv'], '',['Rest' num2str(thisR)]);
    [status, out] = system(cmd);
    if status ~= 0
      error('R call failed:\n%s', out);
    end
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RsleepPOSTreplayRate_overall.csv','','sleepPOSTreplayRate_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RPOSTreplayRate_overall.csv','','POSTreplayRate_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RsleepPOSTreplayRate_overall.csv','','sleepPOSTreplayRate_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RPOSTreplayRate_overall.csv','','POSTreplayRate_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end
    
%% Figure 3
% -> stats cand events and local replay with recency (already computed for fig2)
dt= table; k=1;
for thisS=3:3:height(SLEEP)   
    for thisT=1:length(SLEEP.NremRemPOSTreplayRate{thisS})
        dt.rat(k)= SLEEP.rat(thisS);
        dt.session(k)= SLEEP.session(thisS);
        dt.rate(k)= SLEEP.NremRemPOSTreplayRate{thisS}(thisT);
        dt.time(k)= SLEEP.NremRemPOSTbinCtrs{thisS}(thisT);
         k=k+1;
    end
end
write(dt,fullfile(opts.dataFolder,'NEW_TABLES','replay','sleepPOSTcumulTime.csv'));

%% Figure 4
get_replay_involvment(foldersREPLAY);
regress_replayChangeMap(foldersREPLAY);

corrTable= table; warning('off')
for this_folder=1:length(foldersREPLAY)
    cd(fullfile(opts.dataFolder,foldersREPLAY{this_folder}));
    disp(['       ' foldersREPLAY{this_folder}]);
    tmp= stabilisationMap;
    corrTable= [corrTable ; tmp];
    cd(opts.dataFolder)
end
warning('on');
save(fullfile(opts.dataFolder,'NEW_TABLES','corrTable.mat'),'corrTable');

r_script=  fullfile(opts.scriptsFolder,'R','regressReplayChangesMaps.R');   
wd_path= fullfile(opts.dataFolder,'NEW_TABLES');
if ~exist(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps'),'dir')
    mkdir(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps'));
end
cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script,wd_path,'regressReplayChange.csv','changingMaps');
[status, out] = system(cmd);
if status ~= 0
  error('R regressReplayChangesMaps call failed:\n%s', out);
end


%% Figure 5
% obtain table replay rates
Replays= buildTableModel(opts,foldersREPLAY);
save(fullfile(opts.dataFolder,'NEW_TABLES','Replay_Decay_Model','ReplaysTable.mat'),'Replays');
% run tau scan
tauGrid = [linspace(1*60,9*60,9) linspace(10*60, 60*60, 60)];
tauResult= runGlobalTauScan(Replays,tauGrid,'sleep'); 
save(fullfile(opts.dataFolder,'NEW_TABLES','Replay_Decay_Model','tauResults_trainSleep.mat'),'tauResult');


%% Figure S2
%% CREATE TABLES
speedThresh= 2;
TRACKS= adaptSpeedThresh(foldersALL,speedThresh);
if ~exist(fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)]),'dir')
    mkdir(fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)]));
end
save(fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'TRACKS_BEHAVIOUR.mat'),'TRACKS');

dt= table; 
dt.rat= TRACKS.rat;
dt.track= TRACKS.track;
dt.session= TRACKS.session_number;
dt.reward= TRACKS.reward;
dt.number_of_laps= TRACKS.num_laps;
dt.number_of_laps_per_min= TRACKS.total_num_laps_per_min;
dt.time_run_zones_immobile= TRACKS.time_run_zones_immobile;
dt.time_run_zones_immobile_per_min= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'Rbehaviour_adapt_thresh.csv'));

dt= table; 
kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.time_immobile_per_lap{ii});
    for ll=1:numLaps
        dt.rat(kk)= TRACKS.rat(ii);
        dt.track(kk)= TRACKS.track(ii);
        dt.session(kk)= TRACKS.session_number(ii);
        dt.reward(kk)= TRACKS.reward(ii);
        dt.total_imm(kk)= TRACKS.time_immobile_per_lap{ii}(ll);  
        dt.total_imm_END(kk)= TRACKS.time_end_zones_immobile_per_lap{ii}(ll);
        dt.run_speed(kk)= TRACKS.speed_per_lap{ii}(ll);
        dt.stop_speed(kk)= TRACKS.speedSLOW_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)],'Rbehaviour_perLap_adapt_thresh.csv'));
r_script=  fullfile(opts.scriptsFolder,'R','glmm_effects_behaviour_FULL.R');   
wd_path= fullfile(opts.dataFolder,'NEW_TABLES',['AdaptSpeedThresh_' num2str(speedThresh)]);
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path,'Rbehaviour_adapt_thresh.csv','');
[status, out] = system(cmd);
if status ~= 0
  error('R call AdaptSpeedThresh failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path,'Rbehaviour_perLap_adapt_thresh.csv','');
[status, out] = system(cmd);
if status ~= 0
  error('R call AdaptSpeedThresh per lap failed:\n%s', out);
end

%% Figure S3
speedThresh= parameters.speed_threshold_laps; % normal threshold
TRACKS= adaptSpeedThresh(foldersALL,speedThresh);
TRACKS(~ismember(TRACKS.rat,opts.replay_rats),:)=[];
if ~exist(fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats'),'dir')
    mkdir(fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats'));
end
save(fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats','TRACKS_BEHAVIOUR.mat'),'TRACKS');

dt= table; 
dt.rat= TRACKS.rat;
dt.track= TRACKS.track;
dt.session= TRACKS.session_number;
dt.reward= TRACKS.reward;
dt.number_of_laps= TRACKS.num_laps;
dt.number_of_laps_per_min= TRACKS.total_num_laps_per_min;
dt.time_run_zones_immobile= TRACKS.time_run_zones_immobile;
dt.time_run_zones_immobile_per_min= TRACKS.time_run_zones_immobile./TRACKS.time_on_track_min;
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats','Rbehaviour_replayRats.csv'));

dt= table; 
kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.time_immobile_per_lap{ii});
    for ll=1:numLaps
        dt.rat(kk)= TRACKS.rat(ii);
        dt.track(kk)= TRACKS.track(ii);
        dt.session(kk)= TRACKS.session_number(ii);
        dt.reward(kk)= TRACKS.reward(ii);
        dt.total_imm(kk)= TRACKS.time_immobile_per_lap{ii}(ll);  
        dt.total_imm_END(kk)= TRACKS.time_end_zones_immobile_per_lap{ii}(ll);
        dt.run_speed(kk)= TRACKS.speed_per_lap{ii}(ll);
        dt.stop_speed(kk)= TRACKS.speedSLOW_per_lap{ii}(ll);
        kk=kk+1;
    end
end
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats','Rbehaviour_perLap_replayRats.csv'));

r_script=  fullfile(opts.scriptsFolder,'R','glmm_effects_behaviour_FULL.R');   
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','behaviourReplayRats');
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path,'Rbehaviour_replayRats.csv','');
[status, out] = system(cmd);
if status ~= 0
  error('R call behaviourReplayRats failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path,'Rbehaviour_perLap_replayRats.csv','');
[status, out] = system(cmd);
if status ~= 0
  error('R call behaviourReplayRats per lap failed:\n%s', out);
end

%% Figure S4

load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

% post
dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= SLEEP.POSTreplayRate_overall;
write(dt,fullfile(opts.dataFolder,'NEW_TABLES',RPOST_overall.csv');

% sleep post 
dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= SLEEP.sleepPOSTreplayRate_overall;
write(dt,fullfile(opts.dataFolder,'NEW_TABLES',RSleepPOST_overall.csv');

% sleep post first X min
dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= cell2mat(SLEEP.NremRemPOSTreplayRate_0_to_900);
write(dt,fullfile(opts.dataFolder,'NEW_TABLES',RSleepPOST_firstXmin.csv');

% pre
dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= SLEEP.PREreplayRate;
write(dt,fullfile(opts.dataFolder,'NEW_TABLES',RPRE_overall.csv');

% sleep pre
dt= table; 
dt.rat= SLEEP.rat;
dt.session= SLEEP.session_number;
dt.track= SLEEP.track;
dt.reward= SLEEP.reward;
dt.rate= SLEEP.sleepPREreplayRate_overall;
write(dt,fullfile(opts.dataFolder,'NEW_TABLES',RSleepPRE_overall.csv');

% rest and sleep
r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_restFULL.R');
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','replay');

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RSleepPOST_overall.csv','','SleepPOST_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RPOST_overall.csv','','POST_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RSleepPRE_overall.csv','','SleepPRE_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RPRE_overall.csv','','PRE_overall');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RSleepPOST_firstXmin.csv','','sleepPOST_firstXmin');
[status, out] = system(cmd);
if status ~= 0
  error('R call failed:\n%s', out);
end

%% Figure S5

load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

dt= table; kk=1;
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocal_per_lap_REWSITE{ii});
    for ll=1:numLaps
            dt.rat(kk)= TRACKS.rat(ii);
            dt.track(kk)= TRACKS.track(ii);
            dt.session(kk)= TRACKS.session_number(ii);
            dt.reward(kk)= TRACKS.reward(ii);
            dt.lap_number(kk)= ll;
            dt.event_rate(kk)= TRACKS.rateLocal_per_lap_REWSITE{ii}(ll);
            dt.duration(kk)= TRACKS.time_immobile_per_lap_REWSITE{ii}(ll);
            dt.speed(kk)= TRACKS.speed_imm_per_lap_REWSITE{ii}(ll);
            kk=kk+1;
    end
end
mean_speed= mean(dt.speed);
mean_lap_number= mean(dt.lap_number);
dt.speed= dt.speed - mean_speed;
dt.mean_speed= repmat(mean_speed,height(dt),1);
dt.lap_number= dt.lap_number - mean_lap_number;
dt.mean_lap_number= repmat(mean_lap_number,height(dt),1);
writetable(dt,fullfile('NEW_TABLES','REWSITE','RLocalReplayLapsREWSITE.csv'))

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocal_per_lap_REWSITE{ii});
    for ll=1:numLaps
            dt.event_rate(kk)= TRACKS.rateSWR_per_lap_REWSITE{ii}(ll);
            kk=kk+1;
    end
end
writetable(dt,fullfile('NEW_TABLES','REWSITE','RSWRLapsREWSITE.csv'))

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocalFWD_per_lap_REWSITE{ii});
    for ll=1: numLaps
            dt.event_rate(kk)= TRACKS.rateLocalFWD_per_lap{ii}(ll);
            kk=kk+1;
    end
end
writetable(dt,fullfile('NEW_TABLES','REWSITE','RLocalFWDLapsREWSITE.csv'))

kk=1; dt.event_rate= [];
for ii=1:height(TRACKS)
    numLaps= length(TRACKS.rateLocalREV_per_lap_REWSITE{ii});
    for ll=1:numLaps
            dt.event_rate(kk)= TRACKS.rateLocalREV_per_lap_REWSITE{ii}(ll);
            kk=kk+1;
    end
end
writetable(dt,fullfile('NEW_TABLES','REWSITE','RLocalREVLapsREWSITE.csv'))

% run in R
r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_restFULL.R');
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','REWSITE');
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RSWRLapsREWSITE.csv','','SWR');
[status, out] = system(cmd);
if status ~= 0
  error('RSWR REWSITE call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalReplayLapsREWSITE.csv','','LocalReplay');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalReplay REWSITE call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalFWDLapsREWSITE.csv','','LocalFWDLaps');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalFWDLaps REWSITE call failed:\n%s', out);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s" --dep_name "%s"'], opts.R_BIN, r_script, wd_path,'RLocalREVLapsREWSITE.csv','REWSITE','LocalREVLaps');
[status, out] = system(cmd);
if status ~= 0
  error('RLocalREVLaps REWSITE call failed:\n%s', out);
end

%% Figure S6

dt= table; 
dt.rat= TRACKS.rat;
dt.session= TRACKS.session_number;
dt.track= TRACKS.track;
dt.reward= TRACKS.reward;
dt.Localquality= TRACKS.Local_replay_meanWScore;
dt.LocalFWDquality= TRACKS.LocalForward_replay_meanWScore; 
dt.LocalREVquality= TRACKS.LocalReverse_replay_meanWScore;
writetable(dt,fullfile(opts.dataFolder,'NEW_TABLES','quality','RReplayQualityLaps.csv'))

r_script= fullfile(opts.scriptsFolder,'R','glmm_effects_qualityFULL.R');
wd_path= fullfile(opts.dataFolder,'NEW_TABLES','quality');
if ~exist(wd_path,'dir')
    mkdir(wd_path);
end

cmd = sprintf(['"%s" "%s" --wd_path "%s" --load_path "%s" --save_path "%s"'], opts.R_BIN, r_script, wd_path,'RReplayQualityLaps.csv','');
[status, out] = system(cmd);
if status ~= 0
  error('R quality call failed:\n%s', out);
end


%% Figure S7
getDecodingErrorsLaps(foldersREPLAY);

end