const readline = require("readline");
const fs = require("fs");

const ANALYTICS_FLAG = "[ANALYTICS]";

const args = process.argv.slice(2);
const input_file = args[0];
const output_file = args[1];

if (!input_file || !output_file) {
  console.log(`\nUse: ${process.argv[0]} input.txt output.csv\n`);
  process.exit(1);
}

const instream = fs.createReadStream(input_file);
const outstream = fs.createWriteStream(output_file);

const readInterface = readline.createInterface({
  input: instream,
  console: false,
});

let devices = {};
readInterface.on("line", (line) => {
  if (!line.includes(ANALYTICS_FLAG)) return;

  const index = line.indexOf(ANALYTICS_FLAG) + ANALYTICS_FLAG.length + 1;
  const data_str = line.slice(index, -1);

  const data = data_str.split(", ");

  let device = devices[data[1]] ?? { type: parseInt(data[0]), tasks: {} };
  device.tasks[data[2]] = parseInt(data[3]);
  devices[data[1]] = device;
});

let devices_processed = {};
instream.on("end", () => {
  Object.keys(devices).forEach((key) => {
    let device = devices_processed[key] ?? { type: devices[key].type, tasks: {} };

    const tasks = devices[key].tasks;
    Object.keys(tasks).forEach((task) => {
      if (task == "StartRegistration") return;

      device.tasks[task] = tasks[task] - tasks["StartRegistration"];
      devices_processed[key] = device;
    });
  });

  const tasks = getTasksNameCsv(devices_processed[Object.keys(devices_processed)[0]]);
  const header = `id,type,${tasks}`;
  outstream.write(header);

  Object.keys(devices_processed).forEach((key) => {
    const device = devices_processed[key];
    const tasks = getTasksValuesCsv(device);
    const line = `${key},${device.type},${tasks}`;
    outstream.write(`\n${line}`);
  });

  outstream.end();
});

function getTasksNameCsv(object) {
  let keys = [];
  Object.keys(object.tasks).forEach((task) => {
    keys.push(task);
  });

  return keys.join(",");
}

function getTasksValuesCsv(object) {
  let keys = [];
  Object.keys(object.tasks).forEach((task) => {
    keys.push(object.tasks[task]);
  });

  return keys.join(",");
}
