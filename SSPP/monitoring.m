function [BID, BID_combined, BID_ctrl_limit, BID_ctrl_limit_combined, Cont_BID, Cont_BID_CL] = monitoring(data_test,data_test_diff,border, border_slice, sf_nums,...
    indicate_variable, data_mean_cell, W_cell, GMMmodel_cell,...
    BID_ctrl_limit_matrix, BID_ctrl_limit_matrix_combined, Cont_BID_CL_cell)

% ��������Ϊ inputs: data_test(���������)��border��ÿһ�εı߽磩, border_slice��ÿһƬ�ı߽磩,
%   sf_num��������������, indicate_variable��ָʾ������ţ�, data_mean_cell��ÿһƬ�ľ�ֵ��,
%   W_cell��SFA�任����, GMMmodel_cell��GMMģ�ͣ�,BID_ctrl_limit_matrix��4��BIDָ������ޣ�,
%   BID_ctrl_limit_matrix_combined�����ָ������ޣ�

% �������Ϊ outputs��BID���ĸ����ͳ�������� BID_combined�����ָ�꣩�� 
%       BID_ctrl_limit���ĸ����ͳ���������ޣ��� BID_ctrl_limit_combined�����ͳ���������ޣ�
% *please refer to the comments of modeling if you want to know the meaning
% of each parameters.
X_test = data_test;
X_test_diff = data_test_diff;

[n, m] = size(X_test);

BID = zeros(n,4); 
BID_ctrl_limit = zeros(n, 4);
BID_ctrl_limit_combined = zeros(n, 1);
BID_combined = zeros(n,1);
Cont_BID = zeros(n,m-1,4);
Cont_BID_CL = inf+zeros(n,m-1,4);

for i=1:n
    if X_test(i, indicate_variable)>= max(border) || X_test(i, indicate_variable)< min(border)
        BID(i,:) = -ones(1,4);
        BID_combined(i,1) = -1;
        BID_ctrl_limit(i,:) = zeros(1,4);
        BID_ctrl_limit_combined(i,1) = 0;
    else
        
        J = border - X_test(i, indicate_variable);%determine which condition
                        % segments the sample belong to so that corresponding model is called. ȷ��������Ӧ�ĸ����ʶ��Ե���ģ��
        j = sum(J <= 0);
        Y =  border_slice- X_test(i, indicate_variable); %%determine which condition
                        % segments the sample belong to so that corresponding mean vector is used to standardize the sample. ȷ��������Ӧ�ĸ�����Ƭ�Խ��б�׼��
        y = sum(Y <= 0);
        
        X_test_scaled = (X_test(i,[1:indicate_variable-1, indicate_variable+1:end])-data_mean_cell{y});
        X_test_scaled_diff = X_test_diff(i, [1:indicate_variable-1, indicate_variable+1:end]);
        T = X_test_scaled*W_cell{j};
        Ts = T(:, 1:sf_nums(j));
        Tf = T(:, sf_nums(j)+1:end);
        S = X_test_scaled_diff*W_cell{j};
        Ss = S(:, 1:sf_nums(j));
        Sf = S(:, sf_nums(j)+1:end);
        features = {Ts; Tf; Ss; Sf};
        for k =1:4
            data_on = features{k};
            Pix = posterior(GMMmodel_cell{j, k}, data_on);
            D = mahal(GMMmodel_cell{j, k}, data_on);
            GMM_model = GMMmodel_cell{j, k};
            Cont_BID(i,:,k) = contribute_plot_GMM_GDC(X_test_scaled,X_test_scaled_diff, data_on, W_cell{j}, sf_nums(j), k, GMM_model, Pix);
            BID(i, k) = D*Pix';
            BID_ctrl_limit(i, k) = BID_ctrl_limit_matrix(j, k);
            Cont_BID_CL(i,:,k) = Cont_BID_CL_cell{j,k};
        end
        BID_combined(i, 1) = BID(i, 1)./BID_ctrl_limit(i, 1) + BID(i, 2)./BID_ctrl_limit(i, 2);
        BID_ctrl_limit_combined(i, 1) = BID_ctrl_limit_matrix_combined(j, 1);
    end
end

end