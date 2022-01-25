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
    problem, decision = state
    for clause in eachrow(problem.clauses)
        clause_satisfied = false
        for variable in clause
            variable_value = decision[abs(variable)]
            if (0 == variable_value > variable) || (1 == variable_value <= variable)
                clause_satisfied = true
                break
            end
        end
        if ! clause_satisfied return false end
    end
    return true
end

function generateSAT(instance, random::Bool)
    # create random initial state
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
    return cooling_factor*T
end

function sa_try(T::Float64, state::Tuple{problemSAT, Array{Bool}})
    problem, decision = state
    new_decision = copy(decision)

    flip_id = sample(1:problem.nvar, problem.w_sample)
    new_decision[flip_id] = ! new_decision[flip_id]
    new_state = problem, new_decision

    acceptance_factor = improvement(new_state, state)
    # sometimes also accept worse solution, depends on acc. factor and temperature
    if (acceptance_factor > 0) || (rand() < exp(acceptance_factor / T))
        return new_state
    end
    return state
end

function initial_temperature(state::Tuple{problemSAT, Array{Bool}})
    problem, decision = state
    neighbor_cost = zeros(problem.nvar)
    for i in 1:problem.nvar
        new_decision = copy(decision)
        new_decision[i] = ! new_decision[i]
        neighbor_cost[i] = cost((problem, new_decision))
    end
    difference = abs(maximum(neighbor_cost) - minimum(neighbor_cost))
    return (1 - difference)*100
end

function sa(instance::Tuple{Array{Int64}, Array{Int64}, Int64, Int64, SubString{String}}; T::Float64=0.0, frozen_limit::Float64=0.01, inner_cycle::Int64=0, random::Bool=true, cooling_factor::Float64=0.99, restart::Bool=false, inner_cycle_alpha::Float64=0.75)
    problem, decision = generateSAT(instance, random)
    state = (problem, decision)
    if 0 < frozen_limit < T
    else
        T = initial_temperature(state)
    end
    if inner_cycle == 0
        inner_cycle = problem.nvar * inner_cycle_alpha
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
            state = sa_try(T, state)
            push!(y, cost(state))
            if improvement(state, best) > 0
                best = state
                rejected = 0
            else
                rejected += 1
            end
        end
        T =  cool(T, cooling_factor)
        if rand() < 0.001 && !valid(state) && restart
            state = generateSAT(instance, random)
            T = initial_temperature(state)
            println("RESTART init t ", T) 
            push!(y, -0.5)
            n_resets += 1
        end
    end
    return cost(best), cost(best, true), y, steps, n_resets
end
