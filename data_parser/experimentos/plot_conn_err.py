import csv
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.patheffects as path_effects
import numpy as np

MAX_AXIS_X = 5
MAX_AXIS_Y = 1

mpl.rc('font',family='Times New Roman')

COLOR_FREE5GC_MAIN = "orange"
COLOR_FREE5GC_LINE = "tab:orange"

COLOR_OPEN5GS_MAIN = "cornflowerblue"
COLOR_OPEN5GS_LINE = "royalblue"

vm_configs = [ "TG2-12C-8GB" ] #[ "TG2-8C-8GB", "TG2-6C-8GB", "TG2-4C-4GB" ]
cores_name = [ 'free5GC', 'Open5GS' ]
execs = [ 500, 400, 300, 200, 100 ]     # Delays between connections in ms
cores = [ 2, 3 ]                        # free5GC and Open5GS
experiments = [ 1, 3, 5, 7, 9, 11 ]     # Experiments 1 to 11, step 2

core_res = np.zeros((len(execs), len(experiments), len(cores)), dtype=float)
core_stats = np.zeros((len(execs), len(experiments), len(cores)), dtype=float)

for vm in vm_configs:
    base_filename = vm + "_logs.csv"

    axis_x = 0
    axis_y = 0
    figure, axis = plt.subplots(MAX_AXIS_X, MAX_AXIS_Y)
    figure.canvas.manager.set_window_title(vm)
    figure.set_size_inches((6, 7))

    rects1 = None
    rects2 = None

    with open(base_filename, newline='') as csvfile:
        reader = csv.DictReader(csvfile)

        for row in reader:
            delay_connection = int(row['delay_connection'])
            core = int(row['core'])
            num_gnb = int(row['num_gnb'])
            ue_fail_sum = float(row['num_ue_fail_sum'])
            ue_fail_percent = float(row['ue_fail_percent'])
            ue_fail_avg = float(row['num_ue_fail'])
            ue_fail_pvar = float(row['ue_fail_pvar'])
            ue_fail_stdev = float(row['ue_fail_pstdev'])

            # core_res = np.append(core_res, [delay_connection, core, num_gnb, ue_fail_percent])
            idx_exe = execs.index(delay_connection)
            idx_core = cores.index(core)
            idx_exp = experiments.index(num_gnb)

            core_res[idx_exe][idx_exp][idx_core] = ue_fail_avg
            core_stats[idx_exe][idx_exp][idx_core] = ue_fail_stdev

    for idx_exe, exe in enumerate(execs):
        width = 0.8
        x = np.array(experiments)

        curr_ax = None
        if (MAX_AXIS_Y == 1):
            curr_ax = axis[axis_x]
        elif (MAX_AXIS_X == 1):
            curr_ax = axis[axis_y]
        else:
            curr_ax = axis[axis_y][axis_x]

        rects1 = curr_ax.bar(x - width/2, core_res[idx_exe][:,0], width, label=cores_name[0], color=COLOR_FREE5GC_MAIN)
        rects2 = curr_ax.bar(x + width/2, core_res[idx_exe][:,1], width, label=cores_name[1], color=COLOR_OPEN5GS_MAIN)

        curr_ax.plot(x, core_stats[idx_exe][:,0], color=COLOR_FREE5GC_LINE) #, path_effects=[path_effects.SimpleLineShadow(), path_effects.Normal()])
        curr_ax.plot(x, core_stats[idx_exe][:,1], color=COLOR_OPEN5GS_LINE) #, path_effects=[path_effects.SimpleLineShadow(), path_effects.Normal()])

        curr_ax.scatter(x, core_stats[idx_exe][:,0], s=10, color=COLOR_FREE5GC_LINE)
        curr_ax.scatter(x, core_stats[idx_exe][:,1], s=10, color=COLOR_OPEN5GS_LINE)
        
        curr_ax.set_title(str(exe) + " ms", fontsize=12)
        # curr_ax.set_xlabel("Numero de gNBs")
        # curr_ax.set_ylabel("Average UEs failed")
        curr_ax.set_xticks(experiments)
        # curr_ax.legend()

        # curr_ax.bar_label(rects1, padding=3)
        # curr_ax.bar_label(rects2, padding=3)

        axis_y += 1
            
        if axis_y == MAX_AXIS_Y:
            axis_x += 1
            axis_y = 0

        if (axis_x == MAX_AXIS_X):
            break


    # figure.suptitle('Tempo entre cada conexão (ms)')
    figure.text(0.5, 0.04, "Número de gNBs por núcleo", ha='center', fontsize=12)
    figure.text(0.04, 0.5, "Média e desvio padrão de falhas de conexão", va='center', rotation='vertical', fontsize=12)
    figure.tight_layout(rect=[0.15, 0.1, 0.95, 0.93])

    plt.subplots_adjust(left=0.15, bottom=0.1, right=0.95, top=0.93, wspace=0.5, hspace=0.65)

    plt.figlegend([rects1, rects2], cores_name, loc = 'upper left', ncol=5, labelspacing=0., fontsize=12)
    plt.show(block=False)

input("Press Enter to continue...")
