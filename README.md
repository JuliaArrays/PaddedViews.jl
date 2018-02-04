# PaddedViews

[![Build Status](https://travis-ci.org/JuliaArrays/PaddedViews.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/PaddedViews.jl)

[![Build status](https://ci.appveyor.com/api/projects/status/p4ci9hb4oe4tbro9/branch/master?svg=true)](https://ci.appveyor.com/project/timholy/paddedviews-jl/branch/master)

[![codecov.io](http://codecov.io/github/JuliaArrays/PaddedViews.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArrays/PaddedViews.jl?branch=master)

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
julia> a = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> PaddedView(-1, a, (4, 5))   # -1 is the fill value, (4, 5) is the desired size
4×5 PaddedViews.PaddedView{Int64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
  1   4   7  -1  -1
  2   5   8  -1  -1
  3   6   9  -1  -1
 -1  -1  -1  -1  -1

julia> PaddedView(-1, a, (4,5), (2,2)) # (2, 2) is the location of the first element from a
4×5 PaddedViews.PaddedView{Int64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},OffsetArrays.OffsetArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}}:
 -1  -1  -1  -1  -1
 -1   1   4   7  -1
 -1   2   5   8  -1
 -1   3   6   9  -1
```

For padding multiple arrays to have common indices:

```julia
julia> a1 = reshape([1,2], 2, 1)
2×1 Array{Int64,2}:
 1
 2

julia> a2 = [1.0,2.0]'
1×2 Array{Float64,2}:
 1.0  2.0

julia> a1p, a2p = paddedviews(0, a1, a2);   # 0 is the fill value

julia> a1p
2×2 PaddedViews.PaddedView{Int64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Array{Int64,2}}:
 1  0
 2  0

julia> a2p
2×2 PaddedViews.PaddedView{Float64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Array{Float64,2}}:
 1.0  2.0
 0.0  0.0
```
