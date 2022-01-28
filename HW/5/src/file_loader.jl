#=
file_loader:
- Julia version: 1.5.3
- Author: sutymate
- Date: 2021-11-04
=#
IDX_WEIGHT = 1
IDX_PRICE = 2
IDX_ID = 3
CLAUSE_LEN = 3

macro Name(arg)
    string(arg)
end


function readFile(name::String, problem="knapsack")
    if problem == "sat" return readFileSat(name) end
    line = 0
    instances = []
    open(name) do f
        while !eof(f)
            s = readline(f)
            line += 1
            pieces = split(s, ' ')
            ID = 0
            n = 0
            M = 0
            try
                ID = parse(Int64, pieces[1])
                n = parse(Int64, pieces[2])
                M = parse(Float64, pieces[3])
            catch e
                println("ERROR in parsing definition")
            end
            bag = zeros(Int64, (n, 3))
            idx = 1
            for i in 4:2:(length(pieces) - 1)
                weight = 0
                price = 0
                try
                    weight = parse(Int64, pieces[i])
                    price = parse(Int64, pieces[i + 1])
                catch e
                    println("ERROR in parsing pairs")
                end
                bag[idx, IDX_WEIGHT] = weight
                if weight > M price = 0 end
                bag[idx, IDX_PRICE] = price
                bag[idx, IDX_ID] = idx
                idx += 1
            end
            bag = sortslices(bag, dims=1, by=x->(x[2]/x[1]), rev=true)
            push!(instances, (bag, M))
        end
    end
    return instances
end



function readSolution(filename::String, problem="knapsack")
    if problem == "sat" return readSolutionSat(name) end
    solution = []
    line = 0
    open(filename) do f
        while !eof(f)
                s = readline(f)
                line += 1
                pieces = split(s, ' ')
                ID = 0
                n = 0
                B = 0
                try
                    ID = parse(Int64, pieces[1])
                    n = parse(Int64, pieces[2])
                    B = parse(Float64, pieces[3])
                catch e
                    println("ERROR in parsing definition")
                end
                push!(solution, (ID, n, B))
        end
        return solution
    end
end

function filesFromDir(dirname::String)
    if ! isdir(dirname)
        return [dirname]
    end
    filenames = readdir(dirname, join=true)
    return filenames
end

function readFileSatCL()
    filenames = filesFromDir(name)
    instances = []
    nvar = 0
    nclauses = 0
    w = 0
    clauses = 0
    clause_id = 1
    pieces = []
    while !eof(stdin)
        s = readline(stdin)
        if s[1] == 'c' continue end
        pieces = split(s, ' ')
        filter!(s->!all(isspace, s), pieces)
        if s[1] == 'p'
            nvar = parse(Int64, pieces[3])
            nclauses = parse(Int64, pieces[4]) - 1
            clauses = zeros(Int64, (nclauses, CLAUSE_LEN))
            continue
        end
        if s[1] == 'w'
            w = parse.([Int64], pieces[2:end - 1])
            continue
        end
        clauses[clause_id, :] = parse.([Int64], pieces[1:end-1])
        clause_id += 1
    end
    stripped_filename = stripFilename(filename)
    instance = (clauses, w, nvar, nclauses, stripped_filename)
    push!(instances, instance)
    return instances
end


function readFileSat(name::String, range="ALL")
    filenames = filesFromDir(name)
    instances = []
    if range == "ALL" range = 1:length(filenames) end
    for filename in filenames[range]
        open(filename) do f
            nvar = 0
            nclauses = 0
            w = 0
            clauses = 0
            clause_id = 1
            pieces = []
            while !eof(f)
                s = readline(f)
                if s[1] == 'c' continue end
                pieces = split(s, ' ')
                filter!(s->!all(isspace, s), pieces)
                if s[1] == 'p'
                    nvar = parse(Int64, pieces[3])
                    nclauses = parse(Int64, pieces[4]) - 1
                    clauses = zeros(Int64, (nclauses, CLAUSE_LEN))
                    continue
                end
                if s[1] == 'w'
                    w = parse.([Int64], pieces[2:end - 1])
                    continue
                end
                clauses[clause_id, :] = parse.([Int64], pieces[1:end-1])
                clause_id += 1
            end
            stripped_filename = stripFilename(filename)
            instance = (clauses, w, nvar, nclauses, stripped_filename)
            push!(instances, instance)
        end
    end
    return instances
end

function stripFilename(filename::String)
    slash_id = findlast('/', filename) + 2
    dash_id = 0
    if findlast('A', filename) != nothing
        dash_id = findlast('A', filename) - 2
    else
        dash_id = findlast('.', filename) - 1
    end
    return SubString(filename, slash_id, dash_id)
end

function readSolutionSat(name::String)
    solutions = Dict()
    open(name) do f
        idx = -1
        while !eof(f)
            s = readline(f)
            pieces = split(s, ' ')
            name = pieces[1]
            optimal_value = parse(Int64, pieces[2])
            solutions[name] = optimal_value
        end
    end
    return solutions
end
