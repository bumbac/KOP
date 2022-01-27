using PlotlyJS
using Statistics
using BenchmarkTools

include("../src/sat.jl")
include("../../2/src/file_loader.jl")
A = "/home/servermatej/Downloads/ni-kop-master/HW/5/data/wuf-A1/wuf100-430-A1"
A_sol = "../data/wuf-A1/wuf20-88-A-opt.dat"
Q = "/home/servermatej/Downloads/ni-kop-master/HW/5/data/wuf-Q1/wuf75-310-Q1"
Q_sol = "../data/wuf-Q1/wuf20-78-Q-opt.dat"
M = "/home/servermatej/Downloads/ni-kop-master/HW/5/data/wuf-M1/wuf75-310-M1"
M_sol = "../data/wuf-M1/wuf20-78-M-opt.dat"
N = "/home/servermatej/Downloads/ni-kop-master/HW/5/data/wuf-N1/wuf75-310-N1"
N_sol = "../data/wuf-N1/wuf20-78-N-opt.dat"
R = "/home/servermatej/Downloads/ni-kop-master/HW/5/data/wuf-R1/wuf75-310-R1"
R_sol = "../data/wuf-R1/wuf20-78-R-opt.dat"

names = [(A, A_sol, "A"), (Q, Q_sol, "Q"), (M, M_sol, "M"), (N, N_sol, "N"), (R, R_sol, "R")]
d=Dict()
s=Dict()
for problem in names
   d[problem[3]] = [] 
   s[problem[3]] = [] 
end

attempts = 3

for problem in names
    cnt = 1
    instances = readFileSat(problem[1])
    err = []
    steps_arr = []
    println(problem[3])
    for instance in instances[1:10]
        absolute = 0
        steps = 0
        for i in 1:attempts
            profit, a, y, h, n_r = sa(instance)
            absolute += profit
            steps += h
        end
        absolute = absolute / attempts
        push!(err, absolute)    
        push!(steps_arr, steps//attempts)
        println(cnt)
        cnt += 1
    end
    push!(d[problem[3]], err)
    push!(s[problem[3]], steps_arr)
end
x = []
z = []
histx = []
histz = []
for a in keys(d)
    push!(x, scatter(y=d[a][1], name=a))
    push!(histx, histogram(x=d[a][1], name=a))
end
for a in keys(s)
    push!(z, scatter(y=s[a][1], name=a))
    push!(histz, histogram(x=s[a][1], name=a))
end
display(plot([p for p in x], Layout(title="Average error using automatic parameters.", xaxis_title="instance", yaxis_title="relative error to optimum")))

display(plot([p for p in z], Layout(title="N. of iterations using automatic parameters.", xaxis_title="instance", yaxis_title="# iterations")))

display(plot([p for p in histx], Layout(title="Average error using automatic parameters.")))

display(plot([p for p in histz], Layout(title="Average #iterations using automatic parameters.")))
