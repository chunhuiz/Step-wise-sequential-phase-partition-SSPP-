%% prepare training data and test data
clc
clear
close all
addpath SSPP/
addpath utils/
load('data/d11_te.mat') % the data set should includes a normal and an abnormal data matrix
data = data';
[sample,variable] = size(data(:,[9,51]));
data_train = ones(sample,variable,3); % samples*variables*batch
data_test = ones(sample,variable,3);
for i = 1:3
    data_train(:,:,i) = data(:,[9,51]);
    data_test(:,:,i) = data(:,[9,51]);
end
%% modeling and monitoring
confidence_level = 0.99; %confidence level of the control limits
alpha = 1.5; %relaxing factor.Please change this parameters according to your needs. 
model_directory_and_name = 'trained_model/model.mat';%the directory to
                       %save the model(including the name of the model)
                       %Please change this parameters according to your needs. 
main_modeling(data_train,confidence_level,alpha,model_directory_and_name)

[BID, BID_combined, BID_ctrl_limit, BID_ctrl_limit_combined]=...
                       main_monitoring(data_test, model_directory_and_name);

%%
figure()
plot(data_train(:,:,1))