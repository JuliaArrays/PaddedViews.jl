using OffsetArrays
using Base.Test
ambs = detect_ambiguities(Base, Core)  # in case these have ambiguities of their own
using PaddedViews
@test isempty(setdiff(detect_ambiguities(PaddedViews, Base, Core), ambs))

# Basics
for n = 0:5
    a = PaddedView(0, ones(Int,ntuple(d->1,n)), ntuple(x->x+1,n))
    @test indices(a) == ntuple(x->1:x+1,n)
    @test a[1] == 1
    n > 0 && @test a[2] == 0
end
a0 = reshape([3])
a = PaddedView(-1, a0, ())
@test indices(a) == ()
@test ndims(a) == 0
@test a[] == 3

a = reshape(1:9, 3, 3)
A = PaddedViews.PaddedView(0.0, a, (Base.OneTo(4), Base.OneTo(5)))
@test eltype(A) == Int
@test ndims(A) == 2
@test size(A) === (4,5)
@test indices(A) === (Base.OneTo(4), Base.OneTo(5))
@test indices(A, 3) === Base.OneTo(1)
@test A == [1 4 7 0 0;
            2 5 8 0 0;
            3 6 9 0 0;
            0 0 0 0 0]

A = PaddedViews.PaddedView(0.0, a, (0:4, -1:5))
@test eltype(A) == Int
@test ndims(A) == 2
@test_throws ErrorException size(A)
@test indices(A) === (0:4, -1:5)
@test indices(A, 3) === 1:1
@test A == OffsetArray([0 0 0 0 0 0 0;
                        0 0 1 4 7 0 0;
                        0 0 2 5 8 0 0;
                        0 0 3 6 9 0 0;
                        0 0 0 0 0 0 0], 0:4, -1:5)

nothing
