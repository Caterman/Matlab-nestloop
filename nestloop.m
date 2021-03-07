function relationCell=nestloop2(times,vars,baseFunc,varargin)
%times   --最内层的循环,表示每种输入参数的原子baseFunc操作需要重复的次数，最少为1
%vars    --需要迭代的变量以及常量值，默认所有的数组都是需要遍历的，如果想传入一个数组常量，可以用{{}}包裹，
%          例如vars={[1 2 3],4,'var',{{[5 6]}}}  
%          表示只有一个迭代变量[1 2 3]，三个常量4,'var',[5 6]
%          默认最右侧的迭代变量是最内层的循环
%baseFunc --函数句柄，需要的最基本的原子操作，输入参数是vars
%           例如：
%           nestloop(10,{a,b,c},@base)
%           function res=base(vars)
%             [a,b,c]=distr(vars);
%           end
%varargin --其他参数
%           
    extravarslen=0;
    if nargin>=4
        extravars=varargin;
        extravarslen=length(extravars);
    end
    
%     saveDir='tmp/';
    saveinfo='saveinfo.info';
    extraFunc=struct('flag_publicBefore',false,...
                     'publicBefore',false,...
                     'flag_publicAfter',false,...
                     'publicAfter',false,...
                     'meetBreakPoint',false,...
                     'echo',true,...%实时显示循环进度
                     'flag_stepsave',false,...%是不是要阶段性保存，默认每次结束最外层循环，便算一个保存节点
                     'savename','./defaultSavename.mat',...%运行结果保存的文件名称
                     'flag_resume',false,...%是否使用上次的保存断点继续运行
                     'parallel',true,...;%是否使用并行计算，默认true
                     'times_choose',@mean);%最后的筛选准默认为mean

    if extravarslen>1
        for tagi = 1:2:(extravarslen-1)
            tag=extravars{tagi};
            if isequal(tag,'before')
                extraFunc.flag_publicBefore=true;
                extraFunc.publicBefore=extravars{tagi+1};
            elseif isequal(tag,'after')
                extraFunc.flag_publicAfter=after;
                extraFunc.publicAfter=extravars{tagi+1};
            elseif isequal(tag,'save')
                extraFunc.flag_stepsave=extravars{tagi+1};
            elseif isequal(tag,'savename')
                extraFunc.savename=extravars{tagi+1};
                extraFunc.flag_stepsave=true;
            elseif isequal(tag,'resume')
                extraFunc.flag_resume=extravars{tagi+1};
                extraFunc.flag_stepsave=extravars{tagi+1};
            elseif isequal(tag,'parallel')
                extraFunc.parallel=extravars{tagi+1};
            elseif isequal(tag,'choose')
%               筛选准则为自定义的
                extraFunc.times_choose=extravars{tagi+1};
            elseif isequal(tag,'echo')
                extraFunc.echo=extravars{tagi+1};
            end   
        end
    end
    %从左往右，需要循环的变量的索引，因为常量不需要索引
    %例如{1 [1 2 3] [4 5 5] 'ch'}
    %那么indexs_target=[2 3]
    indexs_target=[];
    varLen=length(vars);
    %cell const char vector
    for vi=1:varLen
        var=vars{vi}; 
        if isa(var,'cell')
            if length(var)==1
                %如果var只有一个成员
                %var={{const}}
                if length(var{1})==1
                    vars{vi}=var{1}{1};
                else
                    %var={loop_cell}
                    vars{vi}={var{1} [1 1 1] 'cell'};
                    indexs_target(end+1)=vi;
                end
            elseif length(var)>1
                if isa(var{1},'char')
                    vars{vi}={var [1 1 1] 'vector'};
                elseif ~isa(var{1},'cell')
                    %var={loop_vec}
                    vars{vi}{3}='vector';
                else
                    %var={loop_cell}
                    vars{vi}{3}='cell';
                end
                indexs_target(end+1)=vi;
            end 
        else
            if ~isa(var,'char')&&length(var)~=1 
                %var=vec
                vars{vi}={var [1 1 1] 'vector'};
                indexs_target(end+1)=vi;
            else
                %var=const num or const str
                 vars{vi}=var;
            end
        end
    end
    if extraFunc.flag_resume
        if exist(saveinfo,'file')
            fr = fopen(saveinfo,'r');
            savedTime_IndexSet=fscanf(fr,'%f');
            savedTime_IndexSet=savedTime_IndexSet(:)';
            fclose(fr);
            extraFunc.savedTime_IndexSet=savedTime_IndexSet;
        else
            print('not found the file : saveinfo.info,cannot resume');
        end
    end
    
    deep=1;
    nest_indexs=ones(1,varLen+1);
    others={indexs_target,saveinfo};
    [relationCell,~]=loop(times,vars,indexs_target,baseFunc,extraFunc,deep,nest_indexs,others);
    
    if extraFunc.flag_resume  
        relationCell=importdata(extraFunc.savename);
    end
%     if iscell(relationCell)
%         res=[];
%         if ~iscell(relationCell{1})
%             for i=1:len(relationCell)
%                 res(:,i)=relationCell{i};
%             end
%             relationCell=res;
%         end
%     end
end

function res=baseFuncInTimes(times,retlen,vars,baseFunc,nest_indexs,extraFunc)
    if extraFunc.echo
        print(str('at position ',nest_indexs));
    end
    res=zeros(times,retlen);
    vars_tmp={vars{1:end} nest_indexs};
    if extraFunc.parallel
        parfor t=1:times
            inner_baseFunc=baseFunc;
            vars_tmp_inner=vars_tmp;
            vars_tmp_inner{end}(end)=t;
            res(t,:)=inner_baseFunc(vars_tmp_inner);
        end
    else
        for t=1:times
            vars_tmp{end}(end)=t;
            res(t,:)=baseFunc(vars_tmp);
        end
    end
end

%%
function [relationCell,control_paras]=loop(times,vars,indexs_target,baseFunc,extraFunc,deep,nest_indexs,others)
    indexslen=length(indexs_target);
    [indexs_target_ori,~]=distr(others);
    index_var=indexs_target(1);
    var0=vars{index_var};
    [var,iocfg,type]=distr(var0);
    %窗口长度，步长，返回值长度
    [winlen,step,retlen]=distr(iocfg);
    varlen=length(var);
    time_loop=1+floor((varlen-winlen)/step);
    
    
    if isequal(type,'vector')
        if indexslen==1
            relationCell=zeros(time_loop,retlen);
            if times==1 && extraFunc.parallel
                parfor tl =1:time_loop
                    extraFunc_tmp=extraFunc;
                    if extraFunc_tmp.flag_resume && ~extraFunc_tmp.meetBreakPoint
                        if tl<extraFunc_tmp.savedTime_IndexSet(index_var)
                            continue
                        elseif tl==extraFunc_tmp.savedTime_IndexSet(index_var)
                            extraFunc_tmp.meetBreakPoint=1;
                            continue
                        end
                    end
                    
                    var_tmp=var;
                    vec_in=var_tmp((1:winlen)+(tl-1)*step);
                    vars_tmp=vars;
                    vars_tmp{index_var}=vec_in;
                    nest_indexs_tmp=nest_indexs;
                    nest_indexs_tmp(index_var)=tl;
                    res=baseFuncInTimes(times,retlen,vars_tmp,baseFunc,nest_indexs_tmp,extraFunc_tmp);
                    inner_times_choose=extraFunc_tmp.times_choose;
                    res=inner_times_choose(res);
                    relationCell(tl,:)=res;
                    if extraFunc_tmp.flag_stepsave
                        saveloop(res,nest_indexs_tmp,extraFunc_tmp,others);
                    end
                end
                control_paras=[extraFunc];
                return
            end
            for tl =1:time_loop
                extraFunc_tmp=extraFunc;
                if extraFunc_tmp.flag_resume && ~extraFunc.meetBreakPoint
                    if tl<extraFunc.savedTime_IndexSet(index_var)
                        continue
                    elseif tl==extraFunc.savedTime_IndexSet(index_var)
                        extraFunc.meetBreakPoint=1;
                        continue
                    end
                end   
  
                var_tmp=var;
                vec_in=var_tmp((1:winlen)+(tl-1)*step);
                vars_tmp=vars;
                vars_tmp{index_var}=vec_in;
                nest_indexs_tmp=nest_indexs;
                nest_indexs_tmp(index_var)=tl;
                res=baseFuncInTimes(times,retlen,vars_tmp,baseFunc,nest_indexs_tmp,extraFunc_tmp);
                inner_times_choose=extraFunc_tmp.times_choose;
                res=inner_times_choose(res);
                relationCell(tl,:)=res;
                if extraFunc_tmp.flag_stepsave
                    saveloop(res,nest_indexs_tmp,extraFunc_tmp,others);
                end
            end
            control_paras=[extraFunc];
            return
        end
        
        relationCell=cell(1,time_loop);
        indexs_target(1)=[];
        for tl =1:time_loop
            if extraFunc.flag_resume && ~extraFunc.meetBreakPoint 
                if tl<extraFunc.savedTime_IndexSet(index_var)
                    continue
                end
            end 

            var_tmp=var;
            vec_in=var_tmp((1:winlen)+(tl-1)*step);
            vars_tmp=vars;
            vars_tmp{index_var}=vec_in;
            nest_indexs_tmp=nest_indexs;
            nest_indexs_tmp(index_var)=tl;
            [relationCell{tl},control_paras]=loop(times,vars_tmp,indexs_target,baseFunc,extraFunc,deep+1,nest_indexs_tmp,others);
            extraFunc=distr(control_paras);
        end
        
    else
        if indexslen==1
            relationCell=zeros(time_loop,retlen);
            parfor tl =1:time_loop    
                extraFunc_tmp=extraFunc;
                range=(1:winlen)+(tl-1)*step;
                var_tmp=var;
                if len(range)==1
                    vec_in=var_tmp{range(1)};
                else
                    vec_in=cell(1,length(range));
                    for veci=1:length(range)
                        vi=range(veci);
                        vec_in{veci}=var_tmp{vi};
                    end
                end
                vars_tmp=vars;
                vars_tmp{index_var}=vec_in;
                res=baseFuncInTimes(times,retlen,vars_tmp,baseFunc);
                inner_times_choose=extraFunc_tmp.times_choose;
                res=inner_times_choose(res);
                relationCell(tl,:)=res; 
            end
            return
        end
        
        relationCell=cell(1,time_loop);
        indexs_target(1)=[];
        parfor tl =1:time_loop            
            var_tmp=var;
            range=(1:winlen)+(tl-1)*step;
            if len(range)==1
                vec_in=var_tmp{range(1)};
            else
                vec_in=cell(1,length(range));
                for veci=1:length(range)
                    vi=range(veci);
                    vec_in{veci}=var_tmp{vi};
                end
            end
            vars_tmp=vars;
            vars_tmp{index_var}=vec_in;
            relationCell{tl}=loop(times,vars_tmp,indexs_target,baseFunc,times_choose);
        end
    end
end

function saveloop(var,nest_indexs,extraFunc,others)
    [indexs_target_ori,saveinfo]=distr(others);
    
    savename=extraFunc.savename;
    if ~exist(savename,'file')
        data_import={};
    else
        data_import=importdata(savename);
    end

    indexs=nest_indexs(indexs_target_ori);
    data_import=setDeepVal(data_import,indexs,var);
    save(extraFunc.savename,'data_import');
    
    fw = fopen(saveinfo,'w');
    fprintf(fw,'%d ',nest_indexs);
    fclose(fw);
end

