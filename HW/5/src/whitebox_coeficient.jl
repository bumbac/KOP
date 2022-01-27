using PlotlyJS
using Statistics
using BenchmarkTools

include("../src/sat.jl")
include("../../2/src/file_loader.jl")
A = "../data/wuf-A1/wuf20-88-A1"
A_sol = "../data/wuf-A1/wuf20-88-A-opt.dat"
Q = "../data/wuf-Q1/wuf20-78-Q1"
Q_sol = "../data/wuf-Q1/wuf20-78-Q-opt.dat"
M = "../data/wuf-M1/wuf20-78-M1"
M_sol = "../data/wuf-M1/wuf20-78-M-opt.dat"
N = "../data/wuf-N1/wuf20-78-N1"
N_sol = "../data/wuf-N1/wuf20-78-N-opt.dat"
R = "../data/wuf-R1/wuf20-78-R1"
R_sol = "../data/wuf-R1/wuf20-78-R-opt.dat"

names = [(A, A_sol, "A"), (Q, Q_sol, "Q"), (M, M_sol, "M"), (N, N_sol, "N"), (R, R_sol, "R")]
d=Dict()
s=Dict()
for problem in names
   d[problem[3]] = [] 
   s[problem[3]] = [] 
end
f = [0.995, 0.99, 0.95, 0.9, 0.85, 0.8]
attempts = 3
for c in f
    cnt = 1
    println("coeficient ", c)
    for problem in names
        println(problem[3])
        instances = readFileSat(problem[1])
        solutions = readSolutionSat(problem[2])
        err = []
        steps_arr = []
        for instance in instances[1:1]
            sol = solutions[instance[5]]
            absolute = 0
            steps = 0
	        for i in 1:attempts
	            profit, a, y, h, n_r = sa(instance, cooling_factor=c)
	            absolute += a
	            steps += h
            end
            absolute = absolute / attempts
            push!(err, 1 - absolute/sol)    
            push!(steps_arr, steps//attempts)
            println(cnt)
            cnt += 1
        end
        push!(d[problem[3]], mean(err))
        push!(s[problem[3]], mean(steps_arr))
    end
end
x = []
z = []
for a in keys(d)
    push!(x, scatter(x=f, y=d[a], name=a))
end
for a in keys(s)
    push!(z, scatter(x=f, y=s[a], name=a))
end
display(plot([p for p in x], Layout(title="Error based on cooling coeficient.", xaxis_title="cooling coeficient", yaxis_title="error")))

display(plot([p for p in z], Layout(title="N. of iterations based on cooling coeficient.", xaxis_title="cooling coeficient", yaxis_title="# iterations")))
