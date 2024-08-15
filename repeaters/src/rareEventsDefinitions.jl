
## DataStructures

abstract type LogisticClassifier end
"""
    Classifier struct
    lg::StatsModels.TableRegressionModel
    tau::Real
    target::Vector
    prediction::Vector 
"""	
struct Classifier <: LogisticClassifier
lg::StatsModels.TableRegressionModel
tau::Real
target::Vector
prediction::Vector
end

"""
    coef::AbstractVector
    tau::Real
    train::AbstractVecOrMat
    targetrain::AbstractVector
    probtrain::AbstractVector
    target::Vector
    prediction::Vector
    name::Vector
"""	
struct Coefficients <: LogisticClassifier
coef::AbstractVector
tau::Real
train::AbstractVecOrMat
targetrain::AbstractVector
probtrain::AbstractVector
target::Vector
prediction::Vector
name::Vector
end

## Help functions

"""
	populationSplit(df::DataFrame; SelecLabel="Nrep", feature=:repeater_name)

	Return Repeater dataframe, Non-repeater dataframe
"""
function populationSplit(df::DataFrame; selectLabel="Nrep", feature=:repeater_name)
 	## Splitting populations
	NRdf = filter(feature => x->x==selectLabel,df);
	Rdf = filter(feature => x->x!==selectLabel,df);
	return Rdf, NRdf
end

"""
	holdOut(dataset::DataFrame, hold_per::Real)

	Returns a sample  with certain percentage removed, determined by hold_per.

	return new set, hold samples
"""
function holdOut(dataset::DataFrame, hold_per::Real)
    n_hold = floor(Int, nrow(dataset)*hold_per);
    idx_new = sample(1:nrow(dataset), nrow(dataset) - n_hold, replace=false);
    new_set = dataset[idx_new,:];
    hold = dataset[Not(idx_new), :];
    return new_set, hold 
end

"""
	holdOutRep(dataset::DataFrame, hold_per::Real)

	Returns a sample  with certain percentage removed, determined by hold_per for repeater sources.

	return new set, hold samples
"""
function holdOutRep(dataset::DataFrame, hold_per::Real)
	selNames =  @chain dataset begin
	    groupby(:repeater_name)
	    combine(nrow => :count)
	    select(:repeater_name)
	end
	n_hold = floor(Int, nrow(dataset)*hold_per)
	removeRdf = sample(selNames.repeater_name, n_hold, replace=false) ## removed 3 repeaters with up to 2 values givin ~ 5-6 samples

	new_set = filter(:repeater_name => x -> !any(x.==removeRdf), dataset)
	hold = filter(:repeater_name => x -> any(x.==removeRdf), dataset)

	
    return new_set, hold 
end

"""
	function trainTestSplit(df, testPercent)

	return train dataframe, test dataframe
"""
function trainTestSplit(df::DataFrame, testPercent::Real=0.1; source=false)

		repeater_df, non_repeater_df = populationSplit(df);

		## splitting data
		if source
			rep_train, rep_test = holdOutRep(repeater_df, testPercent);
		else
			rep_train, rep_test = holdOut(repeater_df, testPercent);
		end
		nrep_train, nrep_test = holdOut(non_repeater_df, testPercent);
		
		### constructing the new sets
		train_set = vcat(rep_train,nrep_train)
		test_set = vcat(rep_test, nrep_test)

	return train_set, test_set
end

## Rare events algorithm functions

"""
	Weghted logistic likelihood function
"""
function loglikeweighted(X, y, β,w)
	LL = 0
	η = X*β
	for i in range(1, size(X)[1]) 
		num = exp(y[i]*η[i])
		den = 1.0 + exp(η[i])
		LL += w[i]*log(num/den)
	end
	return LL
end

"""
	Deviation terminattion function
"""
function DEV(X, y, β,w)
	return -2*loglikeweighted(X, y, β,w)
end

"""
	Weghted logistic normal equation
"""
function WLS(X, W, z)
	    	
	    #Regular equations for weighted logistic
	    XtWX = X'*W*X
	    XtWz = X'*W * z
	    b = inv(XtWX) *XtWz
	    return b
end

"""
    Weight vector
"""
function weightVector(w0, w1, y)
	return w1* y .+ w0*(1 .- y)
end

function V(x)
    # inverse of V_i
    return x * (1 - x)
end

"""
    Rare-Event Weighted Logistic Regression algorigthm  (RE-WLR)
    The algorigthn is based on the paper:
        Maher Maalouf, Mohammad Siddiqi,
        Weighted logistic regression for large-scale imbalanced and rare events data,
        2014,
        https://doi.org/10.1016/j.knosys.2014.01.012.
        (https://www.sciencedirect.com/science/article/pii/S0950705114000239)

    WLRRE(X, y, w0,w1; verbose=false, maxIt = 20)
"""
function WLRRE(X, y, w0,w1; verbose=false, maxIt = 20)
    # Step 1
    # Initialise probability values of 0.5
    betainit = zeros(size(X)[2])
    P = logistic.(X*betainit)
    delta = 1
    i = 0
    LLW = 0
	b = 0
	bCorr = 0
	w = weightVector(w0, w1, y)
    while delta > 1e-6 && (i < maxIt)
        # Step 2
		Va = V.(P)
        # Given current π, calculate z and D = diag(vw)
        Z = X*betainit + diagm(1 ./ Va) * (y - P)
		D = diagm(Va .* w)
		Q = X * inv(X'*D*X)  * X'
        Q_m = diag(Q)
		ξ = 0.5*Q_m .*((1+w1) .*P .- w1)
		# Step 3
        # Given current z and W, calculate β
        b = WLS(X, D, Z)
        bCorr = WLS(X, D, ξ)
        # Step 4
        # Given current β, calculate π 
        P = logistic.(X * (b))
        betainit = b
        # Step 5
        # Calculate and compare log-likelihoods
		LLOld = LLW
		LLW = -2*loglikeweighted(X, y, b, w)
		delta = abs((LLOld - LLW)/LLW)
        i += 1
	end
	if verbose
		if delta < 1e-6
	    	println(string("WLRRE completed on $(i) iterations"))
		else
			println(string("WLRRE stopped at $(i) iterations"))
		end
	end

    unbiasβ = b - bCorr;
    probUnbiasβ = logistic.(X * (unbiasβ));
    return  unbiasβ, probUnbiasβ
end


"""
    Predict function for the logistic regression model
    predict(X::Vector, betas::Vector)
"""
function predict(X::Vector, betas::Vector)
	logistic.(Transpose(X) * betas)
end

"""
    Predict function for the logistic regression model
    predict(X::Vector, betas::Vector)
"""
function predict(X::Matrix, betas::Vector)
	logistic.(X * betas)
end


"""
    calculateWeights(tau, resp)
    
    Calculate the tau weights for to pass for the regression model
"""
function calculateWeights(tau, resp)
    ybar = sum(resp)/length(resp)
    ## franction weights
    wts0 = (1-tau)/(1-ybar)
    wts1 = tau/ybar
    return wts0, wts1
end
