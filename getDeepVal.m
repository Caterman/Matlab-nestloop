function part=getDeepVal(obj,indexs)
    part =obj;
    for index =indexs
        if iscell(part)
            part=part{index};
        else
            part=part(index);
        end
    end
end