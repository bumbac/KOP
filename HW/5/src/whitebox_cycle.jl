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
values = 1:2:11
attempts = 3
for alpha in values
    cnt = 1
    println("Alpha ", alpha)
    for problem in names
        instances = readFileSat(problem[1])
        solutions = readSolutionSat(problem[2])
        alpha_err = []
        steps_arr = []
        for instance in instances[1:100]
            sol = solutions[instance[5]]
            absolute = 0
            steps = 0
            for i in 1:attempts
	            profit, a, y, h, n_r = sa(instance, inner_cycle_alpha=alpha*0.1)
	            absolute += a
	            steps += h
            end
            absolute = absolute / attempts
            push!(alpha_err, 1 - absolute/sol)    
            push!(steps_arr, steps//attempts)
            println(cnt)
            cnt += 1
        end
        push!(d[problem[3]], mean(alpha_err))
        push!(s[problem[3]], mean(steps_arr))
    end
end
x = []
z = []
for a in keys(d)
    push!(x, scatter(x=[0.1*a for a in values], y=d[a], name=a))
end
for a in keys(s)
    push!(z, scatter(x=[0.1*a for a in values], y=s[a], name=a))
end
display(plot([p for p in x], Layout(title="Error based on inner cycle alpha.", xaxis_title="alpha", yaxis_title="error")))

display(plot([p for p in z], Layout(title="N. of iterations with inner cycle alpha.", xaxis_title="alpha", yaxis_title="# iterations")))
