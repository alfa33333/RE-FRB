module repeaters

using CSV
using DataFrames
using Statistics
using Chain
using ProgressBars
using ProgressLogging

include("Download.jl")
include("splitData.jl")


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
