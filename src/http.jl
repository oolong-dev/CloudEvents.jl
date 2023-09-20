export from_http, to_http

using JSON3

from_http(headers, body) = from_http(header, body, Any)
function from_http(headers, body, ::Type{T}) where T
    content_type = "application/cloudevents+json"

    ce = Dict()
    for (k, v) in headers
        k = lowercase(k)
        if k == "content-type"
            content_type = v
        elseif startswith(k, "ce-")
            ce[k[4:end]] = v
        end
    end

    # FIXME: `application/json; charset=utf-8` is not handled
    if content_type == "application/cloudevents+json"
        ce = Dict(string(k) => v for (k, v) in pairs(JSON3.read(body, T)))
    elseif content_type == "application/json"
        @show String(body)
        ce["data"] = JSON3.read(body, T)
    else
        ce["data"] = body
    end

    convert(CloudEvent, ce)
end

to_http(ce::CloudEvent, mode::Symbol=:structure) = to_http(ce, Val(mode))

# https://github.com/cloudevents/spec/blob/main/cloudevents/bindings/http-protocol-binding.md#31-binary-content-mode
function to_http(ce::CloudEvent, ::Val{:binary})
    headers = ["ce-$k" => string(ce[k]) for k in keys(ce) if !isnothing(ce[k])]
    body = ce[]
    headers, body
end

# https://github.com/cloudevents/spec/blob/main/cloudevents/bindings/http-protocol-binding.md#32-structured-content-mode
function to_http(ce::CloudEvent, ::Val{:structure})
    headers = ["Content-Type" => "application/cloudevents+json"]
    body = JSON3.write(Dict(k => string(ce[k]) for k in keys(ce) if !isnothing(ce[k]))) # TODO: more efficient, allow custom serialization
    headers, body
end
