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

function valid(state)
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

function generateSAT(instance, random)
    # create random initial state
    # can be invalid
    clauses, w, nvar, nclauses = instance
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

function improvement(current, previous)
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

function cost(state, sat_value = false)
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

function cool(T, cooling_factor)
    return cooling_factor*T
end

function sa_try(T, state)
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

function sa(instance, T, frozen_limit, inner_cycle=50, random=true, cooling_factor=0.99)
    problem, decision = generateSAT(instance, random)
    state = (problem, decision)
    best = state    
    best_all = state
    steps = 0
    # graph making, current solution
    y = []
    # graph making, best solution so far
    y_best = []
    all_limit = 10000
    while T > frozen_limit# && steps < all_limit
        accepted = 0
        for i in 1:inner_cycle
            steps += 1
            push!(y_best, cost(best))
            state = sa_try(T, state)
            if improvement(state, best) > 0 best = state end
        end
        push!(y, cost(state))
        T =  cool(T, cooling_factor)
    end
    return cost(best), cost(best, true), y, y_best, steps
end
