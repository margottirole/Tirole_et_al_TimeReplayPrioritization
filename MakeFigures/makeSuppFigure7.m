function makeSuppFigure7(opts)
%% Figure S7
load(fullfile(opts.dataFolder,'NEW_TABLES','TRACKS_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','REST_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','SLEEP_REPLAY_EVENTS.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','CANDIDATE_EVENTS.mat'));

load(fullfile(opts.dataFolder,'NEW_TABLES','regressReplayChange.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','replay_involvment.mat'));
load(fullfile(opts.dataFolder,'NEW_TABLES','DECODING_ERRORS_LAPS.mat'));

load(fullfile(opts.dataFolder,'colour palettes\ScientificColourMaps6\tofino\tofino.mat'));
cdata_cell_types= tofino([20 size(tofino,1)/2 size(tofino,1)-20],:);
cdata_cell_types(2,:)= [0.7 0.7 0.7];

load(fullfile(opts.dataFolder,'colour palettes\ScientificColourMaps6\acton\acton.mat'));
cdata_LocRem= acton([20 size(acton,1)/2 size(acton,1)-20],:);

%% DECODING ERROR
warning('off');
figure;
nexttile; hold on;
title({'decoding accuracy';'with experience'});
data= cell2mat(decodingErrors.meanDistLocal);
maxlaps= find(sum(isnan(data),1) == size(data,1),1,'first') -1;
fill([1:maxlaps fliplr(1:maxlaps)],[mean(data(:,1:maxlaps),'omitmissing')-nansem(data(:,1:maxlaps)) fliplr(mean(data(:,1:maxlaps),'omitmissing')+nansem(data(:,1:maxlaps)))],...
    'k','FaceAlpha',0.3,'EdgeColor','none');
plot(1:maxlaps, mean(data(:,1:maxlaps),'omitmissing'),'k','LineWidth',1.5);
xlabel('half lap number');
ylabel('mean distance to real position');
xlim([0 maxlaps])

%% CELL TYPE DISTIBUTION
nexttile; hold on;
title({'cell category';'distribution'});
availSess= unique(replay_involvment.session);
percent_both=[]; percent_novel=[]; total_cells= []; percent_past=[]; 
for thisS=1:height(availSess)
    for thisT=2:3
        sidx= replay_involvment.session == string(availSess{thisS}) & replay_involvment.track == thisT;
        total_cells(thisS,thisT-1)= replay_involvment.numNovelcells(sidx) + ...
                                    replay_involvment.numBothcells(sidx) + ...
                                    replay_involvment.numPastcells(sidx);
        percent_novel(thisS,thisT-1)= 100*replay_involvment.numNovelcells(sidx)/total_cells(thisS,thisT-1);
        percent_both(thisS,thisT-1)= 100*replay_involvment.numBothcells(sidx)/total_cells(thisS,thisT-1);
        percent_past(thisS,thisT-1)= 100*replay_involvment.numPastcells(sidx)/total_cells(thisS,thisT-1);
    end
end
v0= boxplot(percent_past,'Positions',1:2,'Colors',cdata_cell_types(2,:),'Widths',0.1);
v= boxplot(percent_novel,'Positions',[1:2]+0.2,'Colors',cdata_cell_types(3,:),'Widths',0.1);
v2= boxplot(percent_both,'Positions',[1:2]+0.4,'Colors',cdata_cell_types(1,:),'Widths',0.1);
legend({'newly recruited','shared','past'},'Box','off','AutoUpdate','off');
xlim([0.6 2.8]); xticks([1:2]+0.2); xticklabels([2:3]); ylim([0 100])
xlabel('track'); ylabel('percentage of cells')

%% INVOLVEMENT CELL TYPES LOCAL REPLAY
nexttile; hold on; 
p=[]; % LOCAL inv
dataLocalPast= cell2mat(replay_involvment.prop_past_cells_local_lap);
dataLocalBoth= cell2mat(replay_involvment.prop_both_cells_local_lap);
dataLocalNovel= cell2mat(replay_involvment.prop_novel_cells_local_lap);
% past cells
fill([1:size(dataLocalPast,2) fliplr(1:size(dataLocalPast,2))],[mean(dataLocalPast,'omitmissing')-nansem(dataLocalPast) fliplr(mean(dataLocalPast,'omitmissing') + nansem(dataLocalPast))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(mean(dataLocalPast,'omitmissing'),'Color',cdata_cell_types(2,:),'LineWidth',2);
% both
fill([1:size(dataLocalBoth,2) fliplr(1:size(dataLocalBoth,2))],[mean(dataLocalBoth,'omitmissing')-nansem(dataLocalBoth) fliplr(mean(dataLocalBoth,'omitmissing') + nansem(dataLocalBoth))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(mean(dataLocalBoth,'omitmissing'),'Color',cdata_cell_types(1,:),'LineWidth',2);
title('past cells'); 
% novel
fill([1:size(dataLocalNovel,2) fliplr(1:size(dataLocalNovel,2))],[mean(dataLocalNovel,'omitmissing')-nansem(dataLocalNovel) fliplr(mean(dataLocalNovel,'omitmissing') + nansem(dataLocalNovel))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(3)= plot(mean(dataLocalNovel,'omitmissing'),'Color',cdata_cell_types(3,:),'LineWidth',2);
title('local replay');
xlabel('half laps')
ylabel('fraction of cell types in replay'); ylim([0 0.85])

%% INVOLVEMENT CELL TYPES REMOTE REPLAY
nexttile; hold on; % REMOTE inv
dataRemotePast= cell2mat(replay_involvment.prop_past_cells_remote_lap);
dataRemoteBoth= cell2mat(replay_involvment.prop_both_cells_remote_lap);
dataRemoteNovel= cell2mat(replay_involvment.prop_novel_cells_remote_lap);
% past cells
fill([1:size(dataRemotePast,2) fliplr(1:size(dataRemotePast,2))],[mean(dataRemotePast,'omitmissing')-nansem(dataRemotePast) fliplr(mean(dataRemotePast,'omitmissing') + nansem(dataRemotePast))],...
    cdata_cell_types(2,:),'FaceAlpha',0.3,'EdgeColor','none');
p(1)= plot(mean(dataRemotePast,'omitmissing'),'Color',cdata_cell_types(2,:),'LineWidth',2);
% both
fill([1:size(dataRemoteBoth,2) fliplr(1:size(dataRemoteBoth,2))],[mean(dataRemoteBoth,'omitmissing')-nansem(dataRemoteBoth) fliplr(mean(dataRemoteBoth,'omitmissing') + nansem(dataRemoteBoth))],...
    cdata_cell_types(1,:),'FaceAlpha',0.3,'EdgeColor','none');
p(2)= plot(mean(dataRemoteBoth,'omitmissing'),'Color',cdata_cell_types(1,:),'LineWidth',2);
title('past cells');
% novel
fill([1:size(dataRemoteNovel,2) fliplr(1:size(dataRemoteNovel,2))],[mean(dataRemoteNovel,'omitmissing')-nansem(dataRemoteNovel) fliplr(mean(dataRemoteNovel,'omitmissing') + nansem(dataRemoteNovel))],...
    cdata_cell_types(3,:),'FaceAlpha',0.3,'EdgeColor','none');
p(3)= plot(mean(dataRemoteNovel,'omitmissing'),'Color',cdata_cell_types(3,:),'LineWidth',2);
title('remote replay'); xlabel('half laps')
ylabel('fraction of cell types in replay'); ylim([0 0.85])
legend(p,{'past','shared','newly recruited'},'Box','off','location','best'); ylabel('% of cell types in replay'); ylim([0 0.85])

%%
nexttile;
img = imread(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps','LocalEvents_BoxPLotsS7.png'));
imshow(img);

nexttile;
img = imread(fullfile(opts.dataFolder,'NEW_TABLES','changingMaps','RemoteEvents_BoxPLotsS7.png'));
imshow(img);

end