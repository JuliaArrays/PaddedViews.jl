# PaddedViews

[![Build Status](https://travis-ci.org/JuliaArrays/PaddedViews.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/PaddedViews.jl)

[![codecov.io](http://codecov.io/github/JuliaArrays/PaddedViews.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArrays/PaddedViews.jl?branch=master)

[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/P/PaddedViews.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html

[![PkgEval][pkgeval-img]][pkgeval-url]

## Summary

PaddedViews provides a simple wrapper type, `PaddedView`, to add
"virtual" padding to any array without copying data. Edge values not
specified by the array are assigned a `fillvalue`.  Multiple arrays
may be "promoted" to have common indices using the `paddedviews`
function.

`PaddedView` arrays are read-only, meaning that you cannot assign
values to them. The original array may be extracted using `A =
parent(P)`, where `P` is a `PaddedView`.

## Examples

For padding a single array:

```julia
julia> a = collect(reshape(1:9, 3, 3))
3×3 Array{Int64,2}:
 1  4  7
 2  5  8
 3  6  9

julia> PaddedView(-1, a, (4, 5))
4×5 PaddedView(-1, ::Array{Int64,2}, (Base.OneTo(4), Base.OneTo(5))) with eltype Int64:
  1   4   7  -1  -1
  2   5   8  -1  -1
  3   6   9  -1  -1
 -1  -1  -1  -1  -1

 julia> PaddedView(-1, a, (1:5,1:5), (2:4,2:4))
 5×5 PaddedView(-1, OffsetArray(::Array{Int64,2}, 2:4, 2:4), (1:5, 1:5)) with eltype Int64 with indices 1:5×1:5:
 -1  -1  -1  -1  -1
 -1   1   4   7  -1
 -1   2   5   8  -1
 -1   3   6   9  -1
 -1  -1  -1  -1  -1

 julia> PaddedView(-1, a, (0:4, 0:4))
 5×5 PaddedView(-1, ::Array{Int64,2}, (0:4, 0:4)) with eltype Int64 with indices 0:4×0:4:
  -1  -1  -1  -1  -1
  -1   1   4   7  -1
  -1   2   5   8  -1
  -1   3   6   9  -1
  -1  -1  -1  -1  -1

julia> PaddedView(-1, a, (5,5), (2,2))
5×5 PaddedView(-1, OffsetArray(::Array{Int64,2}, 2:4, 2:4), (Base.OneTo(5), Base.OneTo(5))) with eltype Int64:
 -1  -1  -1  -1  -1
 -1   1   4   7  -1
 -1   2   5   8  -1
 -1   3   6   9  -1
 -1  -1  -1  -1  -1
```

For padding multiple arrays to have common indices:

```julia
julia> a1 = reshape([1,2], 2, 1)
2×1 Array{Int64,2}:
 1
 2

julia> a2 = [1.0,2.0]'
1×2 LinearAlgebra.Adjoint{Float64,Array{Float64,1}}:
 1.0  2.0

julia> a1p, a2p = paddedviews(0, a1, a2);   # 0 is the fill value

julia> a1p
2×2 PaddedView(0, ::Array{Int64,2}, (Base.OneTo(2), Base.OneTo(2))) with eltype Int64:
 1  0
 2  0

julia> a2p
2×2 PaddedView(0.0, ::LinearAlgebra.Adjoint{Float64,Array{Float64,1}}, (Base.OneTo(2), Base.OneTo(2))) with eltype Float64:
 1.0  2.0
 0.0  0.0
```
