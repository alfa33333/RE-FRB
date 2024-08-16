## This file contains the functions to compute the metrics of the classifiers

export extractmetricDataframe, Accuracy, Precision, Recall, F1Score

## helper functions

"""
    extractTau(container::AbstractVector{LogisticClassifier})

    Extracts the tau values from a vector of LogisticClassifier

    returns a vector of tau values
"""
function extractTau(container::AbstractVector{LogisticClassifier})
	tau = Vector{Float64}()
	for vector in container
		push!(tau, vector.tau)
	end
	tau
end

"""
    extractActualPredicted(container::LogisticClassifier)

    Extracts the predicted values from a container of type LogisticClassifier

    returns a vector of predicted values
"""
function extractActualPredicted(container::LogisticClassifier)
    actual = container.target
    predicted = container.prediction
return actual, predicted
end

"""
    extractActualPredicted(actual, predicted)

    Compares the actual and predicted values to return the number of true positives, true negatives, false positives and false negatives

    retruns a vector of truepositive, truenegative, falsepositive, falsenegative
"""
function extractActualPredicted(actual, predicted)
    truepositive = sum(predicted[actual.==1] .> 0.5)
    truenegative = sum(predicted[actual.==0] .<= 0.5)
    falsenegative = sum(predicted[actual.==1] .<= 0.5)
    falsepositive = sum(predicted[actual.==0] .> 0.5)
return truepositive, truenegative, falsepositive, falsenegative
end



### Metric functions

"""
    accuracy(container::LogisticClassifier)

    Computes the accuracy of a container of type LogisticClassifier

    returns the accuracy
"""
function Accuracy(container::LogisticClassifier)
    actual, predicted = extractActualPredicted(container)
    truepositive = sum(predicted[actual.==1] .> 0.5)
    truenegative = sum(predicted[actual.==0] .<= 0.5)
    truepositive, truenegative, falsepositive, falsenegative = extractActualPredicted(actual, predicted)

    return (truepositive + truenegative )/(truepositive+truenegative+falsepositive+falsenegative)
end

"""
    accuracy(container::AbstractVector{LogisticClassifier})

    Computes the accuracy of a vector of containers of type LogisticClassifier

    returns a vector of accuracy
"""
function Accuracy(container::AbstractVector{LogisticClassifier})
    vectoraccuracy = Vector{Float64}()
    for singleclassifier in container
        push!(vectoraccuracy, Accuracy(singleclassifier))
    end
    return vectoraccuracy
end

"""
    precision(container::LogisticClassifier)

    Computes the precision of a container of type LogisticClassifier

    returns the precision
"""
function Precision(container::LogisticClassifier)
    actual, predicted = extractActualPredicted(container)
    truepositive, truenegative, falsepositive, falsenegative = extractActualPredicted(actual, predicted)
    calculatedprecision = truepositive/(truepositive + falsepositive)
    if isnan(calculatedprecision)
        return 0.0
    else
        return calculatedprecision
    end
end

"""
    precision(container::AbstractVector{LogisticClassifier})

    Computes the precision of a vector of containers of type LogisticClassifier

    returns a vector of precision
"""
function Precision(container::AbstractVector{LogisticClassifier})
    vectorprecision = Vector{Float64}()
    for singleclassifier in container
        push!(vectorprecision, Precision(singleclassifier))
    end
    return vectorprecision
end

"""
    Recall(container::LogisticClassifier)

    Computes the recall of a container of type LogisticClassifier

    returns the recall
"""
function Recall(container::LogisticClassifier)
    actual, predicted = extractActualPredicted(container)
    truepositive, truenegative, falsepositive, falsenegative = extractActualPredicted(actual, predicted)
    return truepositive/(truepositive + falsenegative)
end

"""
    Recall(container::AbstractVector{LogisticClassifier})

    Computes the recall of a vector of containers of type LogisticClassifier

    returns a vector of recall
"""
function Recall(container::AbstractVector{LogisticClassifier})
    vectorrecall = Vector{Float64}()
    for singleclassifier in container
        push!(vectorrecall, Recall(singleclassifier))
    end
    return vectorrecall
end

"""
    F1Score(container::LogisticClassifier)

    Computes the F1 score of a container of type LogisticClassifier

    returns the F1 score
"""
function F1Score(container::Classifier)
    prec= Precision(container)
    recall = Recall(container)
    return 2*prec*recall/(prec+recall)
end

"""
    F1Score(container::AbstractVector{LogisticClassifier})

    Computes the F1 score of a vector of containers of type LogisticClassifier

    returns a vector of F1 score
"""
function F1Score(container::AbstractVector{LogisticClassifier})
    prec = Precision(container)
    recall = Recall(container)
    numerator = prec .* recall
    denominator = prec + recall
    return 2*numerator./denominator
end


### Metric dataframes

"""
    extractmetricDataframe(container::AbstractVector{LogisticClassifier}, metric::Function)

    Extracts the metric values from a vector of LogisticClassifier

    returns a dataframe with the metric values
"""
function extractmetricDataframe(container::AbstractVector{LogisticClassifier}, metric::Function)
	tau = extractTau(container);
	dfstat = DataFrame([i => zeros(length(unique(tau))) for i ∈ ["tau","min", "Q1", "med", "Q3", "max"]]...);
	dfstat.tau = unique(tau)
	metricvector = metric(container)
	for (i,t) in enumerate(dfstat.tau)
		dfstat[i,2:6]= quantile(metricvector[(tau.==t) .&& (.!isnan.(metricvector))], [0.0, 0.25, 0.5, 0.75, 1])
	end
	return dfstat
end

"""
    extractmetricDataframe(container::AbstractVector{LogisticClassifier}, metric::Function, Q1, Q3)

    Extracts the metric values from a vector of LogisticClassifier for a given quantile range Q1, Q3

    returns a dataframe with the metric values
"""
function extractmetricDataframe(container::AbstractVector{LogisticClassifier}, metric::Function, Q1, Q3)
	tau = extractTau(container);
	dfstat = DataFrame([i => zeros(length(unique(tau))) for i ∈ ["tau","min", "Q1", "med", "Q3", "max"]]...);
	dfstat.tau = unique(tau)
	metricvector = metric(container)
	for (i,t) in enumerate(dfstat.tau)
		dfstat[i,2:6]= quantile(metricvector[(tau.==t) .&& (.!isnan.(metricvector))], [0.0, Q1, 0.5, Q3, 1])
	end
	return dfstat
end