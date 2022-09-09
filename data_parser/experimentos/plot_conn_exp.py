import csv
import matplotlib.pyplot as plt
import statistics
import numpy as np

INITIAL_UE = 43
UE_PER_GNB = 100

vm_configs = [ "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 2, 3 ]
execs = [ 500, 400, 300, 200, 100 ]     # Delays between connections in ms
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

MAX_AXIS_X = 2
MAX_AXIS_Y = 2

plt.style.use('seaborn-whitegrid')

for vm in vm_configs:
    base_filename = vm + "\\" + "my5grantester-logs-{}-{}-{}.csv"

    for core_idx, core in enumerate(cores):

        axis_x = 0
        axis_y = 0
        figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)
        figure.canvas.manager.set_window_title(cores_name[core_idx])

        for exe in execs:
            for exp in experiments:
                time_base = 0
                timestamp = np.array([])
                dataplaneready = np.array([])

                avg_per_brust = [np.array([])] * UE_PER_GNB
                avg_ts_per_brust = [np.array([])] * UE_PER_GNB

                with open(base_filename.format(core, exe, exp), newline='') as csvfile:
                    reader = csv.DictReader(csvfile)

                    for row in reader:
                        if time_base == 0:
                            time_base = int(row['timestamp'])
                        
                        try:
                            dataplaneready = np.append(dataplaneready, float(row['DataPlaneReady']))
                            timestamp = np.append(timestamp, (int(row['timestamp']) - time_base) / 1000000000)
                            
                            try:
                                index_x = (int(row['gnbid']) - INITIAL_UE) % UE_PER_GNB

                                avg_per_brust[index_x] = np.append(avg_per_brust[index_x], float(row['DataPlaneReady']))
                                avg_ts_per_brust[index_x] = np.append(avg_ts_per_brust[index_x], (int(row['timestamp']) - time_base) / 1000000000)

                            except Exception as e:
                                print("Error: {}".format(e))
                                continue
                        except:
                            continue

                    # Plot the data
                    avg_to_plot = np.array([])
                    timestamp_to_plot = np.array([])
                    for i in range(0, len(avg_per_brust)):
                        if avg_per_brust[i].any() and avg_ts_per_brust[i].any():
                            avg_to_plot = np.append(avg_to_plot, statistics.mean(avg_per_brust[i]))
                            timestamp_to_plot = np.append(timestamp_to_plot, statistics.mean(avg_ts_per_brust[i]))

                    # Get color
                    color = next(axis[axis_x, axis_y]._get_lines.prop_cycler)['color']

                    # Plot brust average
                    axis[axis_x, axis_y].scatter(timestamp_to_plot, avg_to_plot, label = "#gNB {}".format(exp), s=5, color=color)

                    # Calculate the average and standard deviation
                    dataplane_avg = statistics.mean(dataplaneready)
                    dataplane_pvar = statistics.pvariance(dataplaneready)
                    dataplane_pstdev = statistics.pstdev(dataplaneready)

                    # Plot the average
                    dataplane_avg_arr = np.repeat(dataplane_avg, dataplaneready.size)
                    axis[axis_x, axis_y].plot(timestamp, dataplane_avg_arr, color=color)

            axis[axis_x, axis_y].set_title("{} (Delay {})".format(cores_name[core_idx], exe))
            axis_y += 1
            if axis_y == MAX_AXIS_Y:
                axis_y = 0
                axis_x += 1

            if (axis_x == MAX_AXIS_X):
                break

        #figure.legend()        
        plt.show(block=False)

    break

input("Press Enter to continue...")
