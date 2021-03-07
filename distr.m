function varargout =distr(args)
    if isa(args,'cell')
        for i=1:nargout
            varargout{i}=args{i};
        end
    else
        for i=1:nargout
            varargout{i}=args(i);
        end
    end

end