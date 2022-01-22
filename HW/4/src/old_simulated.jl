#=
simulated:
- Julia version: 
- Author: sutymate
- Date: 2021-12-18
=#
using Random

include("../../2/src/file_loader.jl")

function valid(state)
    # checks if items in state do not exceed weight
    bag, M, decision = state
    weight = 0
    for i in 1:size(bag)[1]
        weight += decision[i]*bag[i, IDX_WEIGHT]
        if weight > M return false end
    end
    return true
end

function generate_solution(instance)
    # create random initial solution
    bag, M = instance
    n = size(bag)[1]
    state = 0
    cnt = 1000
    while true
        cnt -= 1
        if cnt == 0
            println("CANT FIND INITIAL STATE")
            state = (bag, M, zeros(Int8, n))
            break
        end
        n_candidates = rand(1:n)
        decision = zeros(Int8, n)
        for i in 1:n_candidates
            decision[i] = rand(0:1)
            # prevents loading too heavy item
            if bag[i, IDX_WEIGHT] > M decision[i] = 0 end
        end
        state = (bag, M, decision)
        if valid(state) break end
    end
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
    bag, M, decision = state
    n = size(bag)[1]
    new_decision = copy(decision)
    cnt = 0
    while cnt < n
        # try n times to add item
        change_idx = rand(1:n)
        # add one item
        if new_decision[change_idx] == 0
            new_decision[change_idx] = 1
            break
        end
        cnt += 1
    end
    new_state = (bag, M, new_decision)
    if !valid(new_state) new_state = repair(new_state) end
    return new_state
end

function sa(instance, T, frozen_limit, inner_cycle=50, cooling_factor=0.99)
    state = generate_solution(instance)
    n = size(instance[1])[1]
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
#         println(T)
    end
    return cost(best), best, y, y_best, steps
end
