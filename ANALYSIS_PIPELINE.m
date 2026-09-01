%% ANALYSIS_PIPELINE
% Basic processing pipeline for "Time, but not reward, shapes replay-based
% episodic prioritization" BioRxiv, Tirole et al 2026, https://doi.org/10.64898/2026.06.10.731494

% External dependencies:
% download data from figshare
% clone github repos: https://github.com/bendor-lab/Elife_Tirole_Huelin_Gorriz_2022 and https://github.com/margottirole/Tirole_et_al_TimeReplayPrioritization
% download ScientificColourMaps6 colour palettes to data folder (to replicate colour scheme in manuscript)

%% USER CONFIG
opts.dataFolder = ''; %'C:\Users\mario\Downloads\DRYAD' % path to figshare repo (link TBD)
opts.elifeFolder = ''; % path to cloned https://github.com/bendor-lab/Elife_Tirole_Huelin_Gorriz_2022
opts.scriptsFolder = ''; % path to cloned https://github.com/margottirole/Tirole_et_al_TimeReplayPrioritization

% make sure newer functions superseed older ones
addpath(genpath(opts.scriptsFolder), '-begin');
addpath(genpath(opts.elifeFolder), '-end');
rehash toolboxcache

% set options and paths
opts.R_BIN= ''; % e.g. C:\Program Files\R\R-4.4.2\bin\Rscript.exe
opts.REW= ["LOW","HIGH"];
opts.Mrks= {'diamond','square','hexagram','o','^'};
opts.rats= {'R839_Navi','R846_Toliman','R852_Ogma','R857_Polaris','R860_Rigel'};
opts.correspID= {'RAT1','RAT5','RAT4','RAT2','RAT3'};
opts.replay_rats= {'R839_Navi','R857_Polaris','R860_Rigel'};

% adapt paths below based on where you saved the colour palettes
% reward colours
load(fullfile(opts.dataFolder,'colour palettes','ScientificColourMaps6','berlin','DiscretePalettes','berlin10.mat'));
opts.cdata_rew= [{berlin10(1,:)},...
       {berlin10(8,:)}];
% recency colours
load(fullfile(opts.dataFolder,'colour palettes','ScientificColourMaps6','bamako','DiscretePalettes','bamako10.mat'));
opts.cdata_rec= [{bamako10(1,:)},...
       {bamako10(6,:)},...
       {bamako10(8,:)}];

cd(opts.dataFolder)
parameters= list_of_parameters;

%% REORGANISE DATA FOR CONVENIENCE 
% only needs to be done first time after downloading data
files = dir(fullfile(opts.dataFolder,'RAT*_SESSION*_*.mat')); 
files= {files.name};
for f = 1:length(files)
    t = strsplit(files{f},'_');
    ratFolder = t{1};
    sessionFolder = t{2};
    dest = fullfile(ratFolder, sessionFolder);
    if ~exist(dest,'dir'), mkdir(dest); end
    movefile(files{f}, fullfile(dest, strjoin(t(3:end),'_')));
end

foldersALL= load(fullfile(opts.scriptsFolder,"folders_ALL.mat")); % list of sessions from all rats
foldersALL= foldersALL.foldersALL;
foldersREPLAY= load(fullfile(opts.scriptsFolder,"folders_REPLAY.mat")); % list of sessions from rats included in replay analyses
foldersREPLAY= foldersREPLAY.foldersALL;

%% MAIN PROCESSING OF DATA
for this_folder=1:length(foldersALL) % you may want to change to parfor for speed

     cd(fullfile(opts.dataFolder,foldersALL{this_folder}));
     disp(['processing: ' foldersALL{this_folder}]);
    
     % extract laps
     run_analysis_step('EXTRACT_POSITION'); 

     if ismember(foldersALL{this_folder},foldersREPLAY)
         % extract sleep stages
         run_analysis_step('SLEEP');
         % calculate place fields
         run_analysis_step('PLACE FIELDS');
         % extracts spike counts, bayesian posterior matrices and candidate events
         run_analysis_step('extract bayesian and replay');
         % run shuffles and score replay events
         run_analysis_step('REPLAY'); 
         % find significant events and sort by epoch
         run_analysis_step('SORT_EVENTS');
    
         % run procedure to obtain forward/reverse replay events
         run_analysis_step('DIRECTIONAL_FIELDS');
         cd('.\Directional Analysis\');
         run_analysis_step('REPLAY'); % this will take a while to run
         run_analysis_step('SORT_EVENTS');
     end

     cd(opts.dataFolder);
end
disp('processing of all sessions: done.');

%% ANALYSIS
% this will take quite a while
generateTables(opts,foldersALL,foldersREPLAY);

%% MAKE FIGURES
% main figures below
makeFigure1(opts);
makeFigure2(opts);
makeFigure3(opts);
makeFigure4(opts);
makeFigure5(opts);