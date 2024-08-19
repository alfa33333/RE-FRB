
export createLogisticModel, extractTestModel, selectSample, predictLogisticModel



abstract type LogisticModel end
"""
    coefficientes struct
    coef::AbstractVecOrMat, coefficients matrix
    tau::Real, tau value for the coefficients
"""	
struct  coefficientsModel <: LogisticModel
coef::AbstractVecOrMat
tau::Real
end

"""
    sample struct
    features::AbstractVecOrMat, features of the sample
    name::String, name of the sample
"""	
struct  sampleModel <: LogisticModel
    features::AbstractVecOrMat
    name::String
end

"""
    predictionsModel struct
    predictions::AbstractVecOrMat, vector of predictions for the ensamble of classifiers
    tau::Real, tau value for the predictions
    name::string, name of the sample
"""	
struct  predictionsModel <: LogisticModel
    predictions::AbstractVecOrMat
    tau::Real
    name::String
end

function createLogisticModel(coefficients::DataFrame, tau)
    coefModel = @chain coefficients begin
        filter(:tau =>  x-> x == tau, _)
        select(Not(:tau))
    end
    coefMatrix = Matrix(coefModel)
    return coefficientsModel(coefMatrix, tau)
end

function extractTestModel(df::DataFrame, lgformula)
        names = termnames(lgformula.rhs)
        names = vcat("tns_name",names[2:end])
        return select(df, names)
end

function selectSample(df::DataFrame, name::String)
    sample = @chain df begin
        filter(:tns_name => x -> x == name, _)
        select(Not(:tns_name))
    end
    sample = [float(v) for v in values(sample[1,:])]
    return sampleModel(sample, name)
end


function predictLogisticModel(model::LogisticModel, sample::sampleModel; intercept=false)
    if !intercept
        data = vcat(1, sample.features)
    else
        data = sample
    end
    etavector  = model.coef * data 
    return predictionsModel(logistic.(etavector), model.tau, sample.name)
end