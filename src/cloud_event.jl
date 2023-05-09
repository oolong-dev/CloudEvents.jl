export CloudEvent

using URIs: URI
using TimeZones: ZonedDateTime, localzone, now
using UUIDs: uuid4

mutable struct CloudEvent{T}
    # required
    id::String
    source::URI
    specversion::String
    type::String

    # optional
    datacontenttype::Union{String,Nothing}
    dataschema::Union{URI,Nothing}
    subject::Union{String,Nothing}
    time::Union{ZonedDateTime,Nothing}

    # extra
    extensions::Dict

    data::T

    function CloudEvent(id, source, specversion, type, datacontenttype, dataschema, subject, time, extensions, data)
        if source isa String
            source = URI(source)
        end
        if time isa String
            time = ZonedDateTime(time, "yyyy-mm-ddTHH:MM:SSz")
        end
        if dataschema isa String
            dataschema = URI(dataschema)
        end

        specversion == "0.3" || specversion == "1.0" || @error "unknown specversion $specversion"

        new{typeof(data)}(id, source, specversion, type, datacontenttype, dataschema, subject, time, extensions, data)
    end
end

required_fields(::Type{<:CloudEvent}) = ("id", "source", "specversion", "type")
optional_fields(::Type{<:CloudEvent}) = ("datacontenttype", "dataschema", "subject", "time")
known_fields(ce::Type{<:CloudEvent}) = (required_fields(ce)..., optional_fields(ce)...)

function CloudEvent(
    data
    ; type,
    source,
    id=string(uuid4()),
    time=now(localzone()),
    specversion="1.0",
    datacontenttype=nothing,
    dataschema=nothing,
    subject=nothing,
    kw...
)
    extensions = Dict(convert(String, k) => v for (k, v) in kw)
    CloudEvent(id, source, specversion, type, datacontenttype, dataschema, subject, time, extensions, data)
end

Base.getindex(ce::CloudEvent) = ce.data

function Base.getindex(ce::CloudEvent, k::String)
    if k in known_fields(typeof(ce))
        getfield(ce, Symbol(k))
    else
        get(ce.extensions, k, nothing)
    end
end

Base.setindex!(ce::CloudEvent, v) = ce.data = v

function Base.setindex!(ce::CloudEvent, v, k)
    if k in known_fields(typeof(ce))
        setfield!(ce, Symbol(k), v)
    else
        setindex!(ce.extensions, v, k)
    end
end

Base.keys(ce::CloudEvent) = (known_fields(typeof(ce))..., keys(ce.extensions)...)

function Base.convert(::Type{Dict}, ce::CloudEvent)
    res = Dict(
        "id" => ce.id,
        "source" => ce.resource,
        "specversion" => ce.specversion,
        "type" => ce.type,
        "datacontenttype" => ce.datacontenttype,
        "dataschema" => ce.dataschema,
        "subject" => ce.subject,
        "time" => ce.time
        ;
        ce.extensions...
    )

    res["data"] = ce.data
    res
end

Base.convert(T::Type{<:CloudEvent}, x::AbstractDict) = CloudEvent(
    (x[f] for f in required_fields(T))...,
    (get(x, f, nothing) for f in optional_fields(T))...,
    Dict(f => x[f] for f in keys(x) if x ∉ known_fields(T)),
    get(x, "data", nothing)
)