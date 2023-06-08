import csv
import statistics
import numpy as np

vm_configs = [ "TG2-12C-8GB", "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 1, 3 ]
execs = list(range(1, 17))              # Executions 1 to 16
experiments = [ 1, 2, 4, 6, 8, 10 ]     # Number of UEs runnning iperf per execution

csv_headers = ['timestamp', 'source_address', 'source_port', 'destination_address', 'destination_port', 'id', 'interval', 'transferred_bytes', 'bits_per_second']
final_results_headers = [ 'interval', 'bits_per_second_avg', 'bits_per_second_pvar', 'bits_per_second_pstdev', 'num_measures' ]

for vm in vm_configs:

    base_filename = vm + "\\" + "my5grantester-iperf-{}-{}-{}-{}.csv"
    base_output_filename = vm + "_avg" + "\\" + "my5grantester-iperf-{}-{}-{}.csv"

    for core_idx, core in enumerate(cores):
        for i in experiments:
            for j in range(0, i):
                dictionary = {}
                for e in execs:
                    with open(base_filename.format(e, core, i, j), newline='') as csvfile:
                        reader = csv.DictReader(csvfile, fieldnames=csv_headers)

                        for row in reader:                
                            try:
                                interval_in = int(float(row['interval'].split('-')[0]))
                                interval_out = int(float(row['interval'].split('-')[1]))
                                interval = str(interval_in) + "-" + str(interval_out)

                                if (dictionary.get(interval) is None):
                                    dictionary[interval] = np.array([])
                                
                                dictionary[interval] = np.append(dictionary[interval], int(row['bits_per_second']))
                            except Exception as e:
                                print (e)
                                continue

                out_file = open(base_output_filename.format(core, i, j), "w") # Open file to write
                out_file.write(','.join(final_results_headers) + '\n')	# Write headers

                # Calculate average and standard deviation
                for key in dictionary:
                    avg = statistics.mean(dictionary[key])
                    pvar = statistics.pvariance(dictionary[key])
                    pstdev = statistics.pstdev(dictionary[key])

                    # Write results to file
                    out_file.write(','.join([key, str(avg), str(pvar), str(pstdev), str(len(dictionary[key]))]) + '\n')

                out_file.close()
