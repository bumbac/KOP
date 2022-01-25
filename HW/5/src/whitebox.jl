using PlotlyJS
using Statistics
using JLD2
using BenchmarkTools

include("../src/sat.jl")
include("../../2/src/file_loader.jl")
A = "/home/sutymate/School/KOP/HW/5/data/wuf-A1/wuf20-88-A1"
A_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-A1/wuf20-88-A-opt.dat"
Q = "/home/sutymate/School/KOP/HW/5/data/wuf-Q1/wuf20-78-Q1"
Q_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-Q1/wuf20-78-Q-opt.dat"
M = "/home/sutymate/School/KOP/HW/5/data/wuf-M1/wuf20-78-M1"
M_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-M1/wuf20-78-M-opt.dat"
N = "/home/sutymate/School/KOP/HW/5/data/wuf-N1/wuf20-78-N1"
N_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-N1/wuf20-78-N-opt.dat"
R = "/home/sutymate/School/KOP/HW/5/data/wuf-R1/wuf20-78-R1"
R_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-R1/wuf20-78-R-opt.dat"

names = [(A, A_sol, "A"), (Q, Q_sol, "Q"), (M, M_sol, "M"), (N, N_sol, "N"), (R, R_sol, "R")]
cnt = 1
ax = []
axs = []
axr = []
x = []
xs = []
xr = []
for problem in names
    instances = readFileSat(problem[1])
    solutions = readSolutionSat(problem[2])
    restart = []
    no_restart = []
    stepsr = []
    stepsnr = []
    r = []
    nr = []
    for instance in instances[1:50]
        sol = solutions[instance[5]]
        profit, absolute, y, steps, n_r = sa(instance, restart=true)
        push!(restart, 1 - absolute/sol)    
        push!(stepsr, steps)
        push!(r, n_r)
        println(cnt)
        profit, absolute, y, steps, n_r = sa(instance, restart=false)
        push!(no_restart, 1 - absolute/sol)
        push!(stepsnr, steps)
        push!(nr, n_r)
    end
    push!(x, (restart, no_restart))
    push!(xs, (stepsr, stepsnr))
    push!(xr, (r, nr))
    push!(ax, box(y=restart, name=problem[3]*" restart"))
    push!(ax, box(y=no_restart, name=problem[3]*" no restart"))
    push!(axs, box(y=stepsr, name=problem[3]*" restart"))
    push!(axs, box(y=stepsnr, name=problem[3]*" no restart"))
    push!(axr, box(y=r, name=problem[3]*" restart"))
    push!(axr, box(y=nr, name=problem[3]*" no restart"))
end
display(plot([p for p in ax], Layout(title="Error in dataset.")))
display(plot([p for p in axs], Layout(title="N. of iterations.")))
display(plot([p for p in axr], Layout(title="N. of restarts.")))
