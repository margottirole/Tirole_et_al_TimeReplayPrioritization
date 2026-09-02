function makeFigure4(opts)
%% Figure 4
load(fullfile(opts.dataFolder,'colour palettes\ScientificColourMaps6\tofino\tofino.mat'));
cdata_cell_types= tofino([20 size(tofino,1)/2 size(tofino,1)-20],:);
cdata_cell_types(2,:)= [0.7 0.7 0.7];

load(fullfile(opts.dataFolder,'colour palettes\ScientificColourMaps6\acton\acton.mat'));
cdata_LocRem= acton([20 size(acton,1)/2 size(acton,1)-20],:);

%% PRE REQ tables
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));


load(fullfile(opts.dataFolder,'NEW_TABLES','regressReplayChange.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','replay_involvment.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','corrTable.mat'));

%% PANEL B - map stabilisation x laps
warning('off');

availSess= unique(corrTable.session);
corrTable_wide= table; k=1;
for thisS=1:length(availSess)
    currSess= string(availSess{thisS});
    idx= corrTable.session == currSess;    
    for thisT=1:3
        corrVal= corrTable.corrValue(idx & corrTable.track == thisT);
        corrTable_wide.rat(k)= unique(corrTable.rat(idx));
        corrTable_wide.session(k)= currSess;
        corrTable_wide.track(k)= thisT;
        corrTable_wide.reward(k)= string(TRACKS.reward{TRACKS.session == currSess & TRACKS.track == thisT});
        corrTable_wide.corrValue{k}= corrVal';
        k=k+1;
    end   
end

figure;
nexttile; hold on; 
p=[];
for thisT=1:3
    data= cell2mat(corrTable_wide.corrValue(corrTable_wide.track ==  thisT));
    dataMean= mean(data,1,'omitmissing');
    dataSem= nansem(data);
    fill([1:10 fliplr(1:10)],[dataMean-dataSem fliplr(dataMean+dataSem)],opts.cdata_rec{thisT},'FaceAlpha',0.2,'EdgeColor','none');
    p(thisT)= plot(dataMean,'Color',opts.cdata_rec{thisT},'LineWidth',2); 
end
legend(p,{'track1','track2','track3'},'Box','off','Location','southeast');
ylabel('pearson correlation (r)'); xlabel('lap number');
title('map stabilisation');


%% PANEL C - peak FR cells per category x laps
maxLaps=10;
nexttile; hold on;
title('FR cells laps');
FR_both= vertcat(replay_involvment.both_cells_FR{:});
FR_past= vertcat(replay_involvment.past_cells_FR{:});
FR_novel= vertcat(replay_involvment.novel_cells_FR{:});
% both
fill([1:size(FR_both,2) fliplr(1:size(FR_both,2))],[mean(FR_both,'omitmissing')-nansem(FR_both) fliplr(mean(FR_both,'omitmissing') + nansem(FR_both))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(1:maxLaps,mean(FR_both,'omitmissing'),'Color',cdata_cell_types(1,:),'LineWidth',1.5);
% past
fill([1:size(FR_past,2) fliplr(1:size(FR_past,2))],[mean(FR_past,'omitmissing')-nansem(FR_past) fliplr(mean(FR_past,'omitmissing') + nansem(FR_past))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(1:maxLaps,mean(FR_past,'omitmissing'),'Color',cdata_cell_types(2,:),'LineWidth',1.5);
% novel
fill([1:size(FR_novel,2) fliplr(1:size(FR_novel,2))],[mean(FR_novel,'omitmissing')-nansem(FR_novel) fliplr(mean(FR_novel,'omitmissing') + nansem(FR_novel))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(3)= plot(1:maxLaps,mean(FR_novel,'omitmissing'),'Color',cdata_cell_types(3,:),'LineWidth',1.5);
legend(p,{'past','active both','novel'},'Box','off','Location','east');
xlabel('lap'); ylabel('average peak firing rate');
xticks([1 5 10])

%% PANEL D - map stabilisation per category x laps
nexttile; hold on;
title('stabilisation each cell type');
both_corr= vertcat(replay_involvment.both_cells_corr{:});
past_corr= vertcat(replay_involvment.past_cells_corr{:});
novel_corr= vertcat(replay_involvment.novel_cells_corr{:});
% both
fill([1:size(both_corr,2) fliplr(1:size(both_corr,2))],[mean(both_corr,'omitmissing')-nansem(both_corr) fliplr(mean(both_corr,'omitmissing') + nansem(both_corr))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(1:maxLaps,mean(both_corr,'omitmissing'),'Color',cdata_cell_types(1,:),'LineWidth',1.5);
% past
fill([1:size(past_corr,2) fliplr(1:size(past_corr,2))],[mean(past_corr,'omitmissing')-nansem(past_corr) fliplr(mean(past_corr,'omitmissing') + nansem(past_corr))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(1:maxLaps,mean(past_corr,'omitmissing'),'Color',cdata_cell_types(2,:),'LineWidth',1.5);
% novel
fill([1:size(novel_corr,2) fliplr(1:size(novel_corr,2))],[mean(novel_corr,'omitmissing')-nansem(novel_corr) fliplr(mean(novel_corr,'omitmissing') + nansem(novel_corr))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(3)= plot(1:maxLaps,mean(novel_corr,'omitmissing'),'Color',cdata_cell_types(3,:),'LineWidth',1.5);
legend(p,{'past','active both','novel'},'Box','off','Location','east');
xlabel('lap'); ylabel('between lap field correlation');
ylim([0 1]); xticks([1 5 10])

%% PANEL E - replay involvment per category x laps
nexttile; hold on; % shared cells
p=[];
dataLocal= cell2mat(replay_involvment.prop_involvment_past_cells_local_lap);
dataRemote= cell2mat(replay_involvment.prop_involvment_past_cells_remote_lap);
fill([1:size(dataLocal,2) fliplr(1:size(dataLocal,2))],[mean(dataLocal,'omitmissing')-nansem(dataLocal) fliplr(mean(dataLocal,'omitmissing') + nansem(dataLocal))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(mean(dataLocal,'omitmissing'),'Color',cdata_cell_types(2,:),'LineWidth',2);
fill([1:size(dataRemote,2) fliplr(1:size(dataRemote,2))],[mean(dataRemote,'omitmissing')-nansem(dataRemote) fliplr(mean(dataRemote,'omitmissing') + nansem(dataRemote))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(mean(dataRemote,'omitmissing'),'Color',cdata_cell_types(2,:),'LineStyle','-.','LineWidth',2);
title('past cells'); ylim([0 0.45]); xlabel('half laps')
legend(p,{'local','remote'},'Box','off'); ylabel('% of replays cells active in');

nexttile; hold on; % both cells
dataLocal= cell2mat(replay_involvment.prop_involvment_both_cells_local_lap);
dataRemote= cell2mat(replay_involvment.prop_involvment_both_cells_remote_lap);
fill([1:size(dataLocal,2) fliplr(1:size(dataLocal,2))],[mean(dataLocal,'omitmissing')-nansem(dataLocal) fliplr(mean(dataLocal,'omitmissing') + nansem(dataLocal))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(mean(dataLocal,'omitmissing'),'Color',cdata_cell_types(1,:),'LineWidth',2);
fill([1:size(dataRemote,2) fliplr(1:size(dataRemote,2))],[mean(dataRemote,'omitmissing')-nansem(dataRemote) fliplr(mean(dataRemote,'omitmissing') + nansem(dataRemote))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(mean(dataRemote,'omitmissing'),'Color',cdata_cell_types(1,:),'LineStyle','-.','LineWidth',2);
title('shared cells'); ylim([0 0.45]); xlabel('half laps')

nexttile; hold on; % novel cells
dataLocal= cell2mat(replay_involvment.prop_involvment_novel_cells_local_lap);
dataRemote= cell2mat(replay_involvment.prop_involvment_novel_cells_remote_lap);
fill([1:size(dataLocal,2) fliplr(1:size(dataLocal,2))],[mean(dataLocal,'omitmissing')-nansem(dataLocal) fliplr(mean(dataLocal,'omitmissing') + nansem(dataLocal))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(mean(dataLocal,'omitmissing'),'Color',cdata_cell_types(3,:),'LineWidth',2);
fill([1:size(dataRemote,2) fliplr(1:size(dataRemote,2))],[mean(dataRemote,'omitmissing')-nansem(dataRemote) fliplr(mean(dataRemote,'omitmissing') + nansem(dataRemote))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(mean(dataRemote,'omitmissing'),'Color',cdata_cell_types(3,:),'LineStyle','-.','LineWidth',2);
title('newly recruited cells'); ylim([0 0.45]); xlabel('half laps')

%% PANEL G - map stability x number of replays AND
%% PANEL H -  map stability x number of replays (regressions)

nexttile;
img = imread(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps','LocalEvents_CorrData.png'));
imshow(img);

nexttile;
img = imread(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps','LocalEvents_CorrReg.png'));
imshow(img);

nexttile;
img = imread(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps','RemoteEvents_CorrReg.png'));
imshow(img);

warning('on');
end