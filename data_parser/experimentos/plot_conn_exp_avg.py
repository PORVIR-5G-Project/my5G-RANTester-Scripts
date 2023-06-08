import csv
import matplotlib as mpl
import matplotlib.pyplot as plt
import statistics
import numpy as np

plt.style.use('seaborn-whitegrid')
mpl.rc('font',family='Times New Roman')

INITIAL_UE = 43
UE_PER_GNB = 100

vm_configs = [ "TG2-12C-8GB_avg" ] #[ "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
cores = [ 2, 3 ]
execs = [ 500, 400, 300, 200, 100 ]     # Delays between connections in ms
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

MAX_AXIS_X = 5
MAX_AXIS_Y = 2

for vm in vm_configs:
    base_filename = vm + "\\" + "my5grantester-logs-{}-{}-{}.csv"


    figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)
    figure.canvas.manager.set_window_title(vm)
    figure.set_size_inches((6, 7))

    for core_idx, core in enumerate(cores):
        axis_x = 0

        for exe in execs:
            all_data = np.array([])

            for exp in experiments:
                timestamp = np.array([])
                dataplaneready = np.array([])

                avg_per_brust = [np.array([])] * UE_PER_GNB
                avg_ts_per_brust = [np.array([])] * UE_PER_GNB

                dataplane_avg = 0
                dataplane_pvar = 0
                dataplane_pstdev = 0

                curr_ax = axis[axis_x][core_idx]

                with open(base_filename.format(core, exe, exp), newline='') as csvfile:
                    reader = csv.DictReader(csvfile)

                    for row in reader:
                        
                        try:
                            curr_dpr = float(row['DataPlaneReady_Avg'])
                            curr_ts = float(row['timestamp'])

                            dataplaneready = np.append(dataplaneready, curr_dpr)
                            timestamp = np.append(timestamp, curr_ts)
                            
                            try:
                                index_x = (int(row['gnbid']) - INITIAL_UE) % UE_PER_GNB

                                avg_per_brust[index_x] = np.append(avg_per_brust[index_x], curr_dpr)
                                avg_ts_per_brust[index_x] = np.append(avg_ts_per_brust[index_x], curr_ts)

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
                    color = next(curr_ax._get_lines.prop_cycler)['color']

                    # Plot brust average
                    curr_ax.scatter(timestamp_to_plot, avg_to_plot, label = "#gNB {}".format(exp), s=5, color=color)

                    # Calculate the average and standard deviation
                    all_data = np.append(all_data, avg_to_plot)

                    try:
                        dataplane_avg = statistics.mean(dataplaneready)
                        dataplane_pvar = statistics.pvariance(dataplaneready)
                        dataplane_pstdev = statistics.pstdev(dataplaneready)
                    except:
                        continue

                    # Plot the average
                    # print ("Core {}: {}ms - Exp {:2d}: {:.2f}ms".format(cores_name[core_idx], exe, exp, dataplane_avg))

                    dataplane_avg_arr = np.repeat(dataplane_avg, dataplaneready.size)
                    curr_ax.plot(timestamp, dataplane_avg_arr, color=color)

            # Plot the global average
            print ("Core {}: {} ms - Max: {:.2f} ms - Mean: {:.2f} ms - Median: {:.2f} ms - Pstdev: {:.2f} ms".format(cores_name[core_idx], exe, max(all_data), statistics.mean(all_data), statistics.median(all_data), statistics.pstdev(all_data)))

            curr_ax.set_title(str(exe) + " ms", fontsize=10)
            axis_x += 1

    # figure.text(.55, 0.98, 'Tempo entre cada conexão (ms)', ha='center', fontsize=12)
    figure.text(.31, 0.98, cores_name[0], ha='center', fontsize=12)
    figure.text(.75, 0.98, cores_name[1], ha='center', fontsize=12)

    figure.text(0.5, 0.04, "Tempo do experimento (s)", ha='center', fontsize=12)
    figure.text(0.04, 0.5, "Tempo de conexão do UE (ms)", va='center', rotation='vertical', fontsize=12)
    figure.tight_layout(rect=[0.15, 0.1, 0.95, 0.95])

    plt.subplots_adjust(left=0.15, bottom=0.1, right=0.95, top=0.93, wspace=0.15, hspace=0.5)
     
    plt.show(block=False)

input("Press Enter to continue...")
