module PreProcessing
using CSV
using DataFrames
using Statistics

export readRN3, readcat1

# Define your functions, types, and variables here

function readRN3()
    RN3 = CSV.read("./data/chimefrb2023repeaters.csv",DataFrame);
    return reduceDataFrame(RN3);
end

function readcat1()
    Cat1 = CSV.read("./data/chimefrbcat1.csv",DataFrame);
    return reduceDataFrame(Cat1);
end

function replaceString(frb, col)
        try 
            withdfib = parse(Float64, frb[col])
            return withdfib;
        catch
            withfib = parse(Float64, strip(frb[col], '<'))
            return withfib;
        end
end

function searchString(df, col)
    replacedColumn = Float64[];
    for frb in eachrow(df)
        push!(replacedColumn, replaceString(frb,col))
    end
    return replacedColumn;
end

function reduceDataFrame(df; cols = ["tns_name","repeater_name", "dm_fitb","bc_width","scat_time","flux","fluence","sub_num","width_fitb","sp_idx","sp_run","high_freq","low_freq","peak_freq"])
    numCols = filter(x->any(x.!=["scat_time", "width_fitb"]), cols )
    featdf = select(df, numCols);

    featdf.scat_time = searchString(df, "scat_time");
    if eltype(df.width_fitb) == String15
        featdf.width_fitb = searchString(df, "width_fitb");
    else
        featdf.width_fitb = df.width_fitb;
    end

    groupfeatdf = groupby(featdf, :tns_name);

    redufeatdf = combine(groupfeatdf, :repeater_name=>unique, :sub_num => maximum, Not(:repeater_name,:tns_name, :sub_num) .=> mean; renamecols=false);

    return redufeatdf;
end

end