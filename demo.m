%% prepare training data and test data
clc
clear
close all
addpath SSPP/
addpath base_model/
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

% tranform 3d data to 2d data
% training data
data_train_diff = diff(data_train,1,1); %first order difference of training data
data_train(1,:,:) = [];
[num_samples, num_variables, num_batches] = size(data_train);
for i = 1:num_samples
    data_train(i,num_variables+1,:) = i;
    data_train_diff(i,num_variables+1,:) = i;
end
data_train = permute(data_train, [1, 3, 2]);
data_train_diff = permute(data_train_diff, [1, 3, 2]);
data_train = reshape(data_train,[num_samples*num_batches, num_variables+1]);
data_train_diff = reshape(data_train_diff,[num_samples*num_batches, num_variables+1]);
% test data
data_test_diff = diff(data_test,1,1); %first order difference of training data
data_test(1,:,:) = [];
[num_samples, num_variables, num_batches] = size(data_test);
for i = 1:num_samples
    data_test(i,num_variables+1,:) = i;
    data_test_diff(i,num_variables+1,:) = i;
end
data_test = permute(data_test, [1, 3, 2]);
data_test_diff = permute(data_test_diff, [1, 3, 2]);
data_test = reshape(data_test,[num_samples*num_batches, num_variables+1]);
data_test_diff = reshape(data_test_diff,[num_samples*num_batches, num_variables+1]);
%% parameter setting 
% Important Note: Please change these parameters according to your needs. 
model_directory_and_name = 'trained_model/divided_models.mat';%the directory to
                       %save the model(including the name of the model)
confidence_level = 0.99; %confidence level of the control limits
alpha = 1.5; %relaxing factor.Please change this parameters according to your needs. 
lower_limit = 0; % the samples with the value of indicate_varibale lower 
%                 than lower_limit will be discarded, default 0.
indicate_variable = num_variables+1;% indicates which column of the data matrix is the
%                       indicate variable, default num_variables+1, i.e.,...
%                       divide based on time step.(指示变量标签)

%% initialize model
% Important Note: You can change base model according to your needs. 
% If so, you should prepare your own class based on the 'Base_model/SFA_class.m' .

% SFA as base model
thresholdv = 1e-3; % 白化阈值 the whitening threshold
monitoring_statistic_num = 4;% the number of monitoring statistic
base_model = SFA_class(thresholdv,confidence_level, monitoring_statistic_num);

% Uncomment the following code if you want to use PCA as base model
% %PCA as base model
% thresholdv = 95; % 白化阈值 the whitening threshold
% monitoring_statistic_num = 2;% the number of monitoring statistic
% base_model = PCA_class(thresholdv,confidence_level, monitoring_statistic_num);
%% modeling
divided_models = SSPP_modeling(data_train, data_train_diff, lower_limit, indicate_variable,...
                alpha, base_model);% the output is a struct named as 'divided_models'
save(model_directory_and_name, 'divided_models'); 
%% monitoring
% Important Note: This is an example showing how to use divided models for monitoring.
% You can use divided models for other purpose. 
% If so, you should replace the 'utils/monitoring.m' function with your own function. 
load(model_directory_and_name, 'divided_models');
base_model.feature_nums = divided_models.feature_nums;
[monitoring_statistics, ctrl_limits, divided_models] = monitoring(data_train, data_train_diff, data_test,data_test_diff, divided_models, base_model);
save(model_directory_and_name, 'divided_models'); 
%% show monitoring results
% figure()
% plot(data_train(:,:,1))
figure()
for i = 1:monitoring_statistic_num
    subplot(monitoring_statistic_num,1,i)
    plot(monitoring_statistics(:,i),'-b'), hold on
    plot(ctrl_limits(:,i),'--k')
end