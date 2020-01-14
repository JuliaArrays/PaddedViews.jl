module PaddedViews
using Base: OneTo, tail
using OffsetArrays

export PaddedView, paddedviews

"""
    datapadded = PaddedView(fillvalue, data, padded_axes)
    datapadded = PaddedView(fillvalue, data, padded_axes, data_axes)
    datapadded = PaddedView(fillvalue, data, sz)
    datapadded = PaddedView(fillvalue, data, sz, first_datum)

Create a padded version of the array `data`, where any elements within
the span of `padded_axes` not assigned in `data` will have value
`fillvalue`.

Supply `data_axes` to specify an alterate set of axes for `data`, effectively
relocating `data` to a different set of indices.
This is shorthand for

    offsetdata = OffsetArray(data, data_axes)
    datapadded = PaddedView(fillvalue, offsetdata, padded_axes)

using the [OffsetArrays](https://github.com/JuliaArrays/OffsetArrays.jl) package.

Alternately, the padded array size `sz` can be specified, in which case `datapadded`
starts indexing at 1.
One may optionally specify the location of the `[1, 1, ...]` element of `data` with
`first_datum`.
Specifically, `datapadded[first_datum...]` corresponds to `data[1, 1, ...]`.
`first_datum` defaults to all-1s.

# Example

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
"""
struct PaddedView{T,N,I,A} <: AbstractArray{T,N}
    fillvalue::T
    data::A
    indices::I

    function PaddedView{T,N,I,A}(fillvalue::T,
                                 data::AbstractArray{T,N},
                                 indices::NTuple{N,AbstractUnitRange}) where {T,N,I,A}
        new{T,N,I,A}(fillvalue, data, indices)
    end
end

PaddedView(fillvalue, data::AbstractArray{T,N}, indices) where {T,N} =
    PaddedView{T,N,typeof(indices),typeof(data)}(convert(T, fillvalue), data, indices)

function PaddedView(fillvalue, data::AbstractArray{T,N}, sz::Tuple{Integer,Vararg{Integer}}) where {T,N}
    inds = map(OneTo, sz)
    PaddedView{T,N,typeof(inds),typeof(data)}(convert(T, fillvalue), data, inds)
end

# This method eliminates an ambiguity between the two below it
function PaddedView(fillvalue,
                    data::AbstractArray{T,0},
                    ::Tuple{},
                    ::Tuple{}) where T
    return PaddedView(fillvalue, data, ())
end

function PaddedView(fillvalue,
                    data::AbstractArray{T,N},
                    padded_inds::NTuple{N,AbstractUnitRange},
                    data_inds::NTuple{N,AbstractUnitRange}) where {T,N}
    off_data = OffsetArray(data, data_inds...)
    return PaddedView(fillvalue, off_data, padded_inds)
end

function PaddedView(fillvalue,
                    data::AbstractArray{T,N},
                    sz::NTuple{N,Integer},
                    first_datum::NTuple{N,Integer}) where {T,N}
    padded_inds = map(OneTo, sz)
    data_inds   = map((ax, o)->ax.+o, axes(data), first_datum .- 1)
    return PaddedView(fillvalue, data, padded_inds, data_inds)
end

Base.axes(A::PaddedView) = A.indices
@inline Base.axes(A::PaddedView, d::Integer) = d <= ndims(A) ? A.indices[d] : default_axes(A.indices)
default_axes(::NTuple{N,I}) where {N,I<:AbstractUnitRange} = convert(I, OneTo(1))
default_axes(::Any) = OneTo(1)

Base.size(A::PaddedView) = map(length, axes(A))

Base.parent(A::PaddedView) = A.data

@inline function Base.getindex(A::PaddedView{T,N}, i::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, i...)
    if Base.checkbounds(Bool, A.data, i...)
        return A.data[i...]
    end
    return A.fillvalue
end

"""
    Aspad = paddedviews(fillvalue, A1, A2, ....)

Pad the arrays `A1`, `A2`, ..., to a common size or set of axes,
chosen as the span of axes enclosing all of the input arrays.

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
paddedviews(fillvalue) = ()

@inline outerinds(A::AbstractArray, Bs...) = _outerinds(axes(A), Bs...)
@inline _outerinds(inds, A::AbstractArray, Bs...) =
    _outerinds(_outerinds(inds, axes(A)), Bs...)
_outerinds(inds) = inds
@inline _outerinds(inds1::NTuple{N,I}, inds2::NTuple{N,I}) where {N,I<:AbstractUnitRange} =
    map((i1, i2) -> convert(I, padrange(i1, i2)), inds1, inds2)
_outerinds(inds1::NTuple{N,AbstractUnitRange}, inds2::NTuple{N,AbstractUnitRange}) where {N} =
    map((i1, i2) -> convert(UnitRange{Int}, padrange(i1, i2)), inds1, inds2)

# This shouldn't be reached due to the `paddedviews(fillvalue)` method above,
# but it's here in case anyone extends `paddedviews` for types other than AbstractArrays.
# See https://github.com/JuliaImages/ImageCore.jl/pull/32#discussion_r111545756
outerinds() = error("must supply at least one array with concrete axes")

padrange(i1::OneTo, i2::OneTo) = OneTo(max(last(i1), last(i2)))
padrange(i1::AbstractUnitRange, i2::AbstractUnitRange) = min(first(i1),first(i2)):max(last(i1), last(i2))

function Base.showarg(io::IO, A::PaddedView, toplevel)
    print(io, "PaddedView(", A.fillvalue, ", ")
    Base.showarg(io, parent(A), false)
    print(io, ", (", join(A.indices, ", "))
    print(io, ndims(A) == 1 ? ",))" : "))")
    toplevel && print(io, " with eltype ", eltype(A))
end

end # module
