function plotDataEmmeansContrasts(TRACKS,data,opts,path_to_emm_csv,path_to_ctrst_csv,varargin)

p=inputParser;
addParameter(p,'plot_individual',0);
addParameter(p,'plot_emmeans',0);
addParameter(p,'plot_sig',0);
addParameter(p,'REW_outerShift',[-0.4 0.4]);
addParameter(p,'REW_innerShift',[-0.2 0.2]);
parse(p,varargin{:});

warning('off');

rats= opts.rats;
replay_rats= opts.replay_rats;
Mrks= opts.Mrks;
cdata_rew= opts.cdata_rew;
REW= opts.REW;

REW_outerShift= p.Results.REW_outerShift;
REW_innerShift= p.Results.REW_innerShift;
TRACK_shift= 1:2:6;
if p.Results.plot_individual
    for thisT=1:3
        for thisR=1:2
            swarmchart(repmat(TRACK_shift(thisT)+REW_outerShift(thisR),1,length(data(TRACKS.track == thisT & TRACKS.reward == REW(thisR)))),...
                data(TRACKS.track == thisT & TRACKS.reward == REW(thisR)),10,cdata_rew{thisR}, ...
                'filled','XJitterWidth',0.1,'MarkerFaceAlpha',0.8,'SizeData',35);
        end
    end
end
xlim([-1 7]); xticks(TRACK_shift); xticklabels({'T1','T2','T3'}); 
for thisRat=1:length(rats)
    for thisT=1:3
        if ismember(rats{thisRat},replay_rats)
            plot(TRACK_shift(thisT)+REW_innerShift,...
                arrayfun(@(x) mean(data(TRACKS.track == thisT & TRACKS.reward == REW(x) & TRACKS.rat== string(rats{thisRat}))),1:2),...
                'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k',...
                'MarkerFaceColor',[0.5 0.5 0.5])
        else
            plot(TRACK_shift(thisT)+REW_innerShift,...
                arrayfun(@(x) mean(data(TRACKS.track == thisT & TRACKS.reward == REW(x) & TRACKS.rat== string(rats{thisRat}))),1:2),...
                'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker',Mrks{thisRat},'MarkerSize',7,'MarkerEdgeColor','k', ...
                'MarkerFaceColor','w')
        end
    end
end

if ~isempty(path_to_emm_csv)
    T_emm= readtable(path_to_emm_csv);
    T_con= readtable(path_to_ctrst_csv);

    % add emmeans
    emm=[];
    for thisT=1:3
        emm(thisT,:)= arrayfun(@(x) T_emm.emmean(T_emm.track==thisT & T_emm.reward==REW(x),:),1:2);
        if p.Results.plot_emmeans
            plot(TRACK_shift(thisT)+REW_innerShift,emm(thisT,:),'Color',[0 0.5 0 0.5],'LineWidth',3);
        end
    end
    
    if p.Results.plot_sig
        % add significance
        maxD= max(data);
        max_emm= max(emm,[],2);
        con_x= [1 5; 1 3; 1 5; 3 5; ... % main effects
            1+REW_innerShift; 3+REW_innerShift; 5+REW_innerShift;... % simple effects
            1 3; 1 5; 3 5]; % interactions
        con_y= [1.2*maxD.*[1 1; 0.95 0.95; 0.9 0.9; 0.95 0.95];...
            repmat(1.1.* max_emm,1,2);...
            repmat(mean([1.1.* max_emm   1.2*repmat(maxD,3,1)],2),1,2)];
        
        
        % remove unecessary speed and lap number effects from the plot (put in text)
        T_con(contains(T_con.label,'speed') | contains(T_con.label,'lap'),:)= []; % otherwise messes up con_x and con_y..
        sigIdx= find(T_con.p_value <= T_con.alpha);
        for ii=1:length(sigIdx)
            plot(con_x(sigIdx(ii),:),con_y(sigIdx(ii),:),'k');
            if ismember(sigIdx(ii),[1:4,8:10])
                text(0.7*mean(con_x(sigIdx(ii),:)),1.05*mean(con_y(sigIdx(ii),:)),[T_con.label{sigIdx(ii)} ' *']);
            else
                text(mean(con_x(sigIdx(ii),:)),1.1*mean(con_y(sigIdx(ii),:)),'*','FontSize',16,'FontWeight','bold');
            end
        end
    end

end

xlim([-0.14 6.2]);
warning('on');

end