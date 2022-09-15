import csv
import statistics
import numpy as np

INITIAL_UE = 43
UE_PER_GNB = 100

vm_configs = [ "TG2-12C-8GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 2, 3 ]
execs = list(range(1, 11))              # Executions 1 to 10
delays = [ 500, 400, 300, 200, 100 ]    # Delays between connections in ms
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

final_results_headers = [ "gnbid", "timestamp", "DataPlaneReady_Avg", "DataPlaneReady_PVar", "DataPlaneReady_PStDev" ]
conn_error_headers = [ "core_idx", "core", "core_name", "delay_connection", "num_gnb", "num_ue", "num_ue_fail_sum", "num_ue_fail", "ue_fail_percent", "ue_fail_pvar", "ue_fail_pstdev" ]

for vm in vm_configs:
    base_filename = vm + "\\" + "my5grantester-logs-{}-{}-{}-{}.csv"

    err_out_file = open(vm + "_logs.csv", "w")
    err_out_file.write(','.join(conn_error_headers) + '\n')	# Write headers

    for core_idx, core in enumerate(cores):
        for delay in delays:
            for exp in experiments:
                all_timestamps = [np.array([])] * (UE_PER_GNB * exp)
                all_dpready = [np.array([])] * (UE_PER_GNB * exp)
                
                out_filename = vm + "_avg" + "\\" + "my5grantester-logs-{}-{}-{}.csv".format(core, delay, exp)
                out_file = open(out_filename, "w")
                out_file.write(','.join(final_results_headers) + '\n')	# Write headers

                fails_avg = np.array([])

                for exe in execs:
                    time_base = 0
                    conn_counter = 0

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

                                    conn_counter += 1
                                except Exception as e:
                                    # print("Error parsing file: " + e.__str__() + " " + input_filename)
                                    continue
                    except Exception as e:
                        print("Error reading file: " + e.__str__() + " " + input_filename)

                    fails_qty = exp * UE_PER_GNB - conn_counter
                    fails_avg = np.append(fails_avg, fails_qty)

                for gnbid in range(INITIAL_UE, INITIAL_UE + (UE_PER_GNB * exp)):
                    timestamp_avg = 0
                    dataplaneready_avg = 0
                    dataplaneready_pvar = 0
                    dataplaneready_pstdev = 0
                    if all_dpready[gnbid - INITIAL_UE].size > 0:
                        timestamp_avg = statistics.mean(all_timestamps[gnbid - INITIAL_UE])
                        dataplaneready_avg = statistics.mean(all_dpready[gnbid - INITIAL_UE])
                        dataplaneready_pvar = statistics.pvariance(all_dpready[gnbid - INITIAL_UE])
                        dataplaneready_pstdev = statistics.pstdev(all_dpready[gnbid - INITIAL_UE])
                        out_file.write(str(gnbid) + ',' + str(timestamp_avg) + ',' + str(dataplaneready_avg) + ',' + str(dataplaneready_pvar) + ',' + str(dataplaneready_pstdev) + '\n')
                    else:
                        print("Error: Empty all_timestamps[" + str(gnbid) + "]: " + out_filename)
                        out_file.write(str(gnbid) + ',' + str(timestamp_avg) + ',' + ',' + ',' + '\n')
                out_file.close()
                
                num_ue_fail_sum = 0
                num_ue_fail_avg = 0
                ue_fail_percent_avg = 0
                ue_fail_pvar = 0
                ue_fail_pstdev = 0
                if (fails_avg.size > 0):
                    num_ue_fail_sum = fails_avg.sum()
                    num_ue_fail_avg = statistics.mean(fails_avg)
                    ue_fail_percent_avg = num_ue_fail_avg * 100 / (exp * UE_PER_GNB)
                    ue_fail_pvar = statistics.pvariance(fails_avg)
                    ue_fail_pstdev = statistics.pstdev(fails_avg)

                results = [ core_idx, core, cores_name[core_idx], delay, exp, exp * UE_PER_GNB, num_ue_fail_sum, num_ue_fail_avg, ue_fail_percent_avg, ue_fail_pvar, ue_fail_pstdev ]
                err_out_file.write(','.join(map(str, results)) + '\n')
    
    err_out_file.close()
                

