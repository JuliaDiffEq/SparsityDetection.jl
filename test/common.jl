### Rules
using Cassette, SparsityDetection
using SparseArrays, Test

using Cassette: tag, untag, Tagged, metadata, hasmetadata, istagged
using SparsityDetection: Path, BranchesPass, SparsityContext, Fixed,
    Input, Output, pset, Tainted, istainted,
    alldone, reset!, HessianSparsityContext
using SparsityDetection: TermCombination

function tester(f, Y, X, args...; sparsity=Sparsity(length(Y), length(X)))

    path = Path()
    ctx = SparsityContext(metadata=(sparsity, path), pass=BranchesPass)
    ctx = Cassette.enabletagging(ctx, f)
    ctx = Cassette.disablehooks(ctx)

    val = nothing
    while true
        val = Cassette.overdub(ctx,
                            f,
                            tag(Y, ctx, Output()),
                            tag(X, ctx, Input()),
                            map(arg -> arg isa Fixed ?
                                arg.value :
                                tag(arg, ctx, pset()), args)...)
        println("Explored path: ", path)
        alldone(path) && break
        reset!(path)
    end
    return ctx, val
end

testmeta(args...) = tester(args...)[1].metadata
testval(args...) = tester(args...) |> ((ctx,val),) -> untag(val, ctx)
testtag(args...) = tester(args...) |> ((ctx,val),) -> metadata(val, ctx)

function htester(f, X, args...)

    path = Path()
    ctx = HessianSparsityContext(metadata=path, pass=BranchesPass)
    ctx = Cassette.enabletagging(ctx, f)
    ctx = Cassette.disablehooks(ctx)

    val = nothing
    while true
        val = Cassette.overdub(ctx,
                            f,
                            tag(X, ctx, Input()),
                            map(arg -> arg isa Fixed ?
                                arg.value :
                                tag(arg, ctx, one(TermCombination)), args)...)
        println("Explored path: ", path)
        alldone(path) && break
        reset!(path)
    end
    return ctx, val
end
htestmeta(args...) = htester(args...)[1].metadata
htestval(args...)  = htester(args...) |> ((ctx,val),) -> untag(val, ctx)
htesttag(args...)  = htester(args...) |> ((ctx,val),) -> metadata(val, ctx)


using Test

Base.show(io::IO, ::Type{<:Cassette.Context}) = print(io, "ctx")
Base.show(io::IO, ::Type{<:Tagged}) = print(io, "tagged")

import Base.Broadcast: broadcasted, materialize, instantiate, preprocess
