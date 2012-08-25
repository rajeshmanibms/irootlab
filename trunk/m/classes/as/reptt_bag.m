%> @ingroup as needsrevision
%>
%> @todo I will probably delete this class because I won't work with bagging anyway
%>
%> REPTT for bagging classifiers.
%>
%> Implements a nested loop: external is just a repetition ("bagging repetitions"); internal is a cross-validation loop.
%>
%> The particularity of a bagging train-test session is that each iteration of the bagging loop will do exactly the
%> same thing: train the classifiers with exactly the same data at each iteration
%>
%>
%> <h3>Usage</h3>
%> Calling go() will build the @ref blocks and @ref logs properties.
%>
%> The @ref blocks property will be a [no_datasets]x[no_blocks] matrix, where no_datasets is the number of sub-samples generated by the SGS;
%> @ref no_blocks is the number of elements of the @ref block_mold property. It is expected that the blocks are
%> classifiers (@ref clssr).
%>
%> The @ref reptt_bag::sgs property defines a number of sub-datasets. To each row of the @ref blocks property
%> corresponds one dataset, i.e., at every "bagging repetition" (bag_rep()), all the classifiers in the row will be
%> re-trained on their corresponding dataset. This is why this class is designed for bagging classifiers (@ref
%> aggr_bag). Internally, such classifier will draw sub-datasets (sub-sub-datasets if you consider that each training
%> dataset is already a sub-dataset to train component classifiers.
%>
%> The @ref logs property is a 3D matrix, [no_logs]x[no_blocks]x[@ref no_bagreps]. Inspecting the logs individually has
%> little practical meaning.
%>
%> The "results" are obtained throught extract_curves() which generates one dataset per log in the @ref log_mold
%> property. The dataset x-axis correspond to "bagging repetitions" and the values are classification rates. Only one
%> row will be generated per classifier in the @ref block_mold property. It is expected that the classification rate
%> will rise with the bagging repetitions.
%>
%> Another "results" options is using extract_as_dsperc_x_rate()
%>
%> @sa uip_reptt_bag.m, demo_reptt_bag.m
classdef reptt_bag < reptt
    properties
        sgs;
        %> Number of bagging repetitions.
        no_bagreps = 100;
    end;
    
    properties(SetAccess=protected)
        obsidxs;
        datasets;
        i_bagrep;
        %> Deserves a property because in this way, dataset may be cleaned, and this property still remains
        no_datasets;
        flag_booted = 0;
    end;

    methods(Access=protected)
        %> Allocates cell of blocks (no_datasets)X(no_blocks), where no_datasets is the number of sub-samples generated by the
        %> SGS, and no_blocks is the number of elements of the @c block_mold property.
        %>
        %> This function must be called BEFORE allocate_logs()
        function o = allocate_blocks(o)
            if ~iscell(o.block_mold)
                mold = {o.block_mold};
            else
                mold = o.block_mold;
            end;
            no_blocks = numel(mold);

            % Checks if classifiers are from the right class
            % This is really important, otherwise it is pointless.
            for j = 1:no_blocks
                cll = class(mold{j});
                if ~strcmp(cll, 'aggr_bag')
                    irerror(sprintf('Element in block_mold is of class %s, must be an aggr_bag!', cll));
                end;
            end;
            
            o.blocks = cell(o.no_datasets, no_blocks);
            for i = 1:o.no_datasets
                for j = 1:no_blocks
                    o.blocks{i, j} = mold{j}.boot();
                end;
            end;
        end;

        
        %> Allocates cell of logs (no_logs)X(no_blocks)X(o.no_bagreps), each one allocated with no_datasets slots, where no_logs is the
        %> number of elements in the @c log_mold property, and @c no_blocks is the number of elements in the @c
        %> block_mold property.
        %>
        %> This method must be called AFTER allocate_blocks()
        function o = allocate_logs(o)
            nb = numel(o.block_mold);
            if ~iscell(o.block_mold)
                bmold = {o.block_mold};
            else
                bmold = o.block_mold;
            end;
            
            if ~iscell(o.log_mold)
                mold = {o.log_mold};
            else
                mold = o.log_mold;
            end;
            no_logs = numel(mold);
            o.logs = cell(numel(mold), nb, o.no_bagreps);
            for i = 1:no_logs
                for j = 1:nb
                    for k = 1:o.no_bagreps
                        o.logs{i, j, k} = mold{i}.allocate(o.no_datasets);
                        o.logs{i, j, k}.title = ['From classifier ', bmold{j}.get_description()];
                    end;
                end;
            end;
        end;
    end;
    
    methods
        function o = reptt_bag()
            o.classtitle = 'Bagging';
            o.moreactions = {'go', 'extract_logs', 'extract_curves', 'extract_log_celldata'};
        end;
        
        function o = boot(o)
            o = o.boot_postpr(); % from reptt
            
            o.obsidxs = o.sgs.get_obsidxs(o.data);
            o.no_datasets = size(o.obsidxs, 1);
            
            o = o.allocate_blocks();
            
            o.datasets = o.data.split_map(o.obsidxs(:, 1:2)); % I think I put this function here to let allocate_blocks() give an error (if it will) before doing something time-consuming
            
            o = o.allocate_logs();
            
            o.i_bagrep = 0;
            o.flag_booted = 1;
        end;
        
        function o = assert_booted(o)
            if ~o.flag_booted
                o = o.boot();
            end;
%             if ~o.flag_booted
%                 irerror('Must call boot() first!');
%             end;
        end;

        
        %> This function just calls @c do_bagrep() @c no_bagreps times
        function o = go(o)
            o = o.boot();
            
            for i = 1:o.no_bagreps
                o = o.do_bagrep();
            end;
        end;

        
        function o = do_bagrep(o)
            o = o.assert_booted();
            
            o.i_bagrep = o.i_bagrep+1;

            [nl, nb, nbr] = size(o.logs);
            if o.i_bagrep > nbr
                irerror('Number of bagging repetitions exceded');
            end;
            
            ipro = progress2_open('REPTT_BAG', [], 0, o.no_datasets);
            for i_rep = 1:o.no_datasets
                for i = 1:nb
                    bl = o.blocks{i_rep, i};
                    bl = bl.train(o.datasets(i_rep, 1));
                    o.blocks{i_rep, i} = bl;
                    est = bl.use(o.datasets(i_rep, 2));

                    if ~isempty(o.postpr_est)
                        est = o.postpr_est.use(est);
                    end;
                    if isempty(est.classes)
                        irerror('Estimation post-processing did not assign classes!');
                    end;


                    if ~isempty(o.postpr_test)
                        dref = o.postpr_test.use(o.datasets(i_rep, 2));
                    else
                        dref = o.datasets(i_rep, 2);
                    end;

                    pars = struct('est', {est}, 'dref', {dref}, 'clssr', {bl});
                    for j = 1:nl
                        o.logs{j, i, o.i_bagrep} = o.logs{j, i, o.i_bagrep}.record(pars);
                    end;
                end;
                ipro = progress2_change(ipro, [], [], i_rep);
            end;
            progress2_close(ipro);
        end;


        %> Generates as many datasets as there are elements in the @c log_mold property.
        %>
        %> Each dataset will have one curve per element in the @ref block_mold property X per sub-dateset. Each element in @ref block_mold
        %> gives a different class. Each element in @ref log_mold gives a different dataset.
        function out = extract_curves(o)
            [no_logs, no_blocks, nbr] = size(o.logs);
            
            out = cell(1, no_logs);
            for l = 1:no_logs
                % Determines how many rows the dataset will have, for pre-allocation
                no = no_blocks*o.no_datasets;
                X = zeros(no, nbr);
                classes = zeros(no, 1);
                
                for i = 1:no_blocks
                    for j = 1:nbr
                        X((i-1)*o.no_datasets+1:i*o.no_datasets, j) = o.logs{l, i, j}.get_rates();
                        classes((i-1)*o.no_datasets+1:i*o.no_datasets, 1) = i-1;
                    end;
                end;
           
                blocktitles = cell(1, no_blocks);
                for i = 1:no_blocks
                    blocktitles{i} = o.blocks{1, i}.get_description();
                end;
                df = ['Derived from ', o.logs{l, 1, 1}.get_description()];

                % ... 1D rates dataset...
                d = irdata();
                d.fea_x = 1:nbr;
                d.xname = 'Bagging repetitions'; %> @todo this needs to have other names
                d.xunit = '';
                d.yname = o.logs{l, 1, 1}.get_legend();
                d.yunit = o.logs{l, 1, 1}.get_unit();
                d.X = X;
                d.classes = classes;
                d.classlabels = blocktitles;
                d.title = df;

                out{l} = d;
            end;
        end;
    end;
end