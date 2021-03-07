function s=str(varargin)
    s=[];
    if nargin==1
        if isequal( class(varargin{1}),'cell')
            varargin=varargin{1};
        end
    end
    for i=1:(length(varargin))
        var=varargin{i};
        if isequal( class(var),'double')
            s=[s mat2str(var)];

        elseif isequal( class(var),'char')
                s=[s var];
        end
    end
end
