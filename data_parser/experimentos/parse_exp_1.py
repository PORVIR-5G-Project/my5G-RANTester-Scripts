import csv
import statistics
import numpy as np

UE_PER_GNB = 100

vm_configs = [ "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 2, 3 ]
execs = [ 500, 400, 300, 200, 100 ]     # Delays between connections in ms
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

final_results_headers = [ "core_idx", "core", "core_name", "delay_connection", "num_gnb", "num_ue", "num_ue_fail", "ue_fail_percent", "dataplane_avg", "dataplane_pvar", "dataplane_pstdev" ]

for vm in vm_configs:
    base_filename = vm + "\\" + "my5grantester-logs-{}-{}-{}.csv"
    out_file = open(vm + "_logs.csv", "w")
    out_file.write(','.join(final_results_headers) + '\n')	# Write headers

    for core_idx, core in enumerate(cores):
        for exe in execs:
            for exp in experiments:
                time_base = 0
                timestamp = np.array([])

                dataplaneready_avg = 0
                dataplaneready_pvar = 0
                dataplaneready_pstdev = 0
                dataplaneready = np.array([])

                with open(base_filename.format(core, exe, exp), newline='') as csvfile:
                    reader = csv.DictReader(csvfile)

                    for row in reader:
                        if time_base == 0:
                            time_base = int(row['timestamp'])
                        
                        try:
                            # float(row['DataPlaneReady'])
                            dataplaneready = np.append(dataplaneready, float(row['DataPlaneReady']))
                            timestamp = np.append(timestamp, (int(row['timestamp']) - time_base) / 1000000000)
                        except:
                            continue

                fails_qty = exp * UE_PER_GNB - len(dataplaneready)
                fails_percent = fails_qty / (exp * UE_PER_GNB) * 100

                try:
                    dataplaneready_avg = statistics.mean(dataplaneready)
                    dataplaneready_pvar = statistics.pvariance(dataplaneready)
                    dataplaneready_pstdev = statistics.pstdev(dataplaneready)
                except:
                    dataplaneready_avg = 0
                    dataplaneready_pvar = 0
                    dataplaneready_pstdev = 0

                results = [ core_idx, core, cores_name[core_idx], exe, exp, exp * UE_PER_GNB, fails_qty, fails_percent, dataplaneready_avg, dataplaneready_pvar, dataplaneready_pstdev ]

                out_file.write(','.join(map(str, results)) + '\n')

    out_file.close()
