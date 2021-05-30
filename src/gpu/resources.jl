"""
Application-owned resource hosted in-memory on the GPU.
"""
mutable struct GPUResource{R<:Handle,I}
    resource::R
    memory::DeviceMemory
    info::I
end

Base.@kwdef struct GPUState
    images::Dict{Symbol,GPUResource{Image}} = Dict()
    buffers::Dict{Symbol,GPUResource{Buffer}} = Dict()
    semaphores::Dict{Symbol,Semaphore} = Dict()
    fences::Dict{Symbol,Fence} = Dict()
    command_pools::Dict{Symbol,CommandPool} = Dict()
    descriptor_pools::Dict{Symbol,DescriptorPool} = Dict()
    descriptor_sets::Dict{Symbol,DescriptorSet} = Dict()
    descriptor_set_layouts::Dict{Symbol,DescriptorSetLayout} = Dict()
    image_views::Dict{Symbol,ImageView} = Dict()
    samplers::Dict{Symbol,Sampler} = Dict()
end

function Base.show(io::IO, gpu::GPUState)
    print(io, "GPUState with")
    fields = fieldnames(GPUState)
    props = getproperty.(Ref(gpu), fieldnames(GPUState))
    idxs = findall(!isempty, props)
    props = props[idxs]
    fields = fields[idxs]
    if !isempty(props)
        lastfield = last(fields)
        for (field, prop) in zip(fields, props)
            print(io, ' ', length(prop), ' ', replace(string(field), "_" => " "))
            field ≠ lastfield && print(io, ',')
        end
    else
        print(io, " no resources")
    end
end

function Base.show(io::IO, ::MIME"text/plain", gpu::GPUState)
    print(io, "GPUState")
    fields = fieldnames(GPUState)
    props = getproperty.(Ref(gpu), fieldnames(GPUState))
    idxs = findall(!isempty, props)
    props = props[idxs]
    fields = fields[idxs]
    if !isempty(props)
        println(io)
        lastfield = last(fields)
        for (field, prop) in zip(fields, props)
            println(io, "└─ ", length(prop), ' ', replace(string(field), "_" => " "))
        end
    else
        print(io, " no resources")
    end
end
