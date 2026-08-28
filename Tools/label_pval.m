function label_pval(axeh,x,y,pval,varargin)
% axeh,x,y,pval,varargin
% input 'short' for varargin
p= inputParser;
addParameter(p,'FontSize',12);
addParameter(p,'short',0);
parse(p,varargin{:});
FontSize= p.Results.FontSize;
short= p.Results.short;

if pval >= 0.06
    text(axeh,x,y,'n.s','Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
elseif pval > 0.05 && pval <= 0.06
    if isempty(varargin)
        text(axeh,x,y,['n.s, p= ' num2str(pval,2)],'Color','k','FontWeight','normal','FontName','Arial','FontSize',12);
    else
         text(axeh,x,y,num2str(pval,2),'Color','k','FontWeight','normal','FontName','Arial','FontSize',9);
    end
elseif pval<0.05 && pval>0.01
    if ~short
        text(axeh,x,y,['*, p= ' num2str(pval,2)],'Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    else
         text(axeh,x,y,'*','Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    end
elseif pval<0.01 && pval>0.001
     if ~short
        text(axeh,x,y,['**, p= ' num2str(pval,2)],'Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    else
         text(axeh,x,y,'**','Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    end
elseif pval<0.001
     if ~short
        text(axeh,x,y,'***, p < 0.001 ','Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    else
         text(axeh,x,y,'***','Color','k','FontWeight','normal','FontName','Arial','FontSize',FontSize);
    end
end

end