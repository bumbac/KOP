#=
simulated:
- Julia version: 
- Author: sutymate
- Date: 2021-12-18
=#
using Random

include("../../2/src/file_loader.jl")

struct problemSAT
    clauses::Array{Int64}
    w::Array{Int64}
    nvar::Int64
    nclauses::Int64
end

function valid(state)
    problem, decision = state
    for clause in problem.clauses
        clause_satisfied = false
        for variable in clause
            variable_value = decision[abs(variable)]
            if (0 == variable_value > variable) ||
               (1 == variable_value <= variable)
                clause_satisfied = true
                break
            end
        end
        if ! clause_satisfied return false end
    end
    return true
end

function generateSAT(instance)
    # create random initial state
    clauses, w, nvar, nclauses = instance
    problem = problemSAT(clauses, w, nvar, nclauses)
    decision = zeros(Bool, nvar)
    state = (problem, decision)
    return state
end

function repair(state)
    # unload random items from knapsack when overloaded
    bag, M, decision = state
    n = size(bag)[1]
    weight = 0
    for i in 1:n weight += bag[i, IDX_WEIGHT]*decision[i] end
    while weight > M
        delete_idx = rand(1:n)
        decision[delete_idx] = 0
        weight = 0
        for i in 1:n weight += bag[i, IDX_WEIGHT]*decision[i] end
    end 
    return (bag, M, decision)
end

function improvement(current, previous)
    # returns difference in cost between current state and previous
    # can be negative
    return cost(current) - cost(previous)
end

function cost(state)
    # optimization criterion is the price of knapsack
    bag, M, decision = state
    n = size(bag)[1]
    profit = 0
    weight = 0
    for i in 1:n
        profit += bag[i, IDX_PRICE]*decision[i]
        weight += bag[i, IDX_WEIGHT]*decision[i]
    end
    if weight > M
#         curbed_state = repair(state)
        return 0  #cost(curbed_state)
    end
    return profit
end

function cool(T, cooling_factor)
    return cooling_factor*T
end

function change(current, previous)
    bag, M, decision = current
    pbag, pM, pdecision = previous
    return sum(decision .⊻ pdecision) > 0
end

function sa_try(T, state)
    problem, decision = state
    n = problem.nvars
    new_decision = copy(decision)

#     vars_true = findall(a->a==true, decision)
    vars_false = findall(a->a==false, decision)
    if isempty(vars_false) return state end
    flip_id = rand(vars_false)
    new_decision[flip_id] = true
    new_state = problem, new_decision
    
    if !valid(new_state) new_state = repair(new_state) end
    return new_state
end

function sa(instance, T, frozen_limit, inner_cycle=50, cooling_factor=0.99)
    problem, decision = generateSAT(instance)
    best = state    
    best_all = state
    steps = 0
    # graph making, current solution
    y = []
    # graph making, best solution so far
    y_best = []
    accepted_limit = inner_cycle // 2
#     all_limit = n*1000
    while T > frozen_limit# && steps < all_limit
        accepted = 0
        for i in 1:inner_cycle
            steps += 1
            accepted += 1
            if accepted == accepted_limit break end
            push!(y_best, cost(best))
            if improvement(state, best) > 0 best = state end
           
            new_state = sa_try(T, state)
            acceptance_factor = improvement(new_state, state)
            if acceptance_factor > 0
                state = new_state
                continue
            end
            # sometimes also accept worse solution, depends on a. factor and temperature
            if rand() < exp(acceptance_factor / T) 
                state = new_state 
                continue
            end
            accepted -= 1
            
        end
        push!(y, cost(state))
        T =  cool(T, cooling_factor)
    end
    return cost(best), best, y, y_best, steps
end
