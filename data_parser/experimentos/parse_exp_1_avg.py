import csv
import statistics
import numpy as np

INITIAL_UE = 43
UE_PER_GNB = 100

vm_configs = [ "TG2-12C-8GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 2, 3 ]
execs = list(range(1, 10))              # Executions 1 to 9
delays = [ 500, 400, 300, 200, 100 ]    # Delays between connections in ms
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

final_results_headers = [ "gnbid", "timestamp", "DataPlaneReady_Avg", "DataPlaneReady_PVar", "DataPlaneReady_PStDev" ]

for vm in vm_configs:
    base_filename = vm + "\\" + "my5grantester-logs-{}-{}-{}-{}.csv"

    for core_idx, core in enumerate(cores):
        for delay in delays:
            for exp in experiments:
                all_timestamps = [np.array([])] * (UE_PER_GNB * exp)
                all_dpready = [np.array([])] * (UE_PER_GNB * exp)
                
                out_filename = vm + "_avg" + "\\" + "my5grantester-logs-{}-{}-{}.csv".format(core, delay, exp)
                out_file = open(out_filename, "w")
                out_file.write(','.join(final_results_headers) + '\n')	# Write headers
                for exe in execs:
                    time_base = 0

                    try:
                        input_filename = base_filename.format(exe, core, delay, exp)
                        with open(input_filename, newline='') as csvfile:
                            reader = csv.DictReader(csvfile)

                            for row in reader:
                                if time_base == 0:
                                    time_base = int(row['timestamp'])
                                
                                try:
                                    dataplaneready = float(row['DataPlaneReady'])
                                    timestamp = (int(row['timestamp']) - time_base) / 1000000000
                                    gnbid = int(row['gnbid'])

                                    all_timestamps[gnbid - INITIAL_UE] = np.append(all_timestamps[gnbid - INITIAL_UE], timestamp)
                                    all_dpready[gnbid - INITIAL_UE] = np.append(all_dpready[gnbid - INITIAL_UE], dataplaneready)

                                except:
                                    continue
                    except Exception as e:
                        print("Error reading file: " + e.__str__() + " " + input_filename)
                        continue

                for gnbid in range(INITIAL_UE, INITIAL_UE + (UE_PER_GNB * exp)):
                    # out_file.write(str(gnbid) + ',' + str(statistics.mean(all_timestamps[gnbid - INITIAL_UE])) + ',' + str(statistics.mean(all_dpready[gnbid - INITIAL_UE])) + ',' + str(statistics.pvariance(all_dpready[gnbid - INITIAL_UE])) + ',' + str(statistics.pstdev(all_dpready[gnbid - INITIAL_UE])) + '\n')

                    timestamp_avg = 0
                    try:
                        timestamp_avg = statistics.mean(all_timestamps[gnbid - INITIAL_UE])
                        dataplaneready_avg = statistics.mean(all_dpready[gnbid - INITIAL_UE])
                        dataplaneready_pvar = statistics.pvariance(all_dpready[gnbid - INITIAL_UE])
                        dataplaneready_pstdev = statistics.pstdev(all_dpready[gnbid - INITIAL_UE])
                        out_file.write(str(gnbid) + ',' + str(timestamp_avg) + ',' + str(dataplaneready_avg) + ',' + str(dataplaneready_pvar) + ',' + str(dataplaneready_pstdev) + '\n')
                    except Exception as e:
                        print("Error writing file: " + e.__str__() + " " + out_filename)
                        out_file.write(str(gnbid) + ',' + str(timestamp_avg) + ',' + ',' + ',' + '\n')

                out_file.close()

