function res=setDeepVal(obj,indexs,val)
        deep=1;
        res=baseSetDeepVal(obj,indexs,deep,val);
end

function obj=baseSetDeepVal(obj,indexs,deep,val)
        if deep==length(indexs)
            if isa(obj,'array')
                obj(indexs(deep))=val;
            else
                obj{indexs(deep)}=val;
            end
            return
        end
        
%         obj_len=length(obj);
        while length(obj)<indexs(deep)
            obj{end+1}={};
        end

        res=baseSetDeepVal(obj{indexs(deep)},indexs,deep+1,val);
        obj{indexs(deep)}=res;
end