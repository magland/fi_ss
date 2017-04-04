% preparing M=128 ch Kampff for MS sorting...
% edited from ss_datasets/Kampff/convert_kampff_to_mda.m
% Barnett 3/30/17-3/31/17

% this only works on alex's desktop.
% matlab pwd should be /data/ahb/neuron/Kampff


addpath /data/ahb/neuron/mountainlab/matlab/msutils/
addpath /data/ahb/neuron/mountainlab/matlab/processing/

% GEOM...
% clean newlines from mac to unix:
% tr '\r' '\n' < 128-chgeom-reorg.csv > 128-chgeom-reorg_clean.csv
% put this in datasets/.../geom.csv
a=textread('2015_09_04_Pair_5_0/128-chgeom-reorg_clean.csv','','delimiter',',');
figure; plot(a(:,1),a(:,2),'.'); hold on; axis equal tight
for m=1:size(a,1), text(a(m,1),a(m,2),sprintf('%d',m)); end
% radius of 25 um gets neighbors
jj=1:32; plot(a(jj,1),a(jj,2),'k.','markersize',20);  % highlight subset


M=128;   % # ch

dir='2015_09_04_Pair_5_0'; %%%%%%%%%%%%%%%%%%%%%%%%%%%% #2

fid=fopen([dir,'/amplifier2015-09-04T18_16_25-002.bin'],'r');       % raw MEA
Y = fread(fid,'uint16');  % size not given
fclose(fid);
N = numel(Y)/M
Y = reshape(Y,[M N]);
Y = (Y-32768); %*0.195;    % uV   % don't scale
%figure; plot(Y(1,1:1e4))
writemda16i(Y,'/data/ahb/neuron/fi_ss/raw/kampff128_2_raw.mda'); % 16bit signed

writemda16i(Y(:,1:1800000),'/data/ahb/neuron/fi_ss/raw/kampff128_2_1min_raw.mda'); % 16bit signed

clear Y



fid=fopen([dir,'/adc2015-09-04T18_16_25.bin']);        % ADC = juxta
J = fread(fid,'uint16');
fclose(fid);
MJ = 8;   % # adc ch
N = numel(J)/MJ
J = reshape(J,[MJ N]);
used_channel = 0; J = J(used_channel+1,:);  % to 1-indexed channel #
J = J * (10/65536/100) * 1e6;     % uV
writemda32(J,[dir,'/juxta.mda']);
mJ = mean(J);
trig = (mJ-0.6*(mJ-min(J)));   % trigger level
times = find(diff(J<trig)==1);  % trigger on down-going
% we find 233
labels = 1+0*times;
writemda64([0*times;times;labels],[dir,'/truefirings.mda']);
figure; plot(J,'-'); hold on; v=axis; plot([times;times],[v(3)+0*times;v(4)+0*times],'r:');
