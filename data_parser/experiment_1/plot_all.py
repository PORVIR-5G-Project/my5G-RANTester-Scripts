import csv
import matplotlib.pyplot as plt
import numpy as np

base_filename = 'my5grantester-logs-{}-{}-{}.csv'
cores = [ 2, 3 ]
cores_name = [ 'free5GC', 'Open5GS' ]
execs = [ 500, 400, 300, 200 ]      # Delays between connections in ms
experiments = list(range(1, 12))    # Experiments 1 to 11

MAX_AXIS_X = 2
MAX_AXIS_Y = 2

plt.style.use('seaborn-whitegrid')

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

            with open(base_filename.format(core, exp, exe), newline='') as csvfile:
                reader = csv.DictReader(csvfile)

                for row in reader:
                    if time_base == 0:
                        time_base = int(row['timestamp'])
                    
                    try:
                        dataplaneready = np.append(dataplaneready, float(row['DataPlaneReady']))
                        timestamp = np.append(timestamp, (int(row['timestamp']) - time_base) / 1000000000)
                    except:
                        continue

                axis[axis_x, axis_y].plot(timestamp, dataplaneready, label = "#gNB {}".format(exp))

        #axis[axis_x, axis_y].plot(timestamp, dataplaneready, label = "#gNB {} (Delay {})".format(exp, exe))
        axis[axis_x, axis_y].set_title("{} (Delay {})".format(cores_name[core_idx], exe))
        axis_y += 1
        if axis_y == MAX_AXIS_Y:
            axis_y = 0
            axis_x += 1

    #figure.legend()        
    plt.show(block=False)

input("Press Enter to continue...")