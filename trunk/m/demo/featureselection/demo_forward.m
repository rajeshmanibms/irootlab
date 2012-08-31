% Forward feature selection

ds = load_she5trays();
ds = data_select_hierarchy(ds, 2); % Classes will be N/T


% The classifier
o = clssr_cla();
o.type = 'quadratic';
clssr_cla01 = o;

% The SGS
o = sgs_crossval();
o.flag_group = 1;
o.flag_perclass = 0;
o.randomseed = 0;
o.flag_loo = 0;
o.no_reps = 10;
sgs_crossval01 = o;

% The FSG
o = fsg_clssr();
o.clssr = clssr_cla01;
o.estlog = [];
o.postpr_est = [];
o.postpr_test = [];
o.sgs = sgs_crossval01;
fsg_clssr01 = o;

% The object that will do the feature selection
o = as_fsel_forward();
o.data = ds;
o.nf_select = 25; % Number of features to be selected
o.fsg = fsg_clssr01;
as_fsel_forward01 = o;

log = as_fsel_forward01.go();


% ^^^^^^ Calculations finished ^^^^^^


% Extracts feature selection block...
out = log.extract_fsel();
fsel_forward01 = out;

% Applies to dataset
[fsel_forward01, out] = fsel_forward01.use(ds);
ds_fsel01 = out;
disp([10, '-<= Features selected =>-']);
fprintf('    -> %4.1f cm^-1 <-\n', ds_fsel01.fea_x);
disp(' ');


% Visualizations
o = vis_log_as_fsel();
o.data_hint = ds;
o.flag_mark = 1;
figure;o.use(log);

out = log.extract_dataset();
irdata_forward01 = out;
o = vis_alldata();
figure;
o.use(irdata_forward01);
legend off;