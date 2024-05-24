
function [border, border_slice, sf_nums,data_mean_cell, W_cell,GMMmodel_cell,...
    BID_ctrl_limit_matrix, BID_ctrl_limit_matrix_combined,Cont_BID_CL_cell]...
    = modeling(data_train, data_train_diff, qieruzhi,indicate_variable,...
               confidence_level, alpha)
% modeling function
% inputs:
%       data_train(samples*variables): training data
%       data_train_diff(samples*variables): first order difference of
%       training data
%       qieruzhi: the samples with the value of indicate_varibale lower 
%                 than qieruzhi will be discarded.
%       indicate_variable: indicates which column of the data matrix the
%                          indicate variable is located.(ָʾ������ǩ)
%       confidence_level: confidence level of control limit.�����������Ŷȣ�
%       alpha: relaxing factor.(����ϵ�� )
% outputs:
%       border: the borders of condition segments��ÿһ�εı߽磩
%       border_slice: the borders of condition slices��ÿһƬ�ı߽磩
%       sf_num: the number of slow features��������������
%       data_mean_cell: the mean vectors of condition slices��ÿһƬ�ľ�ֵ��
%       W_cell: the coefficient matrices of condition segments��SFA�任����
%       GMMmodel_cell: the GMMs of condition segments��GMMģ�ͣ�
%       BID_ctrl_limit_matrix: the control limits of four BID indices��4��BIDָ������ޣ�
%       BID_ctrl_limit_matrix_combined: the control limit of conbined BID index�����ָ������ޣ�

%% �ж������Ƿ�Ϸ� assign confidence_level automatically
% if ~isvector(x)
%     error('Input must be a vector')
% end
if ~exist('confidence_level', 'var') || isempty(confidence_level)
    confidence_level = 0.99;
end
%% ����Ԥ���� data preprocessing
% data_train = fillmissing(data_train,'linear');
% data_train_diff = diff(data_train);
% data_train(1,:)=[];

[num_samples, num_variables] = size(data_train);
% �������趨 set the values of hyper parameters
length_min = (num_variables-1)*3*5;% ���û������ݵ�Ԫ��̳��� set the minimum
                              % number of samples in each condition slices
N = floor(num_samples/(0.01*length_min));
% ȥ��ָʾ����ֵ��������ֵ������  discard the samples with the value of
% indicate_varibale lower than qieruzhi
power = data_train(:, indicate_variable);  % ���û��ֱ�����
id = find(power<qieruzhi);
data_train(id,:) = [];
data_train_diff(id,:) = [];
power = data_train(:, indicate_variable);

%% ����СƬ divide original data matrix into different data slices
power_max = max(power);
power_min = min(power);
delta_power = (power_max - power_min)/N;
data_slices = cell(N,1);         % the resulting data slices are stored in a cell
data_diff_slices = cell(N,1);
indicate_variable_slices = cell(N,1);
length = zeros(N,1);
for i = 1:N
    k = find(power>=(power_min+(i-1)*delta_power) & power<(power_min+i*delta_power));
    length(i) = size(k, 1);
    data_slices{i} = data_train(k,[1:indicate_variable-1, indicate_variable+1:end]);
                  %the indicate variable will not be considered when modeling
    data_diff_slices{i} = data_train_diff(k, [1:indicate_variable-1, indicate_variable+1:end]);
    indicate_variable_slices{i} = data_train(k,indicate_variable);
end

%% data slices combinations
% combine adjacent data slices such that the number of samples in each data
% slices is larger than the minimum requirement.
i = 1;
j = 1;
m = 1;
while j < N
    
    if i >= size(data_slices,1)
        break
    end
    
    if size(data_slices{i}, 1)<length_min
        data_slices{i} = [data_slices{i};data_slices{i+1}];
        data_slices(i+1) = [];
        data_diff_slices{i} = [data_diff_slices{i};data_diff_slices{i+1}];
        data_diff_slices(i+1) = [];
        indicate_variable_slices{i} = [indicate_variable_slices{i};indicate_variable_slices{i+1}];
        indicate_variable_slices(i+1) = [];
        j = j + 1;
        m = m + 1;
    else
        i = i + 1;
        j = j + 1;
    end
end
% ������һ���������ݵ�Ԫ������������С����С��������������������ݾ�����ǰһ���ϲ���
if size(data_slices{end},1)<length_min
    data_slices{end-1} = [data_slices{end-1};data_slices{end}];
    data_slices(end) = [];
    data_diff_slices{end-1} = [data_diff_slices{end-1};data_diff_slices{end}];
    data_diff_slices(end) = [];
    indicate_variable_slices{end-1} = [indicate_variable_slices{end-1};indicate_variable_slices{end}];
    indicate_variable_slices(end) = [];
end

%% �������ݵ�ԪSFA���� SFA for each data slices
% ��ÿ��������Ԫ���ݾ����׼��
N = size(data_slices, 1); %������Ļ������ݵ�Ԫ������the number of data slices
                          %after conbination
thresholdv = 1e-3;%SFA�׻���ֵ the whitening threshold for SFA

data_slices_normalized = cell(N,1); %data_diff_slices_normalized = cell(N,1);
data_mean_cell = cell(N,1);  %data_std_cell = cell(N,1);
pc_nums = zeros(N, 1);
sf_nums = zeros(N, 1);
border_slice = zeros(N+1,1);
border_slice(1) = power_min;
for i = 1:N
    border_slice(i+1) = max(indicate_variable_slices{i});
    data_mean_cell{i} = mean(data_slices{i});
    %    data_std_cell{i} = std(data_slices{i});
    data_slices_normalized{i} = (data_slices{i}-repmat(data_mean_cell{i},size(data_slices{i},1),1));%./data_std_cell{i};
    %    data_diff_slices_normalized{i} = data_diff_slices{i}./data_std_cell{i};
    [pc_nums(i), sf_nums(i)] = find_pcs_num(data_slices_normalized{i}, ...
        data_diff_slices{i}, thresholdv);
end

%% �ҵ����ִ���������Ԫ����������������
%Find the number of principal components and the number of slow features that 
%appear the most frequently  
table1 = tabulate(pc_nums);
maxcount = max(table1(:,2));
[row1,~]=find(table1(:,2)==maxcount);
pc_num = table1(row1,1);
pc_num = pc_num(1);

table2 = tabulate(sf_nums);
maxcount = max(table2(:,2));
[row2,~]=find(table2(:, 2)==maxcount);
sf_num = table2(row2,1);
sf_num = sf_num(1);

%% ��������Ƭ������ estimate control limit for each condition slices
ctrl_T2s = zeros(N,1);
ctrl_T2f = zeros(N,1);
for i = 1:N
    [~, ~, ~, ~, ~, ctrl_T2s(i), ctrl_T2f(i)] = cal_monitoring_statistics(...
        data_slices_normalized{i}, data_diff_slices{i}, confidence_level, pc_num, sf_num);
end
%% �ӽ׶λ��� divide condition slices into different condition segments
N  = size(data_slices, 1);
data_segments = data_slices;
data_segments_normalized = data_slices_normalized;
data_diff_segments = data_diff_slices;
indicate_variable_segments = indicate_variable_slices;
label = 1; %��ǩ segment label
i = 1;
k = 1;

while i <= N
    j = 1;
    while j <= N-i
        result = more_than_alpha(data_slices_normalized, data_diff_slices, i, j,...
            sf_num, ctrl_T2s, ctrl_T2f, alpha, confidence_level, thresholdv);
        if result == 1       %result==1��ζ�ŵ�i+j��slice���ܻ��뵱ǰ�ӽ׶�
            %��������µ�labelֵ��Ϊ��i+j��slice������label
            %Ȼ��ӵ�i+j��slice��ʼ�µ�ѭ����
            label = label + 1;
            k = k + 1;
            break
        else      %result==0��ζ�ŵ�i+j��slice�Ǵ��ڵ�ǰ�ӽ׶Σ�
            %������ͬ��ǩ�����뵱ǰ�ӽ׶Ρ�
%             data_segments_normalized{k+1}(:, num_variables+1) = label;
            data_segments_normalized{k} = [data_segments_normalized{k};data_segments_normalized{k+1}];
            data_segments_normalized(k+1) = [];
%             data_segments{k+1}(:, num_variables+1) = label;
            data_segments{k} = [data_segments{k};data_segments{k+1}];
            data_segments(k+1) = [];
%             data_diff_segments{k+1}(:, num_variables+1) = label;
            data_diff_segments{k} = [data_diff_segments{k};data_diff_segments{k+1}];
            data_diff_segments(k+1) = [];
            indicate_variable_segments{k} = [indicate_variable_segments{k};indicate_variable_segments{k+1}];
            indicate_variable_segments(k+1) = [];
            j = j + 1;
        end
    end
    i = i + j
end

%% ȷ�����ֱ߽� determine the borders of condition segments
n = size(indicate_variable_segments, 1);
border = zeros(n+1,1);
border(1) = power_min;
for i = 1:n
    border(i+1) = max(indicate_variable_segments{i});
end

%% ѵ����GMM���� training GMM
n = size(data_segments_normalized, 1);
rng(42) %���ֽ�� for reproducing the results
W_cell = cell(n,1);
GMMmodel_cell = cell(n,4);
BIC_cell = cell(n,4);
D_cell = cell(n,4);
Pix_cell = cell(n,4);
Cont_BID_CL_cell = cell(n, 4);
nbStates_matrix = zeros(n,4);
nbStates_max =  8; %��ʼ��˹Ԫ���ĸ��� the initial number of components

for k = 1:n
    
    X_train = data_segments_normalized{k}(:, 1:end);
    X_train_diff = data_diff_segments{k}(:, 1:end);
    
    [T, W, S] = sfa(X_train, X_train_diff, pc_nums(k));
    Ts = T(:, 1:sf_nums(k));
    Tf = T(:, sf_nums(k)+1:end);
    Ss = S(:, 1:sf_nums(k));
    Sf = S(:, sf_nums(k)+1:end);
    W_cell{k} = W;
    features = {Ts; Tf; Ss; Sf};
    for i =1:4
        data_off = features{i};
        BIC = zeros(1, nbStates_max);
        GMMmodels = cell(1,nbStates_max);
        options = statset('MaxIter',2000);
        %ȷ��GMM�ֳɶ�������� determine the best number of components for GMM
        for j = 1:nbStates_max
            if i <= 2
                GMMmodels{j} = fitgmdist(data_off, j,'RegularizationValue',1e-4,'CovarianceType','diagonal','Options',options);
                BIC(j) = GMMmodels{j}.BIC;
            else
                GMMmodels{j} = fitgmdist(data_off, j,'RegularizationValue',1e-4,'Options',options);
                BIC(j) = GMMmodels{j}.BIC;
            end
        end
        
        [minBIC,numComponents] = min(BIC);
        BestModel = GMMmodels{numComponents};
        BIC_cell{k, i} = BIC;
        Pix_cell{k ,i} = posterior(BestModel, data_off);
        D_cell{k ,i} = mahal(BestModel, data_off);
        GMMmodel_cell{k, i} = BestModel;
        nbStates_matrix(k, i) = numComponents;
        Cont_BID = contribute_plot_GMM_GDC(X_train,X_train_diff, data_off, W_cell{k}, sf_nums(k), i, BestModel, Pix_cell{k ,i});
        Cont_BID_CL = zeros(1,size(Cont_BID,2));
        for m = 1:size(Cont_BID,2)
            Cont_BID_CL(1,m)=ctrl_limit_compute(Cont_BID(:,m),confidence_level);
        end
        Cont_BID_CL_cell{k, i} = Cont_BID_CL;
    end
end

%% ����BID�Ŀ����� estimate the control limit for BID
n = size(data_segments_normalized, 1);
BID_cell = cell(n, 4);
BID_ctrl_limit_matrix = zeros(n, 4);
BID_ctrl_limit_matrix_combined = zeros(n, 1);
for k = 1:n
    for i = 1:4
        D = D_cell{k ,i};
        Pix = Pix_cell{k, i};
        BID_cell{k,i} = diag(D*Pix');
        BID_ctrl_limit_matrix(k, i) = ctrl_limit_compute(BID_cell{k,i},confidence_level);
    end
    BID_combined =  BID_cell{k,1}./BID_ctrl_limit_matrix(k, 1) + BID_cell{k,2}./BID_ctrl_limit_matrix(k, 2);
    BID_ctrl_limit_matrix_combined(k, 1) = ctrl_limit_compute(BID_combined,confidence_level);
end


end


