__precompile__(true)

module PaddedViews

export PaddedView

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
    inds = map(Base.OneTo, sz)
    PaddedView{T,N,typeof(inds),typeof(data)}(convert(T, fillvalue), data, inds)
end

Base.indices(A::PaddedView) = A.indices
@inline Base.indices(A::PaddedView, d::Integer) = d <= ndims(A) ? A.indices[d] : default_indices(A.indices)
default_indices{N,I<:AbstractUnitRange}(::NTuple{N,I}) = convert(I, Base.OneTo(1))
default_indices(::Any) = Base.OneTo(1)

Base.size(A::PaddedView) = _size(A, indices(A))
_size{N}(A, inds::NTuple{N,Base.OneTo}) = map(length, inds)
_size(A, inds) = errmsg(A)
errmsg(A) = error("size not supported for arrays with indices $(indices(A)); see http://docs.julialang.org/en/latest/devdocs/offset-arrays/")

@inline function Base.getindex{T,N}(A::PaddedView{T,N}, i::Vararg{Int,N})
    @boundscheck checkbounds(A, i...)
    if Base.checkbounds(Bool, A.data, i...)
        return A.data[i...]
    end
    return A.fillvalue
end

end # module
