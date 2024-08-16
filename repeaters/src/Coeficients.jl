
export extractCoef

"""
    extractCoef(container::LogisticClassifier)

    Extracts the coefficients and tau from a container of type LogisticClassifier

    Returns coef, tau as a tuple
"""
function extractCoef(container::LogisticClassifier)
    return container.coef, container.tau
end

"""
    extractCoef(containerVector::AbstractVector{LogisticClassifier})

    Extracts the coefficients and tau from the vector of LogisticClassifier

    Returns a coefVector, tauVector as a tuple of vectors
"""
function extractCoef(containerVector::AbstractVector{LogisticClassifier})
    coefVector = Vector{Vector{Float64}}()
    tauVector = Vector{Float64}()
    for container in containerVector
        coef, tau = extractCoef(container)
        push!(coefVector, coef)
        push!(tauVector, tau)
    end
    return coefVector, tauVector
end

"""
    extractCoef(containerVector::AbstractVector{LogisticClassifier}, lgformula)

    Extracts the coefficients and tau from the vector of LogisticClassifier and the formula used to create the model

    Returns a DataFrame with the coefficients and tau labeled by the names of the terms in the formula
"""
function extractCoef(containerVector::AbstractVector{LogisticClassifier}, lgformula)
    names = termnames(lgformula.rhs)
    colnames = deepcopy(names)
    colnames[1] = "intercept"
    push!(colnames, "tau")
    coefdf = DataFrame([T[] for T in fill(Float64, length(colnames))], colnames)
    for container in containerVector
        coef, tau = extractCoef(container)
        push!(coefdf, [coef; tau])
    end
    return coefdf
end