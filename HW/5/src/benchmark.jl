
using PlotlyJS
using BenchmarkTools
include("sat.jl")
include("../../2/src/file_loader.jl")

tst = "/home/sutymate/School/KOP/HW/5/data/test/simple5-2"
A = "/home/sutymate/School/KOP/HW/5/data/wuf-A1/wuf20-88-A1"
A_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-A1/wuf20-88-A-opt.dat"
A1 = "/home/sutymate/School/KOP/HW/5/data/wuf-A1/wuf20-88-A1/wuf20-014-A.mwcnf"
Q = "/home/sutymate/School/KOP/HW/5/data/wuf-Q1/wuf20-78-Q1"
Q_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-Q1/wuf20-78-Q-opt.dat"
Q1 = "/home/sutymate/School/KOP/HW/5/data/wuf-Q1/wuf20-78-Q1/wuf20-01.mwcnf"
M = "/home/sutymate/School/KOP/HW/5/data/wuf-M1/wuf20-78-M1"
M_sol = "/home/sutymate/School/KOP/HW/5/data/wuf-M1/wuf20-78-M-opt.dat"


instances = readFileSat(Q)
solutions = readSolutionSat(Q_sol)

r = []
t = []
s = []
for instance in instances[400:500]
    sol = solutions[instance[5]]
    el = @elapsed profit, absolute, y, steps = sa(instance, restart=true)
    push!(r, absolute/sol)
    push!(t, el)
    push!(s, steps)
    println(absolute/sol)
end

for v in [r, t, s]
	g = plot(scatter(y=v))
	display(g)
	println("Q std ", std(v), " mean ", mean(v))
end

#tricky Q uf20-01000
#tricky Q uf20-0107
#Q uf20-0144
