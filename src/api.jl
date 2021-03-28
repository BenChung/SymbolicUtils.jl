##### Numeric simplification

"""
```julia
simplify(x; polynorm=false,
            threaded=false,
            thread_subtree_cutoff=100,
            rewriter=nothing)
```

Simplify an expression (`x`) by applying `rewriter` until there are no changes.
`polynorm=true` applies `polynormalize` in the beginning of each fixpoint iteration.
"""
function simplify(x;
                  polynorm=false,
                  threaded=false,
                  thread_subtree_cutoff=100,
                  rewriter=nothing)
    f = if rewriter === nothing
        if threaded
            threaded_simplifier(thread_subtree_cutoff)
        elseif polynorm
            serial_polynormal_simplifier
        else
            serial_simplifier
        end
    else
        Fixpoint(rewriter)
    end

    PassThrough(f)(x)
end

Base.@deprecate simplify(x, ctx; kwargs...)  simplify(x; rewriter=ctx, kwargs...)

"""
    substitute(expr, dict)

substitute any subexpression that matches a key in `dict` with
the corresponding value.
"""
function substitute(expr, dict; fold=true)
    haskey(dict, expr) && return dict[expr]

    if istree(expr)
        if fold
            canfold=true
            args = map(arguments(expr)) do x
                x′ = substitute(x, dict; fold=fold)
                canfold = canfold && !(x′ isa Symbolic)
                x′
            end
            canfold && return operation(expr)(args...)
            args
        else
            args = map(x->substitute(x, dict), arguments(expr))
        end
        similarterm(expr, operation(expr), args)
    else
        expr
    end
end

"""
    occursin(needle::Symbolic, haystack::Symbolic)

Determine whether the second argument contains the first argument. Note that
this function doesn't handle associativity, commutativity, or distributivity.
"""
Base.occursin(needle::Symbolic, haystack::Symbolic) = _occursin(needle, haystack)
Base.occursin(needle, haystack::Symbolic) = _occursin(needle, haystack)
Base.occursin(needle::Symbolic, haystack) = _occursin(needle, haystack)
function _occursin(needle, haystack)
    isequal(needle, haystack) && return true

    if istree(haystack)
        args = arguments(haystack)
        for arg in args
            occursin(needle, arg) && return true
        end
    end
    return false
end
