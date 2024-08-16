export plotTau

"""
    plotTau(dfstat, label::String; xmin=0.1, xmax=0.9, title="Repeaters", ylabel="Percentage/100" )

    Plots the median, min and max values of the metric for each tau value

    Arguments:
        dfstat: The dataframe with the metric values
        label::String: The label to be used for the plot
        xmin=0.1: The minimum value of tau to be plotted
        xmax=0.9: The maximum value of tau to be plotted
        title="Repeaters": The title of the plot
        ylabel="Percentage/100": The label of the y-axis
"""
function plotTau(dfstat, label::String; xmin=0.1, xmax=0.9, title="Repeaters", ylabel="Percentage/100" )
	tauV = dfstat.tau
	plot(tauV, dfstat.med, ribbon=(dfstat.med-dfstat.Q1,dfstat.Q3-dfstat.med), label=label)
	plot!(tauV, dfstat.med, color=:purple, label="median")
	plot!(tauV, dfstat.min, color=:salmon, label="")
	plot!(tauV, dfstat.max, color=:salmon, label="95% confidence")
	title!(title)
	xlims!(xmin,xmax)
	xlabel!("τ")
	ylabel!("Percentage/100")
end

"""
    plotTau(dfstat; xmin=0.1, xmax=0.9, title="Repeaters", ylabel="Percentage/100" )

    Plots the median, min and max values of the metric for each tau value

    Arguments:
        dfstat: The dataframe with the metric values
        xmin=0.1: The minimum value of tau to be plotted
        xmax=0.9: The maximum value of tau to be plotted
        title="Repeaters": The title of the plot
        ylabel="Percentage/100": The label of the y-axis
"""
function plotTau(dfstat; xmin=0.1, xmax=0.9, title="Repeaters", ylabel="Percentage/100", Save=false, filename="Repeaters" )
	tauV = dfstat.tau
	plot(tauV, dfstat.med, ribbon=(dfstat.med-dfstat.Q1,dfstat.Q3-dfstat.med), label="IQR")
	plot!(tauV, dfstat.min, label="min")
	plot!(tauV, dfstat.max, label="max")
	title!(title)
	xlims!(xmin,xmax)
	xlabel!("τ")
	ylabel!("Percentage/100")
    if Save
        savefig("$(filename).png")
    end
end