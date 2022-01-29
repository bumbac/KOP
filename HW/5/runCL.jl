include("src/sat.jl")
include("src/file_loader.jl")
# comment this part if PlotlyJS is  already installed
##############
using Pkg
Pkg.add("PlotlyJS")
using PlotlyJS
##############

graphs = false
verbose = false
if "-v" in ARGS
    # if verbose false show only weights of variables and number of iterations
    # else show detailed text output
    verbose = true
end
if "-g" in ARGS 
    # show graphs
    graphs = true
    if verbose
        println("Graphs enabled.")
    end
end
if isempty(ARGS)
    push!(ARGS, "data/wuf-M1/wuf20-78-M1/wuf20-01.mwcnf")
    graphs=true
    verbose=true
end

function showSolution(state)
    problem, decision = state
    output = string(cost(state, true))
    for var in 1:problem.nvar
        output *= " "
        if decision[var] == false
            output *= "-"*string(var)
        else
            output *= string(var)
        end

    end
    output *= " 0"
    return output        
end

for a in ARGS
    if a == "-g" || a == "-v" continue end
    cost_in_time = 0
    instances = readFileSat(a)
    for instance in instances
        #########
        # example of predefined settings
        #EDIT THIS PART IF YOU WANT#
        #########
#        sa(instance, T=1.0, frozen_limit=0.01, inner_cycle=0, random=true, cooling_factor=0.99, restart=false, inner_cycle_alpha=0.9, choice="rand")
#        sa(instance, T=1.0, frozen_limit=0.01, inner_cycle=0, random=true, cooling_factor=0.99, restart=false, inner_cycle_alpha=0.9, choice="rand")                     
        #########
        #########
        relative_cost, absolute_cost, cost_in_time, steps, num_of_restarts, solution = sa(instance)
        if verbose
            println("Relative price of found solution: ", relative_cost)
            println("Absolute price of found solution: ", absolute_cost)
            println("Number of iterations: ", steps)
            println("Solution:\n", "w", instance[5], " ", showSolution(solution))
        else
            println("w", instance[5], " ", showSolution(solution))
#            println(absolute_cost, " ", steps, " " solution[2])
        end
        if graphs display(plot(scatter(y=cost_in_time, name=instance[5]))) end
    end
end
println("\nPress enter to exit.")
a = readline()
