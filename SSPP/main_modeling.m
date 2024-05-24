
function main_modeling(data_train,confidence_level, alpha, model_directory_and_name)
%% 建模 modeling
% inputs:
%       data_train(samples*variables*batch): training data
%       confidence_level: confidence level of control limit.（控制限置信度）
%       alpha: relaxing factor.
%       model_directory_and_name: the directory to save the model(including
%                   the name of the model)e.g. 'C:\Users\Desktop\model.mat'

% the output is a file named as 'model.mat'

% 3d to 2d
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

qieruzhi = 0; % the samples with the value of indicate_varibale lower 
%                 than qieruzhi will be discarded, default 0.
indicate_variable = num_variables+1;% indicates which column of the data matrix the
%                       indicate variable is located, default num_variables+1, i.e.,...
%                       divide based on time step.(指示变量标签)
[border, border_slice, sf_nums,data_mean_cell, W_cell, GMMmodel_cell,...
             BID_ctrl_limit_matrix, BID_ctrl_limit_matrix_combined, Cont_BID_CL_cell]...
                = modeling(data_train, data_train_diff, qieruzhi, indicate_variable, confidence_level, alpha);
model = struct;
model.border = border;
model.border_slice = border_slice;
model.indicate_variable = indicate_variable;
model.sf_nums = sf_nums;
model.data_mean_cell = data_mean_cell;
model.W_cell = W_cell;
model.GMMmodel_cell = GMMmodel_cell;
model.BID_ctrl_limit_matrix = BID_ctrl_limit_matrix;
model.BID_ctrl_limit_matrix_combined = BID_ctrl_limit_matrix_combined;
model.Cont_BID_CL_cell = Cont_BID_CL_cell;
save(model_directory_and_name, 'model');

end