using GLM
using repeaters

## Download data ##

## Downloads and reads the data from the links provided in the Download.jl file from CHIME website
RN3 = readRN3(); ## Repeater catalog
cat1 = readcat1(); ## Catalog 1

## Splitting the data ##

training, test = splitDataframe(cat1,RN3); ## Splitting the data into training/validation and test dataframes


## Model ##
## Define the formula for the logistic regression model specifying the dependent and independent variables
lgpeak = @formula(class ~ 1 + bc_width + Bandwith + sub_num + width_fitb + peak_freq)

## Define the tau values to be used for the weighted logistic regression
tauV = [0.1:0.01:0.9;];

## Rare Events classification procedure ##
vectorenhanced = modelStatsUn(training, lgpeak,tauV, 500,testPercent=0.2, source=true, progress="progressbar");

## Extracting the metrics ##
accuracyDF = extractmetricDataframe(vectorenhanced, Accuracy);
recallDF = extractmetricDataframe(vectorenhanced, Recall);
precisionDF = extractmetricDataframe(vectorenhanced, Precision);
f1score = extractmetricDataframe(vectorenhanced, F1Score);

## Plotting the metrics ##
plotTau(accuracyDF, "Accuracy", Save=true, filename="Accuracy");
plotTau(recallDF, "Recall", Save=true, filename="Recall");
plotTau(precisionDF, "Precision", Save=true, filename="Precision");
plotTau(f1score, "F1Score", Save=true, filename="F1Score");

## predictions
modelCoef = extractCoef(vectorenhanced, lgpeak); ## Extract the coefficients from the model
logModel = createLogisticModel(modelCoef, 0.1); ## Create the logistic model fromt he coefficients and the tau value
trueTestSet = extractTestModel(test, lgpeak); ## Extract the test set
sample = selectSample(trueTestSet, "FRB20180909A"); ## Select a sample from the test set
predictions = predict(logModel, sample); ## Predict the probabilities of the sample belonging to the class

## plot predictions histogram
plotPredictions(predictions, Save=true)

## wrapper function to save the coefficients
saveCoefficients(modelCoef, "savetest")