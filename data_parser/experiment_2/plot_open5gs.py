import csv
import matplotlib.pyplot as plt
import numpy as np

base_filename = 'my5grantester-iperf-3-{}-{}.csv'
execs = [ 1, 2, 4, 6, 8, 10 ]

MAX_AXIS_X = 2
MAX_AXIS_Y = 3
axis_x = 0
axis_y = 0
figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)

csv_headers = ['timestamp', 'source_address', 'source_port', 'destination_address', 'destination_port', 'id', 'interval', 'transferred_bytes', 'bits_per_second']

plt.style.use('seaborn-whitegrid')

for exe in execs:
    all_avg_throughput = np.array([])
    for exp in range(0, exe):
        timestamp = np.array([])
        throughput = np.array([])
        avg_throughput = np.array([])

        with open(base_filename.format(exe, exp), newline='') as csvfile:
            reader = csv.DictReader(csvfile, fieldnames=csv_headers)

            for row in reader:                
                try:
                    interval = int(float(row['interval'].split('-')[1]))
                    curr_throughput = int(row['bits_per_second']) / 1000000

                    if interval in timestamp:
                        avg_throughput = np.repeat(curr_throughput, throughput.size)
                        all_avg_throughput = np.append(all_avg_throughput, curr_throughput)
                        continue

                    throughput = np.append(throughput, curr_throughput)
                    timestamp = np.append(timestamp, interval)
                except:
                    continue

        # print (throughput)
        # print (avg_throughput)
        # print (timestamp)

        if throughput.size > 0:
            axis[axis_x, axis_y].plot(timestamp, throughput, label = "#UE {} (exec {})".format(exe, exp))
            axis[axis_x, axis_y].plot(timestamp, avg_throughput, label = "AVG #UE {} (exec {})".format(exe, exp))
            # axis[axis_x, axis_y].legend()

    num_ues = all_avg_throughput.size
    sum_avg_throughput = np.sum(all_avg_throughput)
    axis[axis_x, axis_y].set_title("#UE {}/{} (Sum avg: {:.2f})".format(num_ues, exe, sum_avg_throughput))
    axis_y += 1
    if axis_y == MAX_AXIS_Y:
        axis_y = 0
        axis_x += 1

plt.show()