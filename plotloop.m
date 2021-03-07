function plotloop(varargin)
%输入格式：
% 当只有1个输入时，{relationCell}
%   可以是一个元胞包含多条数据，例如{f1(xrange),f2(xrange)... }
% 当有2个输入时，{xrange,relationCell}
%   xrange是画图的x坐标区间
% 当有3个输入时，{xrange,legends,relationCell}
%   legends是每条曲线对应的属性值，也就是图注
% 当有4个输入时，{xrange,label,labelrange,relationCell}
%   label是在图注上显示的，数据前的标注
%   labelrange是每条曲线对应的属性值，也就是在图注后的数字

    legendtext={};
    xrange=[];
    labelrange=[];
    label='';
    if nargin==1
        relationCell=varargin{1};
        if isa(relationCell,'cell')
            for ci=1:length(relationCell)
                legendtext{ci}=str(ci);     
            end
            legend(legendtext);
        end
        
        plot(relationCell);
        return
    elseif nargin==2
        xrange=varargin{1};
        relationCell=varargin{2};
        if isa(relationCell,'cell')
            for ci=1:length(relationCell)
                legendtext{ci}=str(ci);     
            end
        end
    elseif nargin==3
        xrange=varargin{1};
        labelrange=varargin{2};
        relationCell=varargin{3};
        if isa(labelrange,'cell')
            legendtext=labelrange;
        else
            if isa(relationCell,'cell')
                for ci=1:length(relationCell)
                    legendtext{ci}=str(labelrange(ci));
                end
            end
        end
    elseif nargin==4
        xrange=varargin{1};
        label=varargin{2};
        labelrange=varargin{3};
        relationCell=varargin{4};
        if isa(relationCell,'cell')
            for ci=1:length(relationCell)
                legendtext{ci}=str({label ': ' labelrange(ci)});
            end
        else
            for ci=1:size(relationCell,2)
                legendtext{ci}=str({label  labelrange(ci)});
            end
        end
    end
    
    if isa(relationCell,'cell')
    elseif isempty(legendtext)
        if isempty(xrange)
            xrange=1:size(relationCell,1);
        end
        if isempty(labelrange) && isempty(label)
            for ci=1:size(relationCell,2)
                legendtext{ci}=str(ci);
            end
        else
            if isa(labelrange,'cell')
                legendtext=labelrange;
            else
                for ci=1:length(labelrange)
                    legendtext{ci}=str(labelrange(ci));
                end
            end
        end
    end
    plotBase(relationCell,xrange,legendtext);
    
    hold off
end

function plotBase(relationCell,xrange,legendtext)
        if isa(relationCell,'cell')
            for ci=1:length(relationCell)
                plot(xrange,relationCell{ci}(:,1));
                hold on
            end
            legend(legendtext);
        else
            for ci=1:size(relationCell,2)
                plot(xrange,relationCell(:,ci));
                hold on
            end
            legend(legendtext);
        end
end
