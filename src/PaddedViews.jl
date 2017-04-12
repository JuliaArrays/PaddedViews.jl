__precompile__(true)

module PaddedViews
using Base: OneTo, tail

export PaddedView, paddedviews

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

function paddedviews(fillvalue, As::AbstractArray...)
    inds = outerinds(As...)
    map(A->PaddedView(fillvalue, A, inds), As)
end
paddedviews(As::AbstractArray...) = paddedviews(0, As...)

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
