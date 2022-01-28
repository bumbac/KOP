include("src/sat.jl")
include("src/file_loader.jl")
using Pkg
Pkg.add("PlotlyJS")
using PlotlyJS

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

for a in ARGS
    if a == "-g" || a == "-v" continue end
    cost_in_time = 0
    instances = readFileSat(a)
    for instance in instances
        # print name of instance
        println(instance[5])
        #########
        # example of predefined settings
        #EDIT THIS PART IF YOU WANT#
        #########
#        sa(instance, T=1.0, frozen_limit=0.01, inner_cycle=0, random=true, cooling_factor=0.99, restart=false, inner_cycle_alpha=0.9, choice="rand")
#        sa(instance, T=1.0, frozen_limit=0.01, inner_cycle=0, random=true, cooling_factor=0.99, restart=false, inner_cycle_alpha=0.9, choice="rand")                     
        #########
        #########
        relative_cost, absolute_cost, cost_in_time, steps, num_of_restarts = sa(instance)
        if verbose
            println("Relative price of found solution: ", relative_cost)
            println("Absolute price of found solution: ", absolute_cost)
            println("Number of iterations: ", steps)
        else
            println(absolute_cost, " ", steps)
        end
        if graphs display(plot(scatter(y=cost_in_time, name=instance[5]))) end
    end
end
