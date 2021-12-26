#=
simulated:
- Julia version: 
- Author: sutymate
- Date: 2021-12-18
=#
using Random
using DataStructures

include("../../2/src/file_loader.jl")
Q_WINDOW = 10

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

function sa_try(T, state)
    bag, M, decision = state
    n = size(bag)[1]
    new_decision = copy(decision)
    # based on size of instance, change 5% of items
    for cnt in 1:(n//20 + 1)
        change_idx = rand(1:n)
        # flip one item
        new_decision[change_idx] = 1 - new_decision[change_idx]
    end
    new_state = (bag, M, new_decision)
    # difference in cost, can be negative
    acceptance_factor = improvement(new_state, state)
    # if difference is positive (better solution) accept it
    if acceptance_factor > 0 return new_state end
    # sometimes also accept worse solution, depends on a. factor and temperature
    if rand() < exp(-acceptance_factor / T)
        return new_state
    end
    return state
end

function improvement(current, previous)
    # returns difference in cost between current state and previous
    # can be negative
    return cost(current) - cost(previous)
end

function equilibrium(T, state, steps, q)
#     q_accepted = sum(q)
#     if q_accepted < Q_WINDOW*0.1 return false end
    return true
end

function cost(state)
    bag, M, decision = state
    n = size(bag)[1]
    profit = 0
    weight = 0
    for i in 1:n
        profit += bag[i, IDX_PRICE]*decision[i]
        weight += bag[i, IDX_WEIGHT]*decision[i]
    end
    if weight > M
        return 0
    end
    return profit
end

function cool(T, state)
    a = 0.95
    return a*T
end

function sa(instance)
    state = generate_solution(instance)
    T = 1
    best = state
    accepted = 1000
    frozen_limit = 50
    steps = 0
    q = Queue{Int8}()
    for i in 1:Q_WINDOW enqueue!(q, 0) end
    while accepted > frozen_limit
        for i in 1:50
            state = sa_try(T, state)
            if improvement(state, best) > 0
                best = state
                accepted += 1
            else
                accepted -= 1
            end
        end
        T =  cool(T, state)
#         println(accepted, "\t", cost(best), "\t", improvement(best, state), "\t", T)
    end
    return cost(best), best
end

function main()
    filename = "../data/ZKC/ZKC40_inst.dat"
    instances = readFile(filename)
    for instance in instances
        cost, result = sa(instance)
        println(cost)
    end
end

main()