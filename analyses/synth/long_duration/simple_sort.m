function simple_sort

% You must first compile mountainlab and run matlab/mountainlab_setup.m

if ~exist('data','dir'), mkdir('data'); end;
samplerate=30000;

% Simulate a random dataset and save to data/raw.mda
if ~exist('data/raw.mda','file')||~exist('data/geom.csv','file')
    ogen.samplerate=samplerate; % Hz
    ogen.duration=60*60; % seconds
    ogen.num_channels=4; % Number of channels
    ogen.num_units=20; % Number of simulated neurons
    generate_raw(ogen,'data/firings_true.mda','data/waveforms_true.mda','data/raw.mda');

    % Write lineary geometry file
    geom=1:ogen.num_channels;
    write_geometry_file(geom,'data/geom.csv');
end;

% View the simulated raw dataset
% view_timeseries(X);

% Bandpass filter
mp_run_process('mountainsort.bandpass_filter',...
    struct('timeseries','data/raw.mda'),...
    struct('timeseries_out','data/filt.mda'),...
    struct('freq_min',300, 'freq_max',6000, 'samplerate',samplerate));
    
% Whiten
mp_run_process('mountainsort.whiten',...
    struct('timeseries','data/filt.mda'),...
    struct('timeseries_out','data/pre.mda'),...
    struct());

% Spike sorting using MountainSort
sort_opts.adjacency_radius=100;
sort_opts.t1=-1; sort_opts.t2=-1;
mp_run_process('mountainsort.mountainsort3',...
    struct('timeseries','data/pre.mda', 'geom','data/geom.csv'),...
    struct('firings_out','data/firings.mda'),...
    sort_opts);

% Compute templates
mp_run_process('mountainsort.compute_templates',...
    struct('timeseries','data/filt.mda', 'firings','data/firings.mda'),...
    struct('templates_out','data/templates_filt.mda'),...
    struct('clip_size',100));
mp_run_process('mountainsort.compute_templates',...
    struct('timeseries','data/pre.mda', 'firings','data/firings.mda'),...
    struct('templates_out','data/templates_pre.mda'),...
    struct('clip_size',100));

% Compute metrics
metrics_list={};
mp_run_process('mountainsort.cluster_metrics',...
    struct('timeseries','data/pre.mda', 'firings','data/firings.mda'),...
    struct('cluster_metrics_out','data/cluster_metrics_1.json'),...
    struct('samplerate',samplerate));
metrics_list{end+1}='data/cluster_metrics_1.json';

mp_run_process('mountainsort.isolation_metrics',...
    struct('timeseries','data/pre.mda', 'firings','data/firings.mda'),...
    struct('metrics_out','data/cluster_metrics_2.json'),...
    struct('samplerate',samplerate));
metrics_list{end+1}='data/cluster_metrics_2.json';

mp_run_process('mountainsort.combine_cluster_metrics',...
    struct('metrics_list',{metrics_list}),...
    struct('metrics_out','data/cluster_metrics.json'));

% Automated annotation
script_fname='example_annotation.script';
mp_run_process('mountainsort.run_metrics_script',...
    struct('metrics','data/cluster_metrics.json','script',script_fname),...
    struct('metrics_out','data/cluster_metrics_annotated.json'),...
    struct());

% View the templates
figure; ms_view_templates(readmda('data/templates_filt.mda'));

% Launch the viewer
mountainview(struct(...
    'raw','data/raw.mda',... 
    'filt','data/filt.mda',...
    'pre','data/pre.mda',...
    'firings','data/firings.mda',...
    'samplerate',samplerate,...
    'cluster_metrics','data/cluster_metrics_annotated.json'...
));

end

function X=generate_raw(opts,firings_fname,waveforms_fname,timeseries_fname)
ooo.K=opts.num_units;
ooo.M=opts.num_channels;
ooo.samplerate=opts.samplerate;
ooo.duration=opts.duration;
ooo.show_figures=false;
synthesize_timeseries_003(ooo,firings_fname,waveforms_fname,timeseries_fname);

end

function write_geometry_file(geom,fname_out)
csvwrite(fname_out,geom');

end

function view_timeseries(X)
raw_path=pathify32(X);
ld_library_str='LD_LIBRARY_PATH=/usr/local/lib';
cmd=sprintf('%s mountainview --raw=%s',ld_library_str,raw_path);
system(cmd);

end

function mountainview(A)
ld_library_str='LD_LIBRARY_PATH=/usr/local/lib';
args='';
keys=fieldnames(A);
for j=1:length(keys)
    args=sprintf('%s--%s=%s ',args,keys{j},num2str(A.(keys{j})));
end;
cmd=sprintf('%s mountainview %s &',ld_library_str,args);
fprintf('%s\n',cmd);
system(cmd);
end
