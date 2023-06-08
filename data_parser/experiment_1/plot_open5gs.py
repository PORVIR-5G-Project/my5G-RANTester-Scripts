import csv
import matplotlib.pyplot as plt
import numpy as np

base_filename = 'my5grantester-logs-3-{}.csv'

plt.style.use('seaborn-whitegrid')

for exp in range(1, 12):
    time_base = 0
    timestamp = np.array([])
    dataplaneready = np.array([])

    with open(base_filename.format(exp), newline='') as csvfile:
        reader = csv.DictReader(csvfile)

        for row in reader:
            if time_base == 0:
                time_base = int(row['timestamp'])
            
            try:
                dataplaneready = np.append(dataplaneready, float(row['DataPlaneReady']))
                timestamp = np.append(timestamp, (int(row['timestamp']) - time_base) / 1000000000)
            except:
                continue

        plt.plot(timestamp, dataplaneready, label = "#gNB {}".format(exp))

plt.legend()        
plt.show()