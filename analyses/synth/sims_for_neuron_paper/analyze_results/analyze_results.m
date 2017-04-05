function analyze_results

close all;
drawnow;

basepath=[fileparts(mfilename('fullpath')),'/..'];
temppath=[basepath,'/tmpdata'];
resultspath=[basepath,'/results'];
mkdir(temppath);
mkdir(resultspath);

results={};
list=dir([basepath,'/output']);
for j=1:length(list)
    name0=list(j).name;
    if (~strcmp(name0(1),'.'))
        algname0=get_algname_from_output_folder_name(name0);
        dsname0=get_dsname_from_output_folder_name(name0);
        if (~strcmp(algname0,'truth'))
            oo=struct;
            oo.temppath=temppath;
            resultpath=[resultspath,'/',name0];
            ret=analyze_result(sprintf('%s/output/%s',basepath,name0),sprintf('%s/output/truth--%s',basepath,dsname0),resultpath,oo);
            ret.algname=algname0;
            ret.dsname=dsname0;
            results{end+1}=ret;
        end;
    end;
end;

concat_output_ms2=zeros(6,0);
concat_output_ks32=zeros(6,0);
concat_output_sc=zeros(6,0);
for j=1:length(results)
    ret=results{j};
    if (strcmp(ret.algname,'ms2'))
        concat_output_ms2=cat(2,concat_output_ms2,ret.output);
    end;
    if (strcmp(ret.algname,'ks32'))
        concat_output_ks32=cat(2,concat_output_ks32,ret.output);
    end;
    if (strcmp(ret.algname,'sc'))
        concat_output_sc=cat(2,concat_output_sc,ret.output);
    end;
end;

writemda(concat_output_ms2,sprintf('%s/concat_output_ms2.mda',resultspath));
writemda(concat_output_ks32,sprintf('%s/concat_output_ks32.mda',resultspath));
writemda(concat_output_sc,sprintf('%s/concat_output_sc.mda',resultspath));

MS2=concat_output_ms2;
KS32=concat_output_ks32;
SC=concat_output_sc;

marker_size=6;

% figure;
% h=plot(MS2(1,:),MS2(2,:),'bo','MarkerSize',marker_size);
% hold on;
% h=plot(KS32(1,:),KS32(2,:),'ro','MarkerSize',marker_size);
% legend('MountainSort','KiloSort');
% xlabel('Peak amplitude');
% ylabel('Unit accuracy');
% title('Accuracy vs. peak amplitude');

figure;
set(gcf,'Position',[200,200,1000,1000]);
ppp=1;

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(1,:),MS2(3,:),'bo','MarkerSize',marker_size);
hold on;
h=plot(KS32(1,:),KS32(3,:),'ro','MarkerSize',marker_size);
h=plot(SC(1,:),SC(3,:),'go','MarkerSize',marker_size);
legend('MountainSort','KiloSort','SpyKING Circus');
xlabel('Peak amplitude');
ylabel('Unit sensitivity rate');
title('Sensitivity rate vs. peak amplitude');

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(1,:),MS2(4,:),'bo','MarkerSize',marker_size);
hold on;
h=plot(KS32(1,:),KS32(4,:),'ro','MarkerSize',marker_size);
h=plot(SC(1,:),SC(4,:),'go','MarkerSize',marker_size);
legend('MountainSort','KiloSort','SpyKING Circus');
xlabel('Peak amplitude');
ylabel('Unit specificity rate');
title('Specificity rate vs. peak amplitude');

% for this plot ignore the ones that have no match
MS2=MS2(:,find(MS2(2,:)>0));

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(5,:),MS2(3,:),'bo','MarkerSize',marker_size);
xlabel('Noise overlap metric');
ylabel('Unit sensitivity rate');
title({'Sensitivity vs. noise overlap metric','for MountainSort'});

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(5,:),MS2(4,:),'bo','MarkerSize',marker_size);
xlabel('Noise overlap metric');
ylabel('Unit specificity rate');
title({'Specificity vs. noise overlap metric','for MountainSort'});

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(6,:),MS2(3,:),'bo','MarkerSize',marker_size);
xlabel('Isolation metric');
ylabel('Unit sensitivity rate');
title({'Sensitivity vs. isolation metric','for MountainSort'});

subplot(3,2,ppp); ppp=ppp+1;
h=plot(MS2(6,:),MS2(4,:),'bo','MarkerSize',marker_size);
xlabel('Isolation metric');
ylabel('Unit specificity rate');
title({'Specificity vs. isolation metric','for MountainSort'});

disp('done.');


function [CM,label_map]=compute_confusion_matrix(firings1,firings2,opts)
CM_fname=sprintf('%s/CM_tmp.mda',opts.temppath);
label_map_fname=sprintf('%s/label_map_tmp.mda',opts.temppath);
delete(CM_fname);
cmd=sprintf('mp-run-process mountainsort.confusion_matrix --firings1=%s --firings2=%s --relabel_firings2=true --max_matching_offset=30 --confusion_matrix_out=%s --firings2_relabel_map_out=%s',...
            firings1,firings2,CM_fname,label_map_fname);
cmd=adjust_system_command(cmd);
disp(['Running ',cmd]);
system(cmd);
CM=readmda(CM_fname);
label_map=readmda(label_map_fname);

function result=analyze_result(output_path,truth_output_path,result_path,opts)
mkdir(result_path);
firings=[output_path,'/firings.mda'];
firings_true=resolve_prv([truth_output_path,'/firings.mda.prv']);
waveforms_true=[truth_output_path,'/waveforms.mda'];
[CM,label_map]=compute_confusion_matrix(firings_true,firings,opts);
writemda64(CM,[result_path,'/confusion_matrix.mda']);
[accuracies,sensitivity_rates,specificity_rates]=compute_accuracies_from_confusion_matrix(CM);
peak_amplitudes=compute_peak_amplitudes_from_waveforms(readmda(waveforms_true));
cluster_metrics=[output_path,'/cluster_metrics.json'];
if (exist(cluster_metrics))
    json=fileread(cluster_metrics);
    obj=jsondecode(json);
    noise_overlaps=get_cluster_metric(obj,length(accuracies),'noise_overlap',label_map);
    isolations=get_cluster_metric(obj,length(accuracies),'isolation', label_map);
else
    noise_overlaps=zeros(size(accuracies));
    isolations=zeros(size(accuracies));
end;

output=zeros(6,length(accuracies));
output(1,:)=peak_amplitudes;
output(2,:)=accuracies;
output(3,:)=sensitivity_rates;
output(4,:)=specificity_rates;
output(5,:)=noise_overlaps;
output(6,:)=isolations;

writemda64(output,[result_path,'/output.mda']);
csvwrite([result_path,'/output.csv'],output);
fprintf('%s\n',result_path);
output
result.output=output;
result.confusion_matrix=CM;

function ret=get_cluster_metric(obj,K,metric_name,label_map)
ret=zeros(1,K);
clusters=obj.clusters;
for j=1:length(clusters)
    cluster=clusters(j);
    k=cluster.label;
    if (k>=1)&&(k<=length(label_map))
        k=label_map(k);
    end;
    if (k>=1)&&(k<=K)
        ret(k)=cluster.metrics.(metric_name);
    end;
end;

function peak_amplitudes=compute_peak_amplitudes_from_waveforms(waveforms)
[M,T,K]=size(waveforms);
waveforms=reshape(waveforms,M*T,K);
peak_amplitudes=max(abs(waveforms),[],1)';

function [accuracies,sensitivity_rates,specificity_rates]=compute_accuracies_from_confusion_matrix(CM)
[N1,N2]=size(CM);
K1=N1-1; K2=N2-1;
accuracies=zeros(1,K1);
sensitivity_rates=zeros(1,K1);
specificity_rates=zeros(1,K1);
for k1=1:K1
    if (k1<=K2)
        numer0=CM(k1,k1);
        if (numer0)
            denom0=sum(CM(k1,:))+sum(CM(:,k1))-CM(k1,k1);
            denom1=sum(CM(k1,:));
            denom2=sum(CM(:,k1));
            accuracies(k1)=numer0/denom0;
            sensitivity_rates(k1)=numer0/denom1;
            specificity_rates(k1)=numer0/denom2;
        end;
    end;
end;

function fname=resolve_prv(prv_fname)
[~,str]=system(sprintf('prv-locate %s',prv_fname));
fname=strtrim(str);

function algname=get_algname_from_output_folder_name(name)
list=strsplit(name,'--');
if (length(list)>=2)
    algname=list(1);
end;

function dsname=get_dsname_from_output_folder_name(name)
list=strsplit(name,'--');
if (length(list)>=2)
    dsname=strjoin(list(2:end),'');
end;

function cmd=adjust_system_command(cmd)
cmd=sprintf('%s %s','LD_LIBRARY_PATH=/usr/local/lib',cmd);