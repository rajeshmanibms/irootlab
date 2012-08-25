%> @brief Trained Mean-centering
classdef pre_meanc < pre
    properties(SetAccess=protected)
        means = [];
    end;
    
    methods
        function o = pre_meanc(o)
            o.classtitle = 'Trained Mean-centering';
            o.flag_trainable = 1;
            o.flag_params = 0;
        end;
    end;
    
    methods(Access=protected)

        
        % Trains the block: records the variable means
        function o = do_train(o, data)
            o.means = mean(data.X, 1);
        end;
        
        % Applies block to dataset
        function [o, data] = do_use(o, data)
            X = data.X;
            data.X = X-repmat(o.means, size(X, 1), 1);
        end;
    end;
end