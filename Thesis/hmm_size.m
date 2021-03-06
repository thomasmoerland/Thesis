function [outout] = hmm_size(models, step, epochs, mydata, K, dim, starttype, max_EM, U)
% Wrapper to assess performance of optimal model

% model can be 'clustered', 'EM
N = size(mydata,1);
actions = unique(cell2mat(mydata(:,1)));
precision= [];
outout = [];
video_index = cell2mat(mydata(:,1));

for rep=1:epochs
    % make splits in set
    sets = cell(step,1);
    for ll=1:15
        sub1 = find(video_index == actions(ll));
        sub1 = sub1(randperm(numel(sub1)));
        rest = mod(numel(sub1),1/(1/step));
        sub2 = reshape(sub1(1:(end-rest)),step,floor(numel(sub1)/step));
        sub3 = sub1((end-rest+1):end);
        for j=1:step
            sets{j} = cat(1,sets{j},sub2(j,:)');
        end
        for m=1:numel(sub3)
            take_em = randi(step,1);
            sets{take_em} = cat(1,sets{take_em},sub3(m));
        end
    end
    for i=1:3
        
        for stepsize = 1:step
            sets = sets(randperm(step,step));
            train = mydata(cell2mat(sets(1:stepsize)),:);
            test = mydata(cell2mat(sets((stepsize+1):end)),:);
            [train test] = pca_adjust(train, test, dim, false);
            
            precision_step = [];
            for nn=1:3
                model = models{nn};
                [A2, mu2, Sigma2, actions] = models_init(train, K, 'clustered');
        
                % Estimate model
                if strcmp(model,'EM')
                    [A2 mu2 Sigma2 A_store mu_store  Sigma_store loglik_store]  = train_EM(train, A2, ...
                                    mu2, Sigma2, actions, 15, starttype);
                end
                if strcmp(model,'EBW')
                     [A2, mu2, Sigma2, A_store, mu_store, Sigma_store, loglik_store] = train_EBW(train, A2, ...
                                mu2, Sigma2, actions, 25, starttype, U);
                end

                % Test error
                [ LL_frame ] = frame_lik(test, A2, mu2, Sigma2);
                [pred_table2 precision2] = classify(test, actions, LL_frame);
                
                precision = cat(1,precision,precision2);
            end
            
            precision_step = cat(2,precision_step,precision);
        end
        outout = cat(3,outout,precision_step);
    end
end

end

