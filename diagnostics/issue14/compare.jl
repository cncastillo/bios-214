using LinearAlgebra, Serialization

reference = deserialize(first(ARGS))
for path in ARGS[2:end]
    images = deserialize(path)
    @assert length(images) == length(reference)
    for (index, (actual, expected)) in enumerate(zip(images, reference))
        @assert size(actual) == size(expected)
        relative_error = norm(actual - expected) / norm(expected)
        println((path, image=index, relative_error))
        @assert relative_error < 5e-4
    end
end
