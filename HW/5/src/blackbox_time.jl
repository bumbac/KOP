using PlotlyJS
using Statistics
using BenchmarkTools

include("../src/sat.jl")
include("../../2/src/file_loader.jl")
#A = "../data/wuf-A1/wuf20-88-A1"
A = "../data/wuf-A1/wuf20-91-A1"
A_sol = "../data/wuf-A1/wuf20-91-A-opt.dat"
Q = "../data/wuf-Q1/wuf50-201-Q1"
Q_sol = "../data/wuf-Q1/wuf50-201-Q-opt.dat"
M = "../data/wuf-M1/wuf50-201-M1"
M_sol = "../data/wuf-M1/wuf50-201-M-opt.dat"
N = "../data/wuf-N1/wuf50-201-N1"
N_sol = "../data/wuf-N1/wuf50-201-N-opt.dat"
R = "../data/wuf-R1/wuf50-201-R1"
R_sol = "../data/wuf-R1/wuf50-201-R-opt.dat"

names = [(A, A_sol, "A"), (M, M_sol, "M"), (N, N_sol, "N"), (R, R_sol, "R")]
d=Dict()

for problem in names
   d[problem[3]] = [] 
end

attempts = 3

for problem in names
    println(problem[3])
    cnt = 1
    instances = readFileSat(problem[1])
    tt = []
    for instance in instances[1:100]
        println(instance[5])
        absolute = 0
        steps = 0
        t = 0
        for i in 1:attempts
            tm = @elapsed profit, a, y, sss, n_r = sa(instance)
            t += tm
        end
        push!(tt, t / attempts)
        println(cnt)
        cnt += 1
    end
    push!(d[problem[3]], tt)
end
x = []

histx = []
for a in keys(d)
    push!(x, scatter(y=d[a][1], name=a))
    push!(histx, histogram(x=d[a][1], name=a, opacity=1.0))
end

display(plot([p for p in x], Layout(title="Average computation time (3 repeats), automatic parameters.", xaxis_title="instance", yaxis_title="seconds")))


display(plot([p for p in histx], Layout(title="Average comp. time (3 repeats), automatic parameters.")))

