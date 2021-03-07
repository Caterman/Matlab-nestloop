# Matlab-nestloop
a tool used for transforming several loops to a function which is only needed to input the range of loop variables

## 中文介绍 

是不是经常遇到，需要写许多个for循环，每一层for循环都要记录中间的结果，光是中间结果的变量名称都容易记混。   

有时仅仅考虑某两个循环变量的关系时，又需要注释掉其他的for循环，导致代码改来改去。   

有时候想用parfor做并行计算，但是由于循环体内公用了一些变量，使得无法使用parfor。    

有时候循环时候很长，但是想记录循环的位置，临时保存结果，下次可以断点继续。     

这些都可以通过nestloop这个函数实现啦！！     


### relationCell=nestloop2(times,vars,baseFunc,varargin) 
### times   --最内层的循环,表示每种输入参数的原子baseFunc操作需要重复的次数，最少为1 
### vars    --需要迭代的变量以及常量值，默认所有的数组都是需要遍历的，如果想传入一个数组常量，可以用{{}}包裹， 
#### 例如
         vars={[1 2 3],4,'var',{{[5 6]}}} 
         表示只有一个迭代变量[1 2 3]，三个常量4,'var',[5 6] 
         默认最右侧的迭代变量是最内层的循环 
### baseFunc --函数句柄，需要的最基本的原子操作，输入参数是vars 
#### 例如： 
           nestloop(10,{a,b,c},@base) 
           function res=base(vars) 
             [a,b,c]=distr(vars); 
           end 
### varargin --其他控制参数 

