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
        if weight > M return false end
    end
    return true
end

function generate_solution(instance)
    # create random initial solution
    bag, M = instance
    n = size(bag)[1]
    state = 0
    cnt = n*10
    while true
        cnt -= 1
        if cnt == 0
            println("CANT FIND INITIAL STATE")
            no = [i for i in 1:n]
            return (bag, M, zeros(Bool, n), [], no)
        end
        decision = zeros(Bool, n)
        yes = []
        no = []
        for i in 1:n
            answer = rand(0:1)
            if answer == 1
                if bag[i, IDX_WEIGHT] > M 
                    push!(no, i)
                    continue
                end
                push!(yes, i)
                decision[i] = 1
            else
                push!(no, i)
            end
        end
        state = (bag, M, decision, yes, no)
        if valid(state) return state end
    end
end

function repair(state)
    # unload random items from knapsack when overloaded
    bag, M, decision, yes, no = state
    weight = 0
    for i in yes weight += bag[i, IDX_WEIGHT] end
    while weight > M
        delete_idx = rand(yes)
        decision[delete_idx] = 0
        deleteat!(yes, findall(x->x==delete_idx, yes))
        push!(no, delete_idx)
        weight = 0
        for i in yes weight += bag[i, IDX_WEIGHT] end
    end 
    return (bag, M, decision, yes, no)
end

function sa_try(T, state)
    bag, M, decision, yes, no = state
    if length(no) == 0 return state end
    new_decision = copy(decision)
    change_idx = rand(no)
    # add one item
    new_decision[change_idx] = 1
    push!(yes, change_idx)
    deleteat!(no, findall(x->x==change_idx, no))
    new_state = (bag, M, new_decision, yes, no)
#     if !valid(new_state) new_state = repair(new_state) end
    return new_state
end

function improvement(current, previous)
    # returns difference in cost between current state and previous
    # can be negative
    return cost(current) - cost(previous)
end

function cost(state)
    # optimization criterion is the price of knapsack
    bag, M, decision, yes, no = state
    n = size(bag)[1]
    profit = 0
    weight = 0
    for i in yes
        profit += bag[i, IDX_PRICE]
        weight += bag[i, IDX_WEIGHT]
    end
    if weight > M
        # penalty
        return 0
    end
    return profit
end

function change(current, previous)
    bag, M, decision, yes, no = current
    pbag, pM, pdecision, pyes, pno = previous
    return sum(decision .⊻ pdecision) > 0
end

function cool(T, cooling_factor)
    return cooling_factor*T
end

function sa(instance, T, frozen_limit, inner_cycle=50, cooling_factor=0.99)
    state = generate_solution(instance)
    println(cost(state))
    best = state
    steps = 0
    # graph making, current solution
    y = []
    # graph making, best solution so far
    y_best = []
    change_cnt = 20
    
    while T > frozen_limit
        for i in 1:inner_cycle
            new_state = sa_try(T, state)
            if change(state, new_state)
                change_cnt = 20
            else
                change_cnt -= 1
            end                
            
            if change_cnt < 0 
                break 
            end
            
            
            # difference in cost, can be negative
            acceptance_factor = improvement(new_state, state)
            # if difference is positive (better solution) accept it
            if acceptance_factor > 0 state = new_state end
            # sometimes also accept worse solution, depends on a. factor and temperature
            if rand() < exp(-acceptance_factor / T) state = new_state end           
#             push!(y, cost(state))
#             push!(y_best, cost(best))
            if improvement(state, best) > 0 best = state end
        end
        T = cool(T, cooling_factor)
    end
#     println(best[4])
#     println(best[5])
#     println(best[3])
    return cost(best), best, y, y_best
end
