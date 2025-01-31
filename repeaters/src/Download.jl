using Downloads


export readRN3, readcat1

# Define your functions, types, and variables here

function downloadData(path)
    http_response= Downloads.download(path)
    return http_response;
end

function readRN3(path="")
    if path == ""
        RN3 = CSV.read(downloadData("https://storage.googleapis.com/chimefrb-dev.appspot.com/repeater_catalog/chimefrb2023repeaters.csv"),DataFrame);
    else
        RN3 = CSV.read(path,DataFrame);
    end
    return reduceDataFrame(RN3);
end

function readcat1(path="")
    if path == ""
        Cat1 = CSV.read(downloadData("https://storage.googleapis.com/chimefrb-dev.appspot.com/catalog1/chimefrbcat1.csv"),DataFrame);
    else
        Cat1 = CSV.read(path,DataFrame);
    end
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
