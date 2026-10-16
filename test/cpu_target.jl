# `first_cpu_target` reduces a multi-target `-C` string to the one target the precompile step
# builds for. Every `+feature`/`-feature` must survive it: a package whose precompile-time code
# branches on `JLOptions().cpu_target` is otherwise built for a target the output process does not
# have, and pkgimage matching accepts the subset silently.
@testset "first_cpu_target" begin
    f = JuliaC.first_cpu_target

    @testset "a bare CPU name is unchanged" begin
        @test f("native") == "native"
        @test f("generic") == "generic"
    end

    @testset "features are kept" begin
        @test f("apple-m1,+sme,+sme2,+sme-f64f64") == "apple-m1,+sme,+sme2,+sme-f64f64"
        @test f("haswell,-rdrnd") == "haswell,-rdrnd"
        # Julia's grammar treats an omitted prefix as `+`, so a bare token is a feature too.
        @test f("x86-64,sse4_2") == "x86-64,sse4_2"
    end

    @testset "only the first target is taken" begin
        @test f("generic;apple-m1,+sme") == "generic"
        @test f("apple-m1,+sme;generic") == "apple-m1,+sme"
    end

    @testset "multiversioning directives are dropped" begin
        @test f("generic,clone_all") == "generic"
        @test f("generic,-clone_all") == "generic"
        @test f("generic,opt_size") == "generic"
        @test f("generic,min_size") == "generic"
        @test f("haswell,base(1)") == "haswell"
        @test f("apple-m1,+sme,clone_all,base(0)") == "apple-m1,+sme"
    end

    @testset "a real multi-target sysimage string" begin
        @test f("generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)") == "generic"
    end

    @testset "an empty string stays empty" begin
        @test f("") == ""
    end
end
