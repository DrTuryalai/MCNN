clc;
clear all;
close all;

Train_data = fullfile(matlabroot,'toolbox','nnet','nndemos','nndatasets','Train_RE_TFR_strong_wifi'); %Load training data
Test_data = fullfile(matlabroot,'toolbox','nnet','nndemos','nndatasets','Test_data_TFR_strong_wifi','snr_-2_f1'); %Load test data individually for each FHSS signal at a certain SNR

k = 5;

imds = imageDatastore(Train_data,'IncludeSubfolders',true,'LabelSource','foldernames');
imds2 = imageDatastore(Test_data,'IncludeSubfolders',true,'LabelSource','foldernames');
[temp1, temp2, temp3, temp4, temp5] = splitEachLabel(imds,0.2,0.2,0.2,0.2);

partStores = {temp1.Files, temp2.Files, temp3.Files, temp4.Files, temp5.Files};

idx = crossvalind('Kfold', k, k)
for i = 1:k
    val_idx = (idx == i);
    train_idx = ~val_idx;

    val_Store = imageDatastore(partStores{val_idx}, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
    train_Store = imageDatastore(cat(1, partStores{train_idx}), 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

    imdsTest = imds2;

    inputSize = [224 224 3];
    numClasses = 6;

    layers = [
    imageInputLayer(inputSize)
    convolution2dLayer([3 9],8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer([1 3],'Stride',2,'Padding','same')
    
    convolution2dLayer([3 7],16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer([1 3],'Stride',2,'Padding','same')
    
    convolution2dLayer([3 5],32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    
    averagePooling2dLayer([1 3],'Stride',2,'Padding','same')
    
    
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

    options = trainingOptions('adam', 'InitialLearnRate',0.01, 'LearnRateSchedule','piecewise', 'LearnRateDropPeriod',4, 'LearnRateDropFactor',0.1, 'MaxEpochs',6, 'MiniBatchSize', 64, 'ValidationData',val_Store, 'ValidationFrequency',50, 'Shuffle','every-epoch', 'ValidationPatience',6, 'Verbose',true,'Plots','training-progress');
    net = trainNetwork(train_Store,layers,options);
end

YPred = classify(net,imdsTest);
YTest = imdsTest.Labels;
PCC = mean(YPred == YTest)