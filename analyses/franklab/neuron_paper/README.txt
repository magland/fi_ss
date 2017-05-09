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
	



Notes:

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

