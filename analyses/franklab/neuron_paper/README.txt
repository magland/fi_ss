Tetrode dataset
	Run mountainsort
		> kron-run ms2mn tetrode
		> kron-view results ms2mn tetrode
	Retrieve manual sortings
		> kron-run manual1 tetrode
		> kron-run manual2 tetrode
		> kron-run manual3 tetrode
	Compare results:
		e.g., > kron-view compare_results manual1,ms2mn tetrode


Probe dataset
	Run mountainsort
		> kron-run ms2mn probe

Neto-Kampff ground truth dataset
	Run mountainsort
		> kron-run ms2mn nk1_ch101-128
	Retrieve juxta (ground truth) generated using ahb's script
		> kron-run truth nk1_ch101-128
	Compare them:
		> kron-view compare_results truth,ms2mn nk1_ch101-128
	The above can be repeated using the full 128 channels by replaceing "nk1_ch101-128" by "nk1"
	




Timings:

Tetrode MS run times on jfm's home computer (12 threads)
	9.091 (mountainsort.bandpass_filter)
	6.011 (mask_out_artifacts)
	5.009 (mountainsort.whiten)
	40.049 (mountainsort.ms2_002_multineighborhood)
	2.008 (merge_across_channels_v2)
	3.011 (mountainsort.fit_stage)
	2.005 (mountainsort.compute_templates)
	1.008 (mountainsort.reorder_labels)
	1.005 (mountainsort.cluster_metrics)
	3.006 (mountainsort.isolation_metrics)
	1.026 (mountainsort.combine_cluster_metrics)
	Total: 73 seconds for 46 minutes of data == 38x real time

nk1_ch101-128 on jfm's home computer (12 threads)
	10.439 (mountainsort.bandpass_filter)
	38.728 (mountainsort.whiten)
	67.072 (mountainsort.ms2_002_multineighborhood)
	7.013 (merge_across_channels_v2)
	19.255 (mountainsort.fit_stage)
	5.01 (mountainsort.compute_templates)
	1.01 (mountainsort.reorder_labels)
	1.045 (mountainsort.cluster_metrics)
	12.165 (mountainsort.isolation_metrics)
	1.007 (mountainsort.combine_cluster_metrics)