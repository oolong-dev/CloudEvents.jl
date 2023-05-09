# CloudEvents

This package provides the Julia SDK for [CloudEvents](https://github.com/cloudevents/spec).

## Basic Usage

Below we provide the most common usages.

```julia
using CloudEvents

# Create a CloudEvent manually
data = Dict("message" => "Hello World!")
ce = CloudEvent(data; type="example", source="https://example.com/event-producer")

headers, body = to_http(ce)  # structure mode by default
# headers, body = to_http(ce, :binary)  # or binary mode

# Send CloudEvent
using HTTP

HTTP.post("<your url>", headers, body)

# Receive CloudEvent
using JSON3
HTTP.serve() do req
    ce = from_http(HTTP.headers(req), JSON3.read(req.body))
end
```