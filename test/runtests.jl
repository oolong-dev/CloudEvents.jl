using CloudEvents
using Test
using JSON3

@testset "CloudEvents.jl" begin

    @testset "uppercase header" begin
        headers = [
            "Ce-Id" => "my-id",
            "Ce-Source" => "<event-source>",
            "Ce-Type" => "cloudevent.event.type",
            "Ce-Specversion" => "1.0",
            "Content-Type" => "text/plain"
        ]

        ce = from_http(headers, nothing)

        @test isnothing(ce[])
    end

    @testset "cloudevents+json" begin
        headers = ["Content-Type" => "application/cloudevents+json"]
        body = JSON3.write(Dict(
            "specversion" => "1.0",
            "source" => "s",
            "type" => "t",
            "id" => "1234-1234-1234",
            "data" => Dict("foo" => "bar"),
            "extra_baz" => "baz"
        ))
        ce = from_http(headers, body)
        @test ce["extra_baz"] == "baz"
        headers, body = to_http(ce)
    end
end
