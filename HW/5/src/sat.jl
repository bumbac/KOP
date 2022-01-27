#=
simulated:
- Julia version: 
- Author: sutymate
- Date: 2021-01-20
=#
using StatsBase
using Random

include("../../2/src/file_loader.jl")

struct problemSAT
    clauses::Array{Int64}
    w::Array{Int64}
    nvar::Int64
    nclauses::Int64
    w_sample::StatsBase.Weights
end

function valid(state::Tuple{problemSAT, Array{Bool}})
    # returns if CNF expression is evaluated as true
    problem, decision = state
    for clause in eachrow(problem.clauses)
        clause_satisfied = false
        for literal in clause
            variable_value = decision[abs(literal)]
            # variable_value == 0 means false and when literal < 0, literal is in negation
            # variable_value == 1 means true and when literal >= 1, literal is in gation
            # if any literal and variable in clause have same gation, clause is satisfied
            if (literal < variable_value == 0) || (1 == variable_value <= literal)
                clause_satisfied = true
                break
            end
        end
        if ! clause_satisfied return false end
    end
    return true
end

function generateSAT(instance, random::Bool)
    # create initial state, if random=true, generate random state, else all variables are false
    # can be invalid
    clauses, w, nvar, nclauses, filename = instance
    problem = problemSAT(clauses, w, nvar, nclauses, Weights(w))
    decision = 0
    if random
        decision = [rand([false, true]) for i in 1:nvar]
    else
        decision = zeros(Bool, nvar)
    end
    state = (problem, decision)
    return state
end

function improvement(current::Tuple{problemSAT, Array{Bool}}, previous::Tuple{problemSAT, Array{Bool}})
    # returns difference in cost between current and previous state
    # can be negative
    c = cost(current)
    p = cost(previous)
    
    difference = abs(c - p)
    if c < p
        return -difference
    else
        return difference
    end
end

function cost(state::Tuple{problemSAT, Array{Bool}}, sat_value::Bool = false)
    # optimization criterion
    # returns the cost/price of a state
    # counts number of satisfied clauses, if equals to all clauses, CNF is satisfied
    # and returns non negative cost
    # cost is  the sum of weight of true variables divided by sum of all weights
    # if some clauses are not satisfied, CNF is not satisfied,
    # returns how close is the state to satisfaction -> (1 - satClauses/allClauses)
    # and multiply by current cost of state
    problem, decision = state   
    n_sat_clauses = 0
    for clause in eachrow(problem.clauses)
        clause_satisfied = false
        for variable in clause
            variable_value = decision[abs(variable)]
            if (0 == variable_value > variable) || (1 == variable_value <= variable)
                n_sat_clauses += 1
                break
            end
        end
    end
    
    w_true_vars = sum(problem.w .* decision)
    if sat_value return w_true_vars end
    
    w_cost = w_true_vars / sum(problem.w)
    n_cost = n_sat_clauses / problem.nclauses
    if n_cost == 1
        return w_cost
    else
        return -1*(1 - n_cost)*w_cost
    end
end

function cool(T::Float64, cooling_factor::Float64)
    # returns cooled temperature
    return cooling_factor*T
end

function sa_try(T::Float64, state::Tuple{problemSAT, Array{Bool}}, choice::String="rand")
    # generates new state in space by flipping one variable
    # if new state is better than previous, accept it
    # or by some chance accept also worse solution
    problem, decision = state
    new_decision = copy(decision)
#    k = trunc(Int, problem.nvar / 3)
#    flip_ids = []
#    if choice == "w" flip_ids = [sample(1:problem.nvar, problem.w_sample)] end
#    if choice == "rand" 
#    flip_ids = [rand(1:problem.nvar)]
#    end    
#    if choice == "k rand" flip_ids = rand(1:problem.nvar, k) end    
#    if choice == "k w" flip_ids = sample(1:problem.nvar, problem.w_sample, k) end
#    for i in flip_ids new_decision[i] = ! new_decision[i] end
    flip_id = rand(1:problem.nvar)
    new_decision[flip_id] = ! new_decision[flip_id]
    new_state = (problem, new_decision)
    # difference in cost, negative when generated state is worse 
    acceptance_factor = improvement(new_state, state)
    # sometimes also accept worse solution, depends on acc. factor and temperature
    if (acceptance_factor > 0) || (rand() < exp(acceptance_factor / T))
        return new_state
    end
    # generated state not accepted, stay in current position
    return state
end


function initial_temperature(state::Tuple{problemSAT, Array{Bool}})
    # calculates initial temperature based on maximal difference in cost between neighbour states
    problem, decision = state
    neighbor_cost = zeros(problem.nvar)
    for i in 1:problem.nvar
        new_decision = copy(decision)
        # flip every variable - one per state
        new_decision[i] = ! new_decision[i]
        neighbor_cost[i] = cost((problem, new_decision))
    end
    # calculate biggest difference between neighbouring states
    difference = abs(maximum(neighbor_cost) - minimum(neighbor_cost))
    # when difference between states is big, temperature can be lower
    return (1 - difference)
end

function sa(instance::Tuple{Array{Int64}, Array{Int64}, Int64, Int64, SubString{String}}; T::Float64=0.0, frozen_limit::Float64=0.01, inner_cycle::Int64=0, random::Bool=true, cooling_factor::Float64=0.99, restart::Bool=false, inner_cycle_alpha::Float64=0.9, choice::String="rand")
    problem, decision = generateSAT(instance, random)
    state = (problem, decision)
    if 0 < frozen_limit < T
    else
        T = initial_temperature(state)
    end
    if inner_cycle == 0
        inner_cycle = ceil(Int64, sqrt(problem.nvar) * sqrt(problem.nclauses)*inner_cycle_alpha)
    end
    best = state    
    steps = 0
    # graph making, current solution
    y = []
    rejected = 0
    n_resets = 0
    while T > frozen_limit
        for i in 1:inner_cycle
            steps += 1
            state = sa_try2(T, state)
            push!(y, cost(state))
            if improvement(state, best) > 0
                best = state
            end
        end
        T =  cool(T, cooling_factor)
        if rand() < 0.001 && !valid(state) && restart
            state = generateSAT(instance, random)
            T = initial_temperature(state)
#            push!(y, -0.5)
            n_resets += 1
        end
    end
    return cost(best), cost(best, true), y, steps, n_resets
end

function sa_try2(T::Float64, state::Tuple{problemSAT, Array{Bool}}, choice::String="rand")
    # exploration strategy
    # tries to satisfy clauses
    problem, decision = state
    new_decision = copy(decision)
    flip_id = 0
    if !valid(state)
        # some clause is not satisfied
        var_flip = zeros(Bool, problem.nvar)
        clause_sat = zeros(Bool, problem.nclauses)
        clause_id = 1
        for clause in eachrow(problem.clauses)
            for variable in clause
                variable_value = decision[abs(variable)]
                if (0 == variable_value > variable) || (1 == variable_value <= variable)
                    # this clause is satisfied
                    clause_sat[clause_id] = true
                    break
                end
            end
            if clause_sat[clause_id] == false
                # set the variable as available for flipping
                for variable in clause var_flip[abs(variable)] = true end
            end
            clause_id += 1
        end
        # find available variables (that are in nonsatisfied clauses)
        nonsat_vars = findall(var_flip .== true)
        flip_id = rand(nonsat_vars)
    else
        flip_id = rand(1:problem.nvar)
    end
    # flip one
    new_decision[flip_id] = ! new_decision[flip_id]
    new_state = (problem, new_decision)

    acceptance_factor = improvement(new_state, state)
    # sometimes also accept worse solution, depends on acc. factor and temperature
    if (acceptance_factor > 0) || (rand() < exp(acceptance_factor / T))
        return new_state
    end
    return state
end