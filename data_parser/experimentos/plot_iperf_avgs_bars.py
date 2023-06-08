import csv
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

plt.style.use('seaborn-whitegrid')
mpl.rc('font',family='Times New Roman')

base_filename = 'my5grantester-iperf-{}-{}-{}.csv'
cores = [ 1, 3 ]
cores_name = [ 'free5GC', 'Open5GS' ]
execs = [ 1, 2, 4, 6, 8, 10 ]           # Number of UEs runnning iperf per execution
vm_configs = [ "TG2-12C-8GB", "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]

MAX_AXIS_X = 3
MAX_AXIS_Y = 2

for vm in vm_configs:

    axis_bar = 0
    fig_bar, ax_bar = plt.subplots(len(cores))
    fig_bar.canvas.manager.set_window_title("AVG Throughput - " + vm)
    fig_bar.set_size_inches((6, 7))

    for core_idx, core in enumerate(cores):

        axis_x = 0
        axis_y = 0
        figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)
        figure.canvas.manager.set_window_title(cores_name[core_idx] + ' - ' + vm)

        figure.set_size_inches((6, 6))

        throughput_sum = np.zeros((max(execs), len(execs)))

        for exe_idx, exe in enumerate(execs):
            all_avg_throughput = np.array([])

            for exp in range(0, exe):
                timestamp = np.array([])
                throughput = np.array([])
                avg_throughput = np.array([])

                with open(vm + "_avg" + '\\' + base_filename.format(core, exe, exp), newline='') as csvfile:
                    reader = csv.DictReader(csvfile)

                    for row in reader:                
                        try:
                            interval = int(float(row['interval'].split('-')[1]))
                            curr_throughput = float(row['bits_per_second_avg']) / 1000000

                            if interval in timestamp:
                                avg_throughput = np.repeat(curr_throughput, throughput.size)
                                all_avg_throughput = np.append(all_avg_throughput, curr_throughput)

                                throughput_sum[exp][exe_idx] = curr_throughput
                                # print('\n'.join([' '.join(['{:10.4f}'.format(item) for item in row]) for row in throughput_sum]))
                                # print("\n")
                                continue

                            throughput = np.append(throughput, curr_throughput)
                            timestamp = np.append(timestamp, interval)
                        except Exception as e:
                            print (e)
                            continue

                if throughput.size > 0:
                    # Get color
                    color = next(axis[axis_x, axis_y]._get_lines.prop_cycler)['color']

                    axis[axis_x, axis_y].plot(timestamp[1:-1], throughput[1:-1], label = "#UE {} (exec {})".format(exe, exp), color=color)
                    # axis[axis_x, axis_y].plot(timestamp, avg_throughput, label = "AVG #UE {} (exec {})".format(exe, exp), color=color)


            num_ues = all_avg_throughput.size
            sum_avg_throughput = np.sum(all_avg_throughput)
            axis[axis_x, axis_y].set_title("#UEs = {}".format(num_ues), fontsize=10)
            
            axis_y += 1
            if axis_y == MAX_AXIS_Y:
                axis_y = 0
                axis_x += 1

        bottom_bar = np.zeros(len(execs))
        ax_bar[axis_bar].set_title(cores_name[core_idx])
        for i in range(0, max(execs)):
            ax_bar[axis_bar].bar(list(map(str,execs)), throughput_sum[i], bottom=bottom_bar)
            ax_bar[axis_bar].set_title(cores_name[core_idx], fontsize=12)
            bottom_bar += np.array(throughput_sum[i])

        for i in range(0, len(execs)):
            throughput_sum_total = np.sum([row[i] for row in throughput_sum])
            print("Core {} - VM {} - Num UE {} - Throughput {:.2f}".format(cores_name[core_idx], vm, execs[i], throughput_sum_total))

        axis_bar += 1

        figure.text(.5, 0.96, cores_name[core_idx], ha='center', fontsize=12)
        figure.text(0.5, 0.01, "Tempo do experimento (s)", ha='center', fontsize=12)
        figure.text(0.04, 0.5, "Largura de banda (Mbps)", va='center', rotation='vertical', fontsize=12)
        figure.tight_layout(rect=[0.12, 0.08, 0.95, 0.95])

        plt.subplots_adjust(left=0.12, bottom=0.09, right=0.95, top=0.91, wspace=0.2, hspace=0.3)


    fig_bar.text(0.5, 0.04, "Número de UEs", ha='center', fontsize=12)
    fig_bar.text(0.04, 0.5, "Largura de banda (Mbps)", va='center', rotation='vertical', fontsize=12)
    fig_bar.tight_layout(rect=[0.05, 0.05, 0.95, 0.95])
    # break

plt.show(block=False)
input("Press Enter to continue...")
