module repeaters

using Plots, StatsPlots
using StatsFuns: logistic
using LinearAlgebra
using GLM
using CSV
using DataFrames
using Statistics
using StatsBase
using Chain
using ProgressBars
using ProgressLogging

include("Download.jl")
include("splitData.jl")
include("rareEventsDefinitions.jl")
include("Coeficients.jl")
include("metrics.jl")
include("Plotting.jl")


export modelStatsUn

"""
	modelStatsUn(df::DataFrame, lgformula, tauV, n::Int;testPercent::Real=0.1, source=false, colname="tns_name", progress="log")

	Runs the model n times and returns a vector of classifiers with the coefficients, tau, predicted probabilities and the validation set

	Arguments:
		df::DataFrame: The dataframe to be used for training and testing
		lgformula: The formula to be used for the logistic regression model
		tauV: The vector of tau values to be used for the weighted logistic regression
		n::Int: The number of times to run the model
		testPercent::Real=0.1: The percentage of the data to be used for testing
		source=false: Whether the source column should be included in the training and testing dataframes
		colname="tns_name": The name of the column to be used for the test set
		progress="log": The type of progress bar to be used

	Returns:
		classifierVector: A vector of classifiers with the coefficients, tau, predicted probabilities, and the test set
"""
function modelStatsUn(df::DataFrame, lgformula, tauV, n::Int;testPercent::Real=0.1, source=false, colname="tns_name", progress="log")
	classifierVector = Vector{LogisticClassifier}()

	if progress != "log"
		for i in ProgressBar(1:n)
			## splitting dataframe
			train_set, test_set = trainTestSplit(df, testPercent, source=source)
			resp, pred = modelcols(apply_schema(lgformula, schema(lgformula, train_set)), train_set);
			testresp, testpred = modelcols(apply_schema(lgformula, schema(lgformula, test_set)), test_set);
			ybar = sum(resp)/length(resp)
			for τ in tauV
				w0 = (1-τ)/(1-ybar)
				w1 = τ/ybar
				
				betas, probs = WLRRE(pred, resp, w0, w1)
	
				push!(classifierVector, Coefficients(betas, τ, pred, resp, probs, testresp, predict(testpred,betas), test_set[:, colname]))
			end
			
		end
	else 
		@progress for i in 1:n
			## splitting dataframe
			train_set, test_set = trainTestSplit(df, testPercent, source=source)
			resp, pred = modelcols(apply_schema(lgformula, schema(lgformula, train_set)), train_set);
			testresp, testpred = modelcols(apply_schema(lgformula, schema(lgformula, test_set)), test_set);
			ybar = sum(resp)/length(resp)
			for τ in tauV
				w0 = (1-τ)/(1-ybar)
				w1 = τ/ybar
				
				betas, probs = WLRRE(pred, resp, w0, w1)
	
				push!(classifierVector, Coefficients(betas, τ, pred, resp, probs, testresp, predict(testpred,betas), test_set[:, colname]))
			end
		end
	end
	return classifierVector
end;

end # module repeaters
