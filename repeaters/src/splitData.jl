
export splitDataframe

"""
	transformDataset(data::DataFrame)

	Preprocess the rows of the dataset to be used for training and testing

	return individualy reduced dataframe
"""
function transformDataset(data_df::DataFrame)
    
    ind_redu_df = @chain data_df begin
        DataFrames.transform(:repeater_name => ByRow(x -> x=="-9999" ? 0 : 1) => :class)
        DataFrames.transform([:high_freq,:low_freq] => ByRow((x,y) -> x-y) => :Bandwith)
        DataFrames.transform(:repeater_name => ByRow(y -> y=="-9999" ? "Nrep" : y) => :repeater_name)
        select(:tns_name, :repeater_name, :dm_fitb,:bc_width, :scat_time,:peak_freq, :Bandwith, :sub_num, :width_fitb,:class)
    end
    return ind_redu_df
end

"""
	splitDataframe(cat1_df::DataFrame, RN3_df::DataFrame)

	Takes the catalogue 1 and RN3 dataframes and splits them into Training/validation and true test sets

	Returns training/validation , true test
"""
function splitDataframe(cat1_df::DataFrame, RN3_df::DataFrame)

    ind_redu_df = transformDataset(cat1_df)
    ind_rn3_df = transformDataset(RN3_df)

    sharedList = semijoin(ind_redu_df, ind_rn3_df; on=:tns_name).tns_name # get the shared list of tns_names of cat1 in RN3
    
    removed1_redu_df = filter([:tns_name, :repeater_name] => (x,y) -> !any(x .== sharedList .|| y .== sharedList), ind_redu_df)
    removed1_rn3_df = filter([:tns_name, :repeater_name] => (x,y) -> !any(x .== sharedList .|| y .== sharedList), ind_rn3_df)
    trainingSet = vcat(removed1_redu_df, removed1_rn3_df)
    trueSet = filter([:tns_name, :repeater_name] => (x,y) -> any(x .== sharedList .|| y .== sharedList), ind_redu_df)
    trueSet.class .= 1
    return trainingSet, trueSet
end