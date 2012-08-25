%> @brief Visualization - Histograms from @ref log_celldata
%>
%> @todo needs implementing the properties GUI
classdef vis_log_celldata < vis
    properties
        idx = 1;
        flag_std = 1;
    end;
    
    methods
        function o = vis_log_celldata(o)
            o.classtitle = 'Learning Curve';
            o.inputclass = {'log_celldata'};
            o.flag_params = 0; % Temporarily
        end;
    end;
    
    methods(Access=protected)
        function [o, out] = do_use(o, obj)
            out = [];
            obj.draw(o.idx, o.flag_std);
        end;
    end;
end