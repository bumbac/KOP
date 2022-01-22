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
    bag, M, decision, yes, no = state
    weight = 0
    for i in yes
        weight += bag[i, IDX_WEIGHT]
    end
    return weight <= M
end

function add(state, idx=0, answer=1)
    # add or remove item from bag at idx
    bag, M, decision, yes, no = state
    if idx == 0
        if answer == 1
            if length(no) == 0 return state end
            idx = rand(no)
        else
            if length(yes) == 0 return state end
            idx = rand(yes)
        end
    end
    if answer == 1
        push!(yes, idx)
        deleteat!(no, findall(x->x==idx, no))
    else
        push!(no, idx)
        deleteat!(yes, findall(x->x==idx, yes))
    end
    decision[idx] = answer
    return (bag, M, decision, yes, no)
end


function generate_solution(instance)
    # create random initial solution
    # if no solution is found, return empty knapsack
    bag, M = instance
    n = size(bag)[1]
    limit = n*10
    empty_state = (bag, M, zeros(Bool, n), [], [idx for idx in 1:n])
    while limit > 0
        n_candidates = rand(1:n)
        state = empty_state
        for i in 1:n_candidates
            state = add(state)
        end
        if valid(state) return state end
        limit -= 1
    end
    return empty_state
end

function repair(state)
    # unload random items from knapsack when overloaded
    bag, M, decision, yes, no = state
    n = size(bag)[1]
    weight = 0
    for i in yes weight += bag[i, IDX_WEIGHT] end
    while weight > M
        delete_idx = rand(yes)
        state = add(state, delete_idx, 0)
        bag, M, decision, yes, no = state
        weight = 0
        for i in yes weight += bag[i, IDX_WEIGHT] end
    end 
    return state
end

function improvement(current, previous)
    # returns difference in cost between current state and previous
    # can be negative
    return cost(current) - cost(previous)
end

function cost(state)
    # optimization criterion is the price of knapsack
    bag, M, decision, yes, no = state
    profit = 0
    weight = 0
    for i in yes
        profit += bag[i, IDX_PRICE]
        weight += bag[i, IDX_WEIGHT]
    end
    if weight > M
        return 0
    end
    return profit
end

function cool(T, cooling_factor)
    return cooling_factor*T
end

function change(current, previous)
    bag, M, decision, yes, no = current
    pbag, pM, pdecision, yes, no = previous
    return sum(decision .⊻ pdecision) > 0
end

function sa_try2(T, state)
    bag, M, decision, yes, no = state
    n = size(bag)[1]
    new_decision = copy(decision)
    cnt = 0
    while cnt < n
        # try n times to add item
        change_idx = rand(1:n)
        # add one item
        if new_decision[change_idx] == 0
            new_decision[change_idx] = 1
            push!(yes, change_idx)
            deleteat!(no, findall(x->x==change_idx, no))
            break
        end
        cnt += 1
    end
    new_state = (bag, M, new_decision)
    if cost(new_state) == 0 new_state = repair(new_state) end
    return new_state
end

function sa_try(T, state)
    new_state = add(state)
    if !valid(new_state) new_state = repair(new_state) end
    return new_state
end

function sa(instance, T, frozen_limit, inner_cycle=50, cooling_factor=0.99)
    state = generate_solution(instance)
    best = state    
    steps = 0
    y = []
    y_best = []

    accepted_limit = inner_cycle // 2
    all_limit = 100000
    while T > frozen_limit && steps < all_limit
        accepted = 0
        for i in 1:inner_cycle
            steps += 1
            accepted += 1
            if accepted == accepted_limit break end
            push!(y, cost(state))
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
        T = cool(T, cooling_factor)
    end
    return cost(best), best, y, y_best
end
