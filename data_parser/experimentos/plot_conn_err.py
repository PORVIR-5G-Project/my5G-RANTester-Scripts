import csv
import matplotlib.pyplot as plt
import numpy as np

MAX_AXIS_X = 2
MAX_AXIS_Y = 2

vm_configs = [ "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
execs = [ 500, 400, 300, 200, 100 ]     # Delays between connections in ms
cores = [ 2, 3 ]                        # free5GC and Open5GS
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

core_res = np.zeros((len(execs), len(experiments), len(cores)), dtype=float)

for vm in vm_configs:
    base_filename = vm + "_logs.csv"

    axis_x = 0
    axis_y = 0
    figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)
    figure.canvas.manager.set_window_title(vm)

    with open(base_filename, newline='') as csvfile:
        reader = csv.DictReader(csvfile)

        for row in reader:
            delay_connection = int(row['delay_connection'])
            core = int(row['core'])
            num_gnb = int(row['num_gnb'])
            ue_fail_percent = float(row['ue_fail_percent'])

            # core_res = np.append(core_res, [delay_connection, core, num_gnb, ue_fail_percent])
            idx_exe = execs.index(delay_connection)
            idx_core = cores.index(core)
            idx_exp = experiments.index(num_gnb)

            core_res[idx_exe][idx_exp][idx_core] = ue_fail_percent

    for idx_exe, exe in enumerate(execs):
        width = 0.8
        x = np.array(experiments)

        rects1 = axis[axis_x][axis_y].bar(x - width/2, core_res[idx_exe][:,0], width, label=cores_name[0])
        rects2 = axis[axis_x][axis_y].bar(x + width/2, core_res[idx_exe][:,1], width, label=cores_name[1])
        
        axis[axis_x][axis_y].set_title(str(exe) + " ms")
        axis[axis_x][axis_y].set_xlabel("Number of gNBs")
        axis[axis_x][axis_y].set_ylabel("UEs failed (%)")
        axis[axis_x][axis_y].set_xticks(experiments)
        axis[axis_x][axis_y].legend()

        # axis[axis_x][axis_y].bar_label(rects1, padding=3)
        # axis[axis_x][axis_y].bar_label(rects2, padding=3)

        axis_y += 1
            
        if axis_y == MAX_AXIS_Y:
            axis_x += 1
            axis_y = 0

        if (axis_x == MAX_AXIS_X):
            break

    figure.tight_layout()
    plt.show(block=False)

input("Press Enter to continue...")
