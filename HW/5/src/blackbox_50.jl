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

names = [(A, A_sol, "A"), (Q, Q_sol, "Q"), (M, M_sol, "M"), (N, N_sol, "N"), (R, R_sol, "R")]
d=Dict()
s=Dict()
k=Dict()
for problem in names
   d[problem[3]] = [] 
   s[problem[3]] = [] 
   k[problem[3]] = [] 
end

attempts = 3
for problem in names
    inst_cnt = 30
    println(problem[3])
    cnt = 1
    instances = readFileSat(problem[1])
    solutions = readSolutionSat(problem[2])
    err = []
    steps_arr = []
    tt = []
    for instance in instances
	if instance[5] in keys(solutions) && inst_cnt > 0
		inst_cnt -= 1
    	else
    		continue
	end
        println(instance[5])
        sol = solutions[instance[5]]
        absolute = 0
        steps = 0
        t = 0
        for i in 1:attempts
            tm = @elapsed profit, a, e, sss, n_r = sa(instance)
            absolute += a
            steps += sss
            t += tm
        end
        absolute = absolute / attempts
        push!(err, 1 - absolute/sol)    
        push!(steps_arr, steps/attempts)
        push!(tt, t/ attempts)
        println(cnt)
        cnt += 1
    end
    push!(d[problem[3]], err)
    push!(s[problem[3]], steps_arr)
    push!(k[problem[3]], tt)
end
x = []
z = []
histx = []
histz = []
histh = []
for a in keys(d)
    push!(x, scatter(y=d[a][1], name=a))
    push!(histx, histogram(x=d[a][1], name=a, opacity=1.0))
end
for a in keys(s)
    push!(z, scatter(y=s[a][1], name=a))
    push!(histz, histogram(x=s[a][1], name=a, opacity=1.0))
end
for a in keys(h)
    push!(histh, histogram(x=k[a][1], name=a, opacity=1.0))
end
display(plot([p for p in x], Layout(title="Average error using automatic parameters.", xaxis_title="instance", yaxis_title="relative error to optimum")))

display(plot([p for p in z], Layout(title="N. of iterations using automatic parameters.", xaxis_title="instance", yaxis_title="# iterations")))

display(plot([p for p in histx], Layout(title="Average error using automatic parameters.")))

display(plot([p for p in histz], Layout(title="Average #iterations using automatic parameters.")))

display(plot([p for p in histh], Layout(title="Average computation time using automatic parameters.")))
