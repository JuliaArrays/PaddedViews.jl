using OffsetArrays
using Test
ambs = detect_ambiguities(Base, Core)  # in case these have ambiguities of their own
using PaddedViews
@testset "ambiguities" begin
    @test isempty(setdiff(detect_ambiguities(PaddedViews, Base, Core), ambs))
end

@testset "PaddedView" begin
    for n = 0:5
        a = @inferred(PaddedView(0, ones(Int,ntuple(d->1,n)), ntuple(x->x+1,n)))
        @test axes(a) == ntuple(x->1:x+1,n)
        @test @inferred(a[1]) == 1
        n > 0 && @test @inferred(a[2]) == 0
        @test @inferred(a[ntuple(x->1,n)...]) == 1
        n > 0 && @test @inferred(a[2, ntuple(x->1,n-1)...]) == 0
    end
    a0 = reshape([3])
    a = @inferred(PaddedView(-1, a0, ()))
    @test axes(a) == ()
    @test ndims(a) == 0
    @test a[] == 3

    a = reshape(1:9, 3, 3)
    A = @inferred(PaddedView(0.0, a, (Base.OneTo(4), Base.OneTo(5))))
    @test eltype(A) == Int
    @test ndims(A) == 2
    @test size(A) === (4,5)
    @test @inferred(axes(A)) === (Base.OneTo(4), Base.OneTo(5))
    @test @inferred(axes(A, 3)) === Base.OneTo(1)
    @test A == [1 4 7 0 0;
                2 5 8 0 0;
                3 6 9 0 0;
                0 0 0 0 0]

    A = @inferred(PaddedView(0.0, a, (0:4, -1:5)))
    @test eltype(A) == Int
    @test ndims(A) == 2
    @test size(A) == (5, 7)
    @test @inferred(axes(A)) === (0:4, -1:5)
    @test @inferred(axes(A, 3)) === 1:1
    @test A == OffsetArray([0 0 0 0 0 0 0;
                            0 0 1 4 7 0 0;
                            0 0 2 5 8 0 0;
                            0 0 3 6 9 0 0;
                            0 0 0 0 0 0 0], 0:4, -1:5)

    A = @inferred(PaddedView(0.0, a, (Base.OneTo(5), Base.OneTo(5)), (2:4, 2:4)))
    @test A == [0 0 0 0 0;
                0 1 4 7 0;
                0 2 5 8 0;
                0 3 6 9 0;
                0 0 0 0 0]
    @test A == @inferred(PaddedView(0.0, a, (5, 5), (2, 2)))
    B = @inferred(PaddedView(0.0, OffsetArray(a, (2:4, 2:4)), (Base.OneTo(5), Base.OneTo(5))))
    @test B == A

    @test PaddedView(0, ones(4), (3,), (1,)) == PaddedView(0, ones(4), (3,))

    let a = reshape(1:6, 2, 3) # [1 3 5; 2 4 6]
        @test @inferred(PaddedView(-1, a, (2, 2))) == [1 3
                                                       2 4]

        @test @inferred(PaddedView(-1, a, (1, 4)))  == [1 3 5 -1 ]

        @test @inferred(PaddedView(-1, a, (2, 4), (1, 1)))  == [1 3 5 -1
                                                                2 4 6 -1]

        @test @inferred(PaddedView(-1, a, (2, 4), (1, 2)))  == [-1 1 3 5
                                                                -1 2 4 6]

        @test @inferred(PaddedView(-1, a, (2, 3), (0, 2)))  == [-1  2  4
                                                                -1 -1 -1]

        @test @inferred(PaddedView(-1, a, (1, 4), (1, -1))) == [5 -1 -1 -1]

        # Create an OffsetArray with axes (0:1, 2:4)
        oa = OffsetArray(a, -1, 1)
        # Make a PaddedView of its elements (1:3, 1:2) (i.e pv[1, 1] == oa[1, 1] == "a[2, 0]" == -1)
        pv = @inferred PaddedView(-1, oa, (3, 2))
        @test axes(pv) === (Base.OneTo(3), Base.OneTo(2))
        @test pv[1:3, 1:2] == [-1 2; -1 -1; -1 -1]
        # Put oa[1, 1] in pv[2, 0] and make a PaddedView of the resulting (1:3, 1:2) elements
            # i.e. same as putting oa[0,2] in pv[1, 1]
        pv = @inferred PaddedView(-1, oa, (3, 2), (2, 0))
        @test pv[1:3, 1:2] == [1 3; 2 4; -1 -1]
    end
end

@testset "paddedviews" begin
    a1 = reshape([1,2], 2, 1)
    a2 = [1.0,2.0]'
    a1p, a2p = @inferred(paddedviews(0, a1, a2))
    @test a1p == [1 0; 2 0]
    @test a1p[CartesianIndices(a1)] == a1
    @test a2p == [1.0 2.0; 0.0 0.0]
    @test a2p[CartesianIndices(a2)] == a2
    @test eltype(a1p) == Int
    @test eltype(a2p) == Float64
    @test axes(a1p) === axes(a2p) === (Base.OneTo(2), Base.OneTo(2))

    a3 = OffsetArray([1.0,2.0]', (0,-1))
    a1p, a3p = @inferred(paddedviews(0, a1, a3))
    @test a1p == OffsetArray([0 1; 0 2], 1:2, 0:1)
    @test a1p[CartesianIndices(a1)] == a1
    @test a3p == OffsetArray([1.0 2.0; 0.0 0.0], 1:2, 0:1)
    @test a3p[CartesianIndices(a3)] == a3
    @test eltype(a1p) == Int
    @test eltype(a3p) == Float64
    @test axes(a1p) === axes(a3p) === (1:2, 0:1)

    @test @inferred(paddedviews(3)) == ()
    @test_throws ErrorException PaddedViews.outerinds()
    # But a zero-dimensional input should not trigger that error
    a = reshape([5])
    @test paddedviews(-1, a) == (a,)
end

@testset "cpaddedviews" begin
    a1 = reshape([1,2,3], 3, 1)
    a2 = [1.0,2.0,3.0]'
    a1p, a2p = @inferred(cpaddedviews(0, a1, a2))

    @test a1p == OffsetArray([0 1 0; 0 2 0; 0 3 0], (1:3, 0:2))
    @test a1p[CartesianIndices(a1)] == a1
    @test a2p == OffsetArray([0.0 0.0 0.0; 1.0 2.0 3.0; 0.0 0.0 0.0], (0:2, 1:3))
    @test a2p[CartesianIndices(a2)] == a2
    @test eltype(a1p) == Int
    @test eltype(a2p) == Float64
    @test axes(a1p) === (1:3, 0:2)
    @test axes(a2p) === (0:2, 1:3)

    a3 = OffsetArray([1.0,2.0,3.0]', (0,-1))
    a1p, a3p = @inferred(cpaddedviews(0, a1, a3))

    @test a1p == OffsetArray([0 1 0; 0 2 0; 0 3 0], 1:3, 0:2)
    @test a1p[CartesianIndices(a1)] == a1
    @test a3p == OffsetArray([0.0 0.0 0.0; 1.0 2.0 3.0; 0.0 0.0 0.0], 0:2, 0:2)
    @test a3p[CartesianIndices(a3)] == a3
    @test eltype(a1p) == Int
    @test eltype(a3p) == Float64
    @test axes(a1p) == (1:3, 0:2)
    @test axes(a3p) == (0:2, 0:2)

    @test @inferred(cpaddedviews(3)) == ()
end

@testset "showarg" begin
    a = collect(reshape(1:9, 3, 3))
    pv = PaddedView(-1, a, (0:4, 1:3))
    io = IOBuffer()
    show(IOContext(io, :displaysize=>(1000,1000)), MIME("text/plain"), pv)
    str = String(take!(io))
    @test endswith(str, "PaddedView(-1, ::Array{$Int,2}, (0:4, 1:3)) with eltype $Int with indices 0:4×1:3:\n -1  -1  -1\n  1   4   7\n  2   5   8\n  3   6   9\n -1  -1  -1")
end
