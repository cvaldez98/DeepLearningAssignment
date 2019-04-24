%% MiniBatchGD
%
% Perform the model update.
% where X contains all the training images, Y the labels for the training
% images, W, b are the initial values for the network’s parameters, lambda
% is the regularization factor in the cost function and GDparams is an object containing the parameter values n batch, eta
% and n epochs
%
function NetParams = MiniBatchGDBN(X, Y, GDparams, NetParams, lambda, Xval, Yval)
    
    batch_size = int32(GDparams.n_batch);
    plot_idx = 1;
    eta_min = 1e-5;
    eta_max = 1e-1;
    n_s = GDparams.n_step;
    cycles= GDparams.n_cycles;
    
    Rounds=2*(cycles*n_s);
    
    % matrices to save cost and accuracy after each epoch
    C = zeros(Rounds,4);
    A = zeros(Rounds,2);
    etas = zeros(Rounds,1);
    
    eta = eta_min;
    eta_step = (eta_max-eta_min)/(n_s);
    start_index  = 1;
    sign = 1;
    
    for rounds = 1 : Rounds
        if mod(rounds,100)==0
            fprintf("Round %d of %d : %.2f %%\n",rounds,Rounds,100*rounds/Rounds);
        end
        if start_index >= size(X,2)
            start_index = 1;
        end
        %get indexes of the batch data
        idx = start_index : min(start_index + batch_size -1, size(X,2));

        % index the actual data
        X_batch = X(:,idx);
        Y_batch = Y(:,idx);

        %update starting index
        start_index = start_index + batch_size;

        P = EvaluateClassifierBN(X_batch, NetParams);
        [grad_W, grad_b,grad_gammas, grad_betas] = ComputeGradientsBN(X_batch, Y_batch, P,NetParams, lambda);
        
        for k=1:length(NetParams.W)
            NetParams.W{k} = NetParams.W{k} - eta * grad_W{k};
            NetParams.b{k} = NetParams.b{k} - eta * grad_b{k};
            
            if k < length(NetParams.W)
                NetParams.gammas{k} = NetParams.gammas{k}- eta *grad_gammas{k} ;      
                NetParams.betas{k}= NetParams.betas{k} - eta * grad_betas{k};
            end
        end
        
        %save statistics each 100 iterations
        if mod(rounds,100)==0
            C(plot_idx,1) = ComputeCostBN(X, Y, NetParams, lambda);
            C(plot_idx,2) = ComputeCostBN(Xval, Yval, NetParams, lambda);
            C(plot_idx,3) = ComputeCostBN(X, Y, NetParams, 0);
            C(plot_idx,4) = ComputeCostBN(Xval, Yval, NetParams, 0);

            A(plot_idx,1) = compute_accuracy(X, Y,NetParams);
            A(plot_idx,2) = compute_accuracy(Xval, Yval,NetParams);
            etas(plot_idx) = eta;
            plot_idx = 1 + plot_idx;
        end
        %update eta
        eta = eta + sign*eta_step;
        if(eta >= (eta_max-1e-9))
            eta = eta_max;
            sign = -sign;
        elseif (eta <= (eta_min+1e-9))
            eta = eta_min;
            sign = -sign;
        end
    end
    
    % plot loss and accuracy of the network
    x = 1 : plot_idx-1;
    plot(100*x, C(x,1),100*x, C(x,2));
    xlabel("Step")
    ylabel("Loss")
    saveas(gcf,'lossBN.pdf')
    figure();
    plot(100*x, C(x,3),100*x, C(x,4));
    xlabel("Step")
    ylabel("Cost")
    saveas(gcf,'costBN.pdf')
    figure();
    plot(100*x, A(x,1),100*x, A(x,2));
    xlabel("Step")
    ylabel("Accuracy")
    saveas(gcf,'accuracyBN.pdf')
    %figure();
    %plot(x-1, etas);
    %save("test_fig3","C","A");
    % set return values
    
end



function acc = compute_accuracy(X,Y,NetParams)

y = vec2ind(Y);

P = EvaluateClassifierBN(X, NetParams);

[~, argmax] = max(P{end,3});

R = argmax == y;

acc = double(sum(R))/size(Y,2)*100;

end