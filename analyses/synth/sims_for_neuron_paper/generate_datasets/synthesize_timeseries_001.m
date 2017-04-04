function [X,firings_true,waveforms]=synthesize_timeseries_001(opts)

if (~isfield(opts,'M')), opts.M=4; end; % #channels
if (~isfield(opts,'T')), opts.T=800; end; % #timepoints in synthetic waveforms
if (~isfield(opts,'K')), opts.K=20; end; % #synthetic units
if (~isfield(opts,'samplerate')), opts.samplerate=30000; end; %Hz
if ((~isfield(opts,'duration'))&&(~isfield(opts,'N'))), opts.duration=600; end; %total duration in seconds
if (~isfield(opts,'N')), N=ceil(opts.duration*opts.samplerate); end
if (~isfield(opts,'upsamplefac')), opts.upsamplefac=13; end; %upsampling for synthetic waveforms
if (~isfield(opts,'refractory_period')), opts.refractory_period=10; end; %ms
if (~isfield(opts,'noise_level')), opts.noise_level=1; end; %
if (~isfield(opts,'firing_rate_range')), opts.firing_rate_range=[0.5,3]; end;
if (~isfield(opts,'amp_variation_range')), opts.amp_variation_range=[1,1]; end;
if (~isfield(opts,'show_figures')), opts.show_figures=0; end;
if (isfield(opts,'random_seed')), random_seed(opts.random_seed); end;

show_figures=opts.show_figures;

% seed=1;
% try
%   rng(seed); %not available in octave
% catch err
%   rand('seed',seed);
%   randn('seed',seed);
% end

M=opts.M;
T=opts.T;
K=opts.K;
samplerate=opts.samplerate;
N=opts.N;
noise_level=opts.noise_level;
synth_opts.upsamplefac=opts.upsamplefac;
refr=opts.refractory_period;

firing_rates=opts.firing_rate_range(1)+rand(1,K)*(opts.firing_rate_range(2)-opts.firing_rate_range(1));
%tmp=opts.amp_variation_range(1)+rand(1,K)*(opts.amp_variation_range(2)-opts.amp_variation_range(1));
%amp_variations=zeros(2,K); amp_variations(1,:)=tmp; amp_variations(2,:)=1; %amplitude variation
amp_variation_ranges=zeros(2,K); amp_variation_ranges(1,:)=opts.amp_variation_range(1); amp_variation_ranges(2,:)=opts.amp_variation_range(2);

opts2.geom_spread_coef1=0.4;
opts2.upsamplefac=synth_opts.upsamplefac;
waveforms=synthesize_random_waveforms(M,T,K,opts2);

if (show_figures)
    figure; ms_view_templates(waveforms);
end;

% events/sec * sec/timepoint * N
populations=ceil(firing_rates/samplerate*N);
times=zeros(1,0);
labels=zeros(1,0);
ampls=zeros(1,0);
for k=1:K
    refr_timepoints=refr/1000*samplerate;
    
%     a=refr_timepoints;
%     b=2*N/populations(k)-a; %(a+b)/2=N/pop so b=2*N/pop-a
%     isi=rand_uniform(a,b,[1,populations(k)*2]); %x2 to be safe
%     times0=cumsum(isi);
%     times0=times0((times0>=1)&(times0<=N));
    
    times0=rand(1,populations(k))*(N-1)+1;
    times0=[times0,times0+rand_distr2(refr_timepoints,refr_timepoints*20,size(times0))];
    times0=times0(randsample0(length(times0),ceil(length(times0)/2)));
    times0=enforce_refractory_period(times0,refr_timepoints);
    times0=times0((times0>=1)&(times0<=N));
    
    times=[times,times0];
    labels=[labels,k*ones(size(times0))];
    amp1=amp_variation_ranges(1,k);
    amp2=amp_variation_ranges(2,k);
    ampls=[ampls,rand_uniform(amp1,amp2,size(times0)).*ones(size(times0))];
end;

firings_true=zeros(3,length(times));
firings_true(2,:)=times;
firings_true(3,:)=labels;

X=synthesize_timeseries(waveforms,N,times,labels,ampls,synth_opts);
X=X+randn(size(X))*noise_level;

end

function X=rand_distr2(a,b,sz)
X=rand(sz);
X=a+(b-a)*X.^2;
end

function X=rand_uniform(a,b,sz)
X=rand(sz);
X=a+(b-a)*X;
end

function times0=enforce_refractory_period(times0,refr)
if (length(times0)==0) return; end;
times0=sort(times0);
done=0;
while ~done
    diffs=times0(2:end)-times0(1:end-1);
    diffs=[diffs,inf]; %hack to make sure we handle the last one
    inds0=find((diffs(1:end-1)<=refr)&(diffs(2:end)>refr)); %only first violator in every group
    if (length(inds0)>0)
        times0(inds0)=-1; %kind of a hack, what's the better way?
        times0=times0(times0>=0);
    else
        done=1;
    end;
end
end

function Y=randsample0(n,k)
Y=randperm(n);
Y=Y(1:k);
end

function random_seed(seed)
try
  rng(seed); %not available in octave
catch err
  rand('seed',seed);
  randn('seed',seed);
end
end