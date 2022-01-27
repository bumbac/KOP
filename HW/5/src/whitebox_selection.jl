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
names = [ (Q, Q_sol, "Q")]
d=Dict()
s=Dict()
for problem in names
   d[problem[3]] = [] 
   s[problem[3]] = [] 
end
f = ["rand", "w", "k rand", "k w"]
df = Dict()
for flip in f
    df[flip] = []
end
attempts = 5
for problem in names
    instances = readFileSat(problem[1])
    solutions = readSolutionSat(problem[2])
    println(problem[3])
    cnt = 1
    for instance in instances[1:100]
        sol = solutions[instance[5]]
        a = 0
        for flip in f
            for i in 1:attempts
                profit, a, y, h, n_r = sa(instance, T=100.0, choice=flip)
                push!(df[flip], a/sol)
            end
        end
        println(cnt)
        cnt += 1
    end
end
for a in keys(df)
    println(a, " ", mean(df[a]))
end
