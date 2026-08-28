function pretty_boxplot(data,varargin)
% e.g. pretty_boxplot(data,group (optional),{cell array of colours} (optional),positions (optional))

% data as you would put in a normal boxplot
% input matrix, each column is a group
% or vector for data, and group
% on top of data and/or group can specify a list of colours
marker_size= 18;
marker_alpha= 0.7;
line_width=1;

p = inputParser;
% validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0); %
% example from matlab
addRequired(p,'data',@ismatrix);
if min(size(data))>1
    default_group= ones(size(data)).*[1:size(data,2)];
    data= data(:); 
    default_group= default_group(:);
else
    default_group= ones(size(data));
end
addParameter(p,'group',default_group,@ismatrix);
addParameter(p,'marker_size',marker_size,@isnumeric);
addParameter(p,'marker_alpha',marker_alpha,@isnumeric);
addParameter(p,'marker','o');
addParameter(p,'line_width',line_width,@ismatrix);
addParameter(p,'disp_quantiles',true,@islogical);
addParameter(p,'cdata',repmat({[0.5 0.5 0.5]},1,length(unique(default_group))),@(x) iscell(x));
addParameter(p,'positions',[1:length(unique(default_group))],@ismatrix);
addParameter(p,'box_width',0.8,@ismatrix);
addParameter(p,'lStyle',{},@(x) iscell(x));
parse(p,data,varargin{:});

data= p.Results.data;
group= p.Results.group;
marker_size= p.Results.marker_size;
marker_alpha= p.Results.marker_alpha;
marker= p.Results.marker;
line_width= p.Results.line_width;
cdata= p.Results.cdata;
lStyle= p.Results.lStyle;
disp_quantiles= p.Results.disp_quantiles;
positions= p.Results.positions;
if ~contains('group',p.UsingDefaults) && contains('cdata',p.UsingDefaults)
    cdata= repmat({[0.5 0.5 0.5]},1,length(unique(p.Results.group)));
% elseif contains('group',p.UsingDefaults) && ~contains('cdata',p.UsingDefaults)
%     cdata= repmat(cdata(1),1,length(unique(p.Results.group)));
end
if ~contains('group',p.UsingDefaults) && contains('positions',p.UsingDefaults)
    positions= [1:length(unique(p.Results.group))];
%         positions= unique(group);
end
if isempty(lStyle)
    lStyle= repmat({'-'},1,length(cdata));
end

start_idx= length(unique(group));

hold on;
avail_groups= unique(group);
avail_colors= unique(cell2mat(cdata),'rows');
if size(avail_colors,1)>length(avail_groups)
    for j=1:length(avail_groups)
            scatter(positions(j)+(0.8*p.Results.box_width*rand(size(data(group==avail_groups(j))))-0.4*p.Results.box_width),...
                data(group==avail_groups(j)),...
                marker_size,vertcat(cdata{group==avail_groups(j)}(1:3)),'filled',...
                'MarkerFaceAlpha',marker_alpha,'MarkerEdgeAlpha',0,'Marker',marker); hold on;
    end
else
    for j=1:length(avail_groups)
            scatter(positions(j)+(0.8*p.Results.box_width*rand(size(data(group==avail_groups(j))))-0.4*p.Results.box_width),data(group==avail_groups(j)),...
            marker_size,[cdata{j}(1:3)],'filled',...
            'MarkerFaceAlpha',marker_alpha,'MarkerEdgeAlpha',0,'Marker',marker); hold on;
    end
end
boxplot(data,group,'Positions',positions,'Widths',p.Results.box_width');

% recolour the boxes and median etc as you wish
a= get(get(gca,'Children'),'children');
a= a{1};
for i=1:length(unique(group))
    set(a(i),'Visible','off'); % does outliers first
    if ~disp_quantiles
        set(a([3,4,5,6]*start_idx+i),'Visible','off'); % do not display quantiles
    end
    set(a(start_idx+i),'Color','k','LineWidth',max(0.5,0.5*line_width)) % then medians
    if size(cdata{1},1)>1
        set(a(2*start_idx+i),'Color','k','LineWidth',line_width); % then boxes
    else
        set(a(2*start_idx+i),'Color',cdata{length(cdata)-i+1},'LineWidth',1.5,'LineStyle',lStyle{length(cdata)-i+1}); %
    end
end

%%% OLD VERSION
% if length(varargin)==1 % data only
%     data= varargin{1};
%     arrayfun(@(x) scatter(x+(0.2*rand(size(data(:,x)))-0.1),data(:,x),marker_size,'MarkerFaceColor',[0.5 0.5 0.5],...
%                 'MarkerFaceAlpha',marker_alpha,'MarkerEdgeAlpha',0),1:size(data,2)); 
%     boxplot(varargin{1});
% elseif length(varargin)>1 
%     if length(varargin{1})== length(varargin{2}) % data and group    
%         data= varargin{1};
%         group= varargin{2};
%         positions= [1:length(unique(group))];
%         if length(varargin)==2 % no colour specified
%             cdata= repmat({[0.5 0.5 0.5]},1,length(unique(group)));
%         else % 3 or 4 arguments
%             if iscell(varargin{3}) % colour
%                 cdata= varargin{3};
%             elseif ~iscell(varargin{3}) % positions
%                 positions= varargin{3};
%             end
%             if length(varargin)==4
%                 positions= varargin{4};
%             end
%         end
%         for j=1:length(unique(group))
%             scatter(positions(j)+(0.2*rand(size(data(group==j)))-0.1),data(group==j),marker_size,'MarkerFaceColor',[cdata{j}],...
%                 'MarkerFaceAlpha',marker_alpha,'MarkerEdgeAlpha',0); hold on;
%         end
%         boxplot(data,group,'Positions',positions);
%         start_idx=length(cdata);
%     else % data and colour
%         data= varargin{1};
%         positions= [1:size(data,2)];
%         if ~iscell(varargin{2}) % position specified, not colour
%             cdata= repmat({[0.5 0.5 0.5]},1,length(unique(group)));
%         else
%              cdata= varargin{2};
%         end
%         if length(varargin)==3
%                 positions= varargin{3};
%         end
%         arrayfun(@(x) scatter(positions(x)+(0.2*rand(size(data(:,x)))-0.1),data(:,x),marker_size,'MarkerFaceColor',[cdata{x}],...
%                 'MarkerFaceAlpha',marker_alpha,'MarkerEdgeAlpha',0),1:size(data,2)); 
%          boxplot(data,'Positions',positions);
%          start_idx=length(cdata);
%     end
% end
% 
% % recolour the boxes and median etc as you wish
%     a= get(get(gca,'Children'),'children');
%     a= a{1};
%     if length(varargin)>1
%         for i=1:start_idx
%             set(a(i),'Visible','off'); % does outliers first
%             set(a(start_idx+i),'Color','k','LineWidth',1) % then medians
%             if length(varargin)==2  && length(varargin{1})~= length(varargin{2}) ||...  % data and colour
%                 length(varargin)>2 % data, group, colour
%                     set(a(2*start_idx+i),'Color',cdata{length(cdata)-i+1},'LineWidth',2); % then boxes
%                 
%             end
%         end
%     end


end