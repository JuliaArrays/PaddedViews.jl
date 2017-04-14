__precompile__(true)

module PaddedViews
using Base: OneTo, tail

export PaddedView, paddedviews

"""
    datapadded = PaddedView(fillvalue, data, sz)
    datapadded = PaddedView(fillvalue, data, indices)

Create a padded version of the array `data`, where any elements within
the span of `indices` not assigned in `data` will have value
`fillvalue`.

# Example

```julia
julia> a = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> PaddedView(-1, a, (4, 5))
4×5 PaddedViews.PaddedView{Int64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
  1   4   7  -1  -1
  2   5   8  -1  -1
  3   6   9  -1  -1
 -1  -1  -1  -1  -1
```
"""
immutable PaddedView{T,N,I,A} <: AbstractArray{T,N}
    fillvalue::T
    data::A
    indices::I

    function (::Type{PaddedView{T,N,I,A}}){T,N,I,A}(fillvalue::T,
                                                    data::AbstractArray{T,N},
                                                    indices::NTuple{N,AbstractUnitRange})
        new{T,N,I,A}(fillvalue, data, indices)
    end
end

(::Type{PaddedView}){T,N}(fillvalue, data::AbstractArray{T,N}, indices) =
    PaddedView{T,N,typeof(indices),typeof(data)}(convert(T, fillvalue), data, indices)
function (::Type{PaddedView}){T,N}(fillvalue, data::AbstractArray{T,N}, sz::Tuple{Integer,Vararg{Integer}})
    inds = map(OneTo, sz)
    PaddedView{T,N,typeof(inds),typeof(data)}(convert(T, fillvalue), data, inds)
end

Base.indices(A::PaddedView) = A.indices
@inline Base.indices(A::PaddedView, d::Integer) = d <= ndims(A) ? A.indices[d] : default_indices(A.indices)
default_indices{N,I<:AbstractUnitRange}(::NTuple{N,I}) = convert(I, OneTo(1))
default_indices(::Any) = OneTo(1)

Base.size(A::PaddedView) = _size(A, indices(A))
_size{N}(A, inds::NTuple{N,OneTo}) = map(length, inds)
_size(A, inds) = errmsg(A)
errmsg(A) = error("size not supported for arrays with indices $(indices(A)); see http://docs.julialang.org/en/latest/devdocs/offset-arrays/")

@inline function Base.getindex{T,N}(A::PaddedView{T,N}, i::Vararg{Int,N})
    @boundscheck checkbounds(A, i...)
    if Base.checkbounds(Bool, A.data, i...)
        return A.data[i...]
    end
    return A.fillvalue
end

"""
    Aspad = paddedviews(fillvalue, A1, A2, ....)

Pad the arrays `A1`, `A2`, ..., to a common size or set of indices,
chosen as the span of indices enclosing all of the input arrays.

# Example:
```julia
julia> a1 = reshape([1,2], 2, 1)
2×1 Array{Int64,2}:
 1
 2

julia> a2 = [1.0,2.0]'
1×2 Array{Float64,2}:
 1.0  2.0

julia> a1p, a2p = paddedviews(0, a1, a2);

julia> a1p
2×2 PaddedViews.PaddedView{Int64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Array{Int64,2}}:
 1  0
 2  0

julia> a2p
2×2 PaddedViews.PaddedView{Float64,2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Array{Float64,2}}:
 1.0  2.0
 0.0  0.0
```
"""
function paddedviews(fillvalue, As::AbstractArray...)
    inds = outerinds(As...)
    map(A->PaddedView(fillvalue, A, inds), As)
end
paddedviews(fillvalue) = nothing

@inline outerinds(A::AbstractArray, Bs...) = _outerinds(indices(A), Bs...)
@inline _outerinds(inds, A::AbstractArray, Bs...) =
    _outerinds(_outerinds(inds, indices(A)), Bs...)
_outerinds(inds) = inds
@inline _outerinds{N,I<:AbstractUnitRange}(inds1::NTuple{N,I}, inds2::NTuple{N,I}) =
    map((i1, i2) -> convert(I, padrange(i1, i2)), inds1, inds2)
_outerinds{N}(inds1::NTuple{N,AbstractUnitRange}, inds2::NTuple{N,AbstractUnitRange}) =
    map((i1, i2) -> convert(UnitRange{Int}, padrange(i1, i2)), inds1, inds2)

padrange(i1::OneTo, i2::OneTo) = OneTo(max(last(i1), last(i2)))
padrange(i1::AbstractUnitRange, i2::AbstractUnitRange) = min(first(i1),first(i2)):max(last(i1), last(i2))

end # module
