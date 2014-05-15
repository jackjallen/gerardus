%% OPTI Toolbox Linear Program Demo
%
% This file contains a number of LP problems and demonstrates how to solve
% them using the OPTI Toolbox. You must complete Basic_demo.m before
% running this demo!
%
%   Copyright (C) 2011 Jonathan Currie (I2C2)

%% Problem 1
% This is a simple two decision variable LP which will use for the next few
% examples

%Problem
f = -[6 5]';                %Objective Function (min f'x)
A = [1,4; 6,4; 2, -5];      %Linear Inequality Constraints (Ax <= b)
b = [16;28;6];    
lb = [0;0];                 %Bounds on x (lb <= x <= ub)
ub = [10;10];

%% Example 1 - Basic Setup
% Problems are built using the opti constructor:

Opt = opti('f',f,'ineq',A,b,'bounds',lb,ub)

%% Example 1 - Solving the Problem
%Call solve to solve the problem

[x,fval,exitflag,info] = solve(Opt)   

%% Problem 2
% Another simple example with three decision variables.

%Problem
f = -[1 2 3]';
A = [-1,1,1; 1,-3,1];
b = [20,30]';
Aeq = [1 1 1];
beq = 40;
lb = [0;0;0];
ub = [40;inf;inf];

%% Example 2 - Mixed Constraints
% There are multiple ways to enter linear constraints. This includes by
% groups such as inequalities and equalities (1), as row linear constraints
% (2), mixed constraints (3) or individually (4)

% 1)
Opt = opti('f',f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub); 

% 2)
Ar = [A;Aeq];
rl = [-Inf(size(b));beq];
ru = [b;beq];
Opt = opti('f',f,'lin',Ar,rl,ru,'bounds',lb,ub);

% 3)
Amix = [A;Aeq]; 
bmix = [b;beq];
e = [-1;-1;0];  %specify via constraint type vector (-1 <=, 0 ==, 1 >=)
Opt = opti('f',f,'mix',Amix,bmix,e,'bounds',lb,ub);

% 4)
Opt = opti('f',f,'A',A,'b',b,'Aeq',Aeq,'beq',beq,'bounds',lb,ub); 

%% Example 3 - Maximization
% You can use the 'sense' option to change between minimization and
% maximization. Use sense = -1 for maximization, 1 for minimization.

fmax = -f; %identical but with inverted sign for this example

Opt = opti('f',fmax,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'sense',-1)

x = solve(Opt)

%% Example 4 - Calling a Solver Directly
% You can skip calling using the OPTI class altogether and call the solvers
% directly if required. Each solver has a function called opti_solver, and
% is documented as follows:

help opti_clp

[x,fval,exitflag,info] = opti_clp([],f,Ar,rl,ru,lb,ub)

%% Problem 3
% A larger sparse LP for the next few examples

load sparseLP1;

%% Example 5 - Sparse LPs
% All solvers are setup to directly solve sparse systems, which is the
% preferred format for most solvers:

opts = optiset('solver','glpk'); %Solve with GLPK
Opt = opti('f',f,'ineq',A,b,'eq',Aeq,beq,'options',opts);
[x,fval,exitflag,info] = solve(Opt);
fval
info

%% Example 6 - Using the Optimization Toolbox
% If you have the MATLAB optimization toolbox you can also solve OPTI
% problems using it:

opts = optiset('solver','matlab');
Opt = opti(Opt,opts)
[x,fval,exitflag,info] = solve(Opt);
fval
info

