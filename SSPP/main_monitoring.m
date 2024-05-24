function [BID, BID_combined, BID_ctrl_limit, BID_ctrl_limit_combined]=main_monitoring(data_test, model_directory_and_name)
%% ÔÚÏß¼à²â online monitoring
%   inputs£º
%       data_test(samples*variables)£º test data
%       model_directory_and_name: the directory to save the model(including
%                   the name of tha model) e.g. 'C:\Users\Desktop\model.mat' 
%   outputs:
%       BID(samples-1*4): BID monitoring indices
%       BID_combined(samples-1*1): combined BID monitoring index
%       BID_ctrl_limit(samples-1*4): corresponding control limit for each
%                                    samples and each monitoring indices.
%       BID_ctrl_limit_combined(samples-1*1):corresponding control limit
%                                           for BID_combined.
% 3d to 2d
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

% data_test_diff = diff(data_test);
% data_test(1,:) = [];
% % use time step as indicate variable
% sample_indicator = 1:size(data_test,1);
% sample_indicator = sample_indicator';
% data_test = [sample_indicator,data_test];
% data_test_diff = [sample_indicator,data_test_diff];

load(model_directory_and_name, 'model');
[BID, BID_combined, BID_ctrl_limit, BID_ctrl_limit_combined, ~, ~] = monitoring(data_test,data_test_diff,model.border, model.border_slice, model.sf_nums,...
    model.indicate_variable, model.data_mean_cell, model.W_cell, model.GMMmodel_cell,...
    model.BID_ctrl_limit_matrix, model.BID_ctrl_limit_matrix_combined, model.Cont_BID_CL_cell);

end