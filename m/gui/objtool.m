%>@ingroup guigroup mainguis
%>@file
%>@brief Object browser
%> @image html Screenshot-objtool.png

%> @param classname='irdata'
function varargout = objtool(varargin)
% Last Modified by GUIDE v2.5 09-Nov-2012 10:32:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @objtool_OpeningFcn, ...
                   'gui_OutputFcn',  @objtool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%> @cond
% --- Executes just before objtool is made visible.
function objtool_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
handles.output = hObject;

% Default parameters
if nargin < 3+1
    varargin{1} = 'irdata';
end;

% Initializes classes list
handles.classes = {'irdata', 'block', 'pre', 'fcon', 'fsel', 'clssr', 'block_cascade_base', 'sgs', 'fsg', 'peakdetector', 'irlog', 'as', 'vectorcomp', 'soitem'};


handles.flag_new = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]; % Only irdata cannot be created here
for i = 1:length(handles.classes)
    o = eval([handles.classes{i} ';']);
    handles.classtitles{i} = o.classtitle;
end;
[handles.classtitles, ii] = sort(handles.classtitles);
handles.classes = handles.classes(ii);
handles.flag_new = handles.flag_new(ii);
idx = find(strcmp(varargin{1}, handles.classes));
if isempty(idx)
    irerror(sprintf('Class ''%s'' not in list!', s));
end;
handles.input.rootclassname = varargin{1};
handles.input.flag_modal = 0;
handles.databuttonclass = 'pre'; % default data button to be down
handles.modebutton = 'properties'; % default mode button to be down
guidata(hObject, handles);

guidata(hObject, handles);
set_class(idx);
handles = guidata(hObject);

fig_assert();
gui_set_position(hObject);
guidata(hObject, handles);
setup_load();

refresh();
move_popup(idx);


function varargout = objtool_OutputFcn(hObject, eventdata, handles) 

if handles.input.flag_modal
    try
        uiwait(handles.figure1);
        handles = guidata(hObject);
        varargout{1} = handles.output;
        delete(gcf);
    catch %#ok<CTCH>
        output.flag_ok = 0;
        varargout{1} = output;
    end;
else
    % Get default command line output from handles structure
    varargout{1} = handles.output;
end;




%##########################################################################
%##########################################################################
% Auxiliary functions

%%%%%%%%%%%
% Getters %
%%%%%%%%%%%

%#####
function handles = find_handles()
H = findall(0, 'Name', 'objtool');
if isempty(H)
    irerror('objtool not open');
end;
handles = guidata(H);


%#####
function a = get_selected_names()
handles = find_handles();
a = listbox_get_selected_names(handles.listboxObjects);


%#####
function s = get_selected_1stname()
handles = find_handles();
s = listbox_get_selected_1stname(handles.listboxObjects);

function s = get_selected_1stname2()
handles = find_handles();
s = listbox_get_selected_1stname(handles.listbox_blocks);







%###############
% Refreshments %
%###############

%#####
function refresh()
read_classes();
refresh_modebuttons();
refresh_left();

%#####
function refresh_left()
handles = find_handles();
set(handles.listbox_classes, 'String', handles.strings_classes);
refresh_class();
refresh_middle();

%#####
function refresh_middle()
handles = find_handles();
listbox_load_from_workspace(handles.rootclassname, handles.listboxObjects);
refresh_right();

%#####
function refresh_right()
handles = find_handles();
objtool_status();
switch handles.modebutton
    case 'actions'
        refresh_actionspanel();
    case 'blocks'
        refresh_blockspanel();
    case 'properties'
        refresh_propertiespanel();
end;

%#####
% Updates GUI to reflect the class that is currently selected
% - GUI color
% - "New" button (enabled/disabled)
function refresh_class()
handles = find_handles();
onoff = {'off', 'on'};
s = handles.rootclassname;
o = eval([s ';']);
set(handles.figure1, 'Color', o.color);
idx = find(strcmp(handles.classes, handles.rootclassname));
% set(handles.pushbuttonNew, 'Enable', onoff{handles.flag_new(idx)+1});


if handles.flag_new(idx) %#ok<FNDSB>
    % New...
    set(handles.pushbuttonNew, 'String', 'New...');
    set(handles.pushbuttonSave, 'Visible', 'off');
    p = get(handles.pushbuttonRename, 'position');
    p(1) = 0.209375;
    set(handles.pushbuttonRename, 'position', p);
    p = get(handles.pushbuttonClear, 'position');
    p(1) = .45;
    set(handles.pushbuttonClear, 'position', p);
else
    % Load...; Save...    
    set(handles.pushbuttonNew, 'String', 'Load...');
    set(handles.pushbuttonSave, 'Visible', 'on');
    p = get(handles.pushbuttonRename, 'position');
    p(1) = 0.434375;
    set(handles.pushbuttonRename, 'position', p);
    p = get(handles.pushbuttonClear, 'position');
    p(1) = 0.671875;
    set(handles.pushbuttonClear, 'position', p);
end;
set(handles.uipanelObjects, 'Title', sprintf('Existing objects of class "%s"', s));


%#####
% Updates the up/down status of the mode buttons and visibility of corresponding panel
function refresh_modebuttons()
handles = find_handles();
guys = {'actions', 'blocks', 'properties'};
for i = 1:numel(guys)
    flag = strcmp(handles.modebutton, guys{i});
    set(handles.(['togglebutton_', guys{i}]), 'value', flag);
    set(handles.(['uipanel_', guys{i}]), 'visible', iif(flag, 'on', 'off'));
end;


%#####
% Refreshes actions panel completely
function refresh_actionspanel()
refresh_databuttons();
read_actions();
filter_actions();
populate_actions();
read_moreactions();
populate_moreactions();

%#####
% Refreshes blocks panel
function refresh_blockspanel()
handles = find_handles();
objname = get_selected_1stname();
if ~isempty(objname)
    obj = evalin('base', [objname, ';']);
    a = get_varnames('block', obj);
else
    a = {'(none)'};
end;
if get(handles.listbox_blocks, 'Value') > numel(a)
    set(handles.listbox_blocks, 'Value', 1);
end;
set(handles.listbox_blocks, 'string', a);

%#####
% Refreshes properties panel
function refresh_propertiespanel()
handles = find_handles();
show_description(handles.listboxObjects, handles.editHistory);

%#####
% Adjusts
% - listbox_actions height,
% - data buttons visibility, and
% - selected data button "down" status
% according to handles.flag_databuttons, handles.handles.databuttonclass
function refresh_databuttons()
handles = find_handles();
flag = handles.flag_databuttons;
hei = iif(flag, 0.5114678899082569, 0.573394495412844);
guys = {'as', 'fext', 'clus', 'pre', 'fcon', 'fsel', 'blmisc', 'block', 'block_cascade_base', 'vis'};
s_flag = iif(flag, 'on', 'off');
for i = 1:numel(guys)
    set(handles.(['pushbutton_', guys{i}]), 'Visible', s_flag);
    if flag
        set(handles.(['pushbutton_', guys{i}]), 'Value', strcmp(handles.databuttonclass, guys{i}));
    end;
end;
p = get(handles.listbox_actions, 'position');
p(4) = hei;
set(handles.listbox_actions, 'position', p);







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Non-visual, handles-changing %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%#####
function set_class(idx)
handles = find_handles();
s = handles.classes{idx};
handles.rootclassname = s;
handles.flag_databuttons = strcmp(s, 'irdata');
guidata(handles.figure1, handles);

%#####
% Reads class list with counts
function read_classes()
handles = find_handles();
a = handles.classtitles;
oldcounts = [];
if isfield(handles, 'classcounts')
    oldcounts = handles.classcounts;
end;
aa = get_varnames2(handles.classes);
for i = 1:numel(a)
    counts(i) = numel(aa{i});
    s = iif(~isempty(oldcounts) && oldcounts(i) < counts(i), ' **', '');
    a{i} = [a{i}, ' (', s, int2str(counts(i)), s, ')'];
end;
handles.strings_classes = a;
handles.classcounts = counts;
guidata(handles.figure1, handles);

%#####
% Reads actions into handles
function read_actions()
handles = find_handles();
classname = iif(handles.flag_databuttons, handles.databuttonclass, 'block'); % This may come from somewhere else, later
objname = get_selected_1stname();
if ~isempty(objname)
    obj = evalin('base', [objname, ';']);
    list = classmap_get_list(classname, class(obj));
    a = itemlist2cell(list);
else
    list = [];
    a = {'(none)'};
end;
handles.a = a;
handles.al = lower(a); % for filtering
handles.actionslist = list;
handles.idxs_in = 1:numel(list); % Indexes of list elements to show
guidata(handles.figure1, handles);

%#####
% Makes handles.idxs_in
function filter_actions()
handles = find_handles();
filter = fel(get(handles.edit_filter, 'String'));
if ~isempty(filter)
    idxs = find(cellfun(@(x) (~isempty(x)), cellfun(@(x) (findstr(filter, x)), handles.al, 'UniformOutput', 0))); %#ok<FSTR>
    b = zeros(1, numel(handles.a));
    for i = 1:numel(idxs)
        if handles.actionslist(idxs(i)).flag_final
            b(idxs(i)) = 1;
            ob = handles.actionslist(idxs(i));
            while 1
                if ob.level == 1
                    break;
                end;
                ob = handles.actionslist(ob.parentindex);
                b(ob.index) = 1;
            end;
        end;
    end;
    handles.idxs_in = find(b);
else
    handles.idxs_in = 1:numel(handles.a);
end;
guidata(handles.figure1, handles);

%#####
% Reads moreactions into handles
function read_moreactions()
handles = find_handles();
blockname = get_selected_1stname();
ma = {};
if ~isempty(blockname)
    block = evalin('base', [blockname, ';']);
    cla = class(block);
    freshobj = eval([cla, ';']);
    ma = unique(freshobj.moreactions);
    la = ma;
end;
if isempty(ma)
    la = [];
    ma = {'(none)'};
end;
handles.moreactions_methods = la; % Keeps list of methods for reference
handles.moreactions_descriptions = ma; % Keeps list of methods for reference
guidata(handles.figure1, handles);









%%%%%%%%%%%%%%%%%%%%%
% Dumb GUI updaters %
%%%%%%%%%%%%%%%%%%%%%
% (these functions don't know why they are doing what they are doing)

%#####
% Populates actions listbox
function populate_actions()
handles = find_handles();
if get(handles.listbox_actions, 'Value') > numel(handles.a)
    set(handles.listbox_actions, 'Value', 1);
end;
set(handles.listbox_actions, 'String', handles.a(handles.idxs_in));

%#####
% Populates moreactions listbox
function populate_moreactions()
handles = find_handles();
ma = handles.moreactions_descriptions;
if get(handles.listbox_moreactions, 'Value') > numel(ma)
    set(handles.listbox_moreactions, 'Value', 1);
end;
set(handles.listbox_moreactions, 'String', ma);

%#####
function move_popup(idx)
handles = find_handles();
set(handles.listbox_classes, 'Value', idx);

%#########   
function objtool_status(s)
handles = find_handles();
if nargin < 1
    s = '';
end;
set(handles.text_status, 'String', s);





%%%%%%%%%%%%%%%%%%%%%
% Callback handlers %
%%%%%%%%%%%%%%%%%%%%%
% (These functions to everything that needs to be done in response to some user's action)

%#####
function do_moreactions()
handles = find_handles();
if ~isempty(handles.moreactions_methods)
    v = get(handles.listbox_moreactions, 'Value');
    if v > 0
        s_action = handles.moreactions_methods{v};
        blockname = get_selected_1stname();
        try
            og = gencode();
            og.blockname = blockname;
            og.flag_leave_block = 0;
            og = og.start();
            og = og.m_generic(s_action);
            og = og.finish(); %#ok<NASGU>
            refresh();
        catch ME
            refresh();
            send_error(ME);
        end;
    end;
end;

%#####
function do_actions()
handles = find_handles();
if ~isempty(handles.idxs_in)
    v = get(handles.listbox_actions, 'Value');
    if v > 0
        which = handles.idxs_in(v);
        item = handles.actionslist(which);
        if ~item.flag_final
            msgbox('Please select a deepest-level option!');
        else
            classname = handles.actionslist(which).name;
            try
                objnames = get_selected_names();
                objs = cellfun(@(objname) (evalin('base', [objname, ';'])), objnames, 'UniformOutput', 0);
                if numel(objs) == 1
                    objs = objs{1};
                end;
                vis = eval([classname, ';']);
                result = vis.get_params(objs);

                if result.flag_ok
                    og = gencode();
                    og.classname = classname;
                    og.dsnames = objnames;
                    og.params = result.params;
                    og.flag_leave_block = 1;

                    try
                        og = og.start();
                        og = og.m_create();
                        og = og.m_boot();
                        og = og.m_train();
                        og = og.m_use();
                        og = og.finish(); %#ok<NASGU>
                        % There is no need to refresh, because we don't expect the workspace to change out of visualization 
                    catch ME
                        % refresh();
                        rethrow(ME);
                    end;
                end;
                refresh();
            catch ME
                refresh();
                send_error(ME);
            end;
        end;
    end;
end;


%#####
function do_block(what)
blockname = get_selected_1stname2();
if ~isempty(blockname)
    try
        dsnames = get_selected_names();

        og = gencode();
        og.blockname = blockname;
        og.dsnames = dsnames;
        og.flag_leave_block = 0;
        og = og.start();
        if ismember(what, {'boot', 'train', 'use'})
            og = og.(['m_', what])();
        else
            og = og.m_generic(what);
        end;
        og = og.finish(); %#ok<NASGU>
        refresh();
    catch ME
        refresh();
        objtool_status(ME.message);
        send_error(ME);
    end;
else
    objtool_status('Cannot do anything: no block selected!');
end;


%#####
function set_databutton(s)
objtool_status();
handles = find_handles();
handles.databuttonclass = s;
guidata(handles.figure1, handles);
read_actions();
filter_actions();
populate_actions();
refresh_databuttons();


%#####
function set_modebutton(s)
handles = find_handles();
handles.modebutton = s;
guidata(handles.figure1, handles);
refresh_modebuttons();
refresh_right();


%#########################################
%#########################################

%#####
function listbox_classes_Callback(hObject, eventdata, handles) 
set_class(get(handles.listbox_classes, 'Value'));
refresh_class();
refresh_middle();

%#####
function listboxObjects_Callback(hObject, eventdata, handles)
refresh_right();

%#####
function pushbuttonRefreshMS_Callback(hObject, eventdata, handles)
refresh();

%#####
function pushbuttonRename_Callback(hObject, eventdata, handles)
objtool_status();
s = get_selected_1stname();
if ~isempty(s)
    try
        rename_object(s);
        refresh_middle();
    catch ME
        refresh_middle();
        send_error(ME);
    end;
end;

%#####
function pushbuttonClear_Callback(hObject, eventdata, handles)
objtool_status();
names = get_selected_names();
if ~isempty(names)
    try
        code = sprintf('clear %s;', sprintf('%s ', names{:}));
        ircode_eval(code, 'Clearing objects');
        refresh();
    catch ME
        refresh();
        send_error(ME);
    end;
end;    

%#####
function pushbuttonNew_Callback(hObject, eventdata, handles)
objtool_status();
handles = find_handles();
idx = find(strcmp(handles.classes, handles.rootclassname));
if handles.flag_new(idx) %#ok<FNDSB>
    r = do_blockmenu(handles.rootclassname, [], 1);
    if r.flag_ok
        try
            og = r.og;
            og = og.start();
            og = og.m_create();
            og = og.finish();
            refresh();
        catch ME
            refresh();
            send_error(ME);
        end;
    end;
else
    % Load data
    
    path_assert();
    global PATH; %#ok<*TLEV>
    global ATRTOOL_LOAD_OK ATRTOOL_LOAD_RANGE;
    try
        types = {'mat', 'txt'};
        [name, path, filterindex] = uigetfile({'*.mat;*.txt', 'Supported file types (*.mat;*.txt)'; ...
                                               '*.*', 'All files (*.*)'; ...
                                               '*.mat', 'MAT-files (*.mat)'; ...
                                               '*.txt', 'TXT-files (*.txt)'; ...
                                               '*.0', 'OPUS-files (*.txt)'; ...
                                              }, 'Select file to open', PATH.data_load); %#ok<*NASGU>
        if name > 0
            name_full = fullfile(path, name);
            classname = detect_file_type(name_full);

            % Either way, will update the path
            PATH.data_load = path;
            setup_write();

            if isempty(classname)
                irerrordlg(sprintf('Could not detect type of file ''%s''', name), 'Sorry');
            else
                oio = eval(classname);
                s_range = '';
                flag_ok = 1;
                if ~oio.flag_xaxis
                    datatool_fearange();
                    if ~isempty(ATRTOOL_LOAD_OK)
                        s_range = '';
                        if ~isempty(ATRTOOL_LOAD_RANGE)
                            s_range = [mat2str(ATRTOOL_LOAD_RANGE)]; %#ok<NBRAK>
                        end;
                    else
                        flag_ok = 0;
                    end;

                end;

                if flag_ok

                    name_new = find_varname('ds');
                    code = sprintf('o = %s();\no.filename = ''%s'';\n%s = o.load(%s);', classname, name_full, name_new, s_range);

                    ircode_eval(code, 'Dataset load');
                    refresh();

                end;
            end;
        end;

    catch ME
        refresh();
        objtool_status(ME.message);
        send_error(ME);
    end;

    
end;


%#####
function togglebutton_actions_Callback(hObject, eventdata, handles)
set_modebutton('actions');

%#####
function togglebutton_properties_Callback(hObject, eventdata, handles)
set_modebutton('properties');

%#####
function listbox_actions_Callback(hObject, eventdata, handles)
if strcmp(get(handles.figure1, 'SelectionType'), 'open') % This is how you detect a double-click in MATLAB
    do_actions();
end;

%#####
function listbox_moreactions_Callback(hObject, eventdata, handles)
if strcmp(get(handles.figure1, 'SelectionType'), 'open') % This is how you detect a double-click in MATLAB
    do_moreactions();
end;

%#####
function pushbutton_go_train_use_Callback(hObject, eventdata, handles)
do_actions();

%#####
function pushbutton_go_moreactions_Callback(hObject, eventdata, handles)
do_moreactions();

%#####
function pushbutton_create_defaults_Callback(hObject, eventdata, handles)
create_default_objects();
refresh();

%#####
function edit_filter_Callback(hObject, eventdata, handles)
filter_actions();
populate_actions();

%#####
function pushbutton_vis_Callback(hObject, eventdata, handles)
set_databutton('vis');

%#####
function pushbutton_fcon_Callback(hObject, eventdata, handles)
set_databutton('fcon');

%#####
function pushbutton_pre_Callback(hObject, eventdata, handles)
set_databutton('pre');

%#####
function pushbutton_blmisc_Callback(hObject, eventdata, handles)
set_databutton('blmisc');

%#####
function pushbutton_fsel_Callback(hObject, eventdata, handles)
set_databutton('fsel');

%#####
function pushbutton_block_cascade_base_Callback(hObject, eventdata, handles)
set_databutton('block_cascade_base');

%#####
function pushbutton_block_Callback(hObject, eventdata, handles)
set_databutton('block');

%#####
function pushbutton_as_Callback(hObject, eventdata, handles)
set_databutton('as');

%#####
function pushbutton_fext_Callback(hObject, eventdata, handles)
set_databutton('fext');

%#####
function pushbutton_clus_Callback(hObject, eventdata, handles)
set_databutton('clus');

%#####
function togglebutton_blocks_Callback(hObject, eventdata, handles)
set_modebutton('blocks');

%#####
function pushbutton_boot_Callback(hObject, eventdata, handles)
objtool_status('');
s = get_selected_1stname2();
if ~isempty(s)
    o = evalin('base', [s, ';']); % gets object to see if it is bootable
    if o.flag_bootable < 1
        objtool_status('Cannot boot: block not bootable!');
    else
        do_block('boot');
    end;
else
    objtool_status('Cannot boot: no block selected!');
end;

%#####
function pushbutton_train_Callback(hObject, eventdata, handles)
objtool_status('');
s = get_selected_1stname2();
if ~isempty(s)
    o = evalin('base', [s, ';']); % gets object to see if it is trainable
    if o.flag_trainable < 1
        objtool_status('Cannot train: block not trainable!');
    else
        do_block('train');
    end;
else
    objtool_status('Cannot train: no block selected!');
end;

%#####
function pushbutton_use_Callback(hObject, eventdata, handles)
do_block('use');

%#####
function listbox_blocks_Callback(hObject, eventdata, handles)
objtool_status();

%#####
%#####
function listboxObjects_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function editHistory_Callback(hObject, eventdata, handles)
function editHistory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function listbox_classes_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function listbox_actions_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function listbox_moreactions_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_filter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_filter_KeyPressFcn(hObject, eventdata, handles)

function listbox_blocks_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbuttonSave_Callback(hObject, eventdata, handles)
objtool_status();
path_assert();
global PATH;
dsname = get_selected_1stname();
if isempty(dsname)
    objtool_status('No dataset to save!');
    return;
end;
ds = evalin('base', [dsname ';']);
[pa, na, ex] = fileparts(ds.filename);
try
    classnames = {'dataio_mat', 'dataio_txt_irootlab', 'dataio_txt_pir', 'dataio_txt_basic'};
    [name, path, filterindex] = uiputfile({'*.mat', 'MAT file (*.mat)'; ...
                                           '*.txt', 'TXT file (IRootLab format) (*.txt)'; ...
                                           '*.txt', 'TXT file (pir format) (*.txt)'; ...
                                           '*.txt', 'TXT file (basic format) (*.txt)' ...
                                          }, 'Save as', fullfile(PATH.data_save, [na, ex]));
 
    if name > 0
        filename = fullfile(path, name);
        o = eval(classnames{filterindex}); % creates instance of some dataio class
        o.filename = filename;
        o.save(ds);

        % If reached this point, will celebrate and write the path as default data path to the setup file
        PATH.data_save = path;
        setup_write();
    end;
catch ME
    objtool_status(ME.message);
    send_error(ME);
end;

%> @endcond