%> In this type of SODATAITEM, the sovalues object contains a values.dia field
classdef soitem_merger_merger_fitest < soitem
    properties
        %> Array of soitem_merger_fitest objects
        items = soitem_diachoice.empty();
    end;
    
    % -*-*-*-*-*- TOOLS
    methods
        %> @param varargin see @ref get_biocomparisontable
        %> @return [s, M, titles] @s is HTML; M is the comparison cube; @c titles describes each row in M
        %>
        %> @sa get_biocomparisoncube()
        function [s, Y] = html_rates(o)
            so = o.get_sovalues();
            Y = so.get_Y('rates');
            means = mean(Y, 3);
            stds = std(Y, [], 3);
            s = ['<center>', html_table_std(round(means*100)/100, round(stds*100)/100, so.ax(1).ticks, so.ax(2).ticks), '</center>', 10];
        end;
    end;        
    
    %------> Low-level tools
    methods
        
        function out = get_sovalues(o)
            ni = numel(o.items);

            out = sovalues();
            out.chooser = o.items(1).sovalues.chooser;
            out.ax(1) = o.items(1).sovalues.ax(1);
            for i = 1:ni
                if i == 1
                    out.values = o.items(i).sovalues.values(:);
                else
                    out.values(:, i) = o.items(i).sovalues.values(:);
                end;
                titles{i} = o.items(i).title;
            end;
            
%             out.ax(1) = raxisdata();
%             out.ax(1).label = 'System';
%             out.ax(1).values = 1:ni;
%             out.ax(1).legends = titles;
            
            out.ax(2) = raxisdata();
            out.ax(2).label = 'Model';
            out.ax(2).ticks = titles;
        end;
    end;
end