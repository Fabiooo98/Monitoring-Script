# Monitoring-Script

This repository is used for my bachelor thesis.
## Prerequisites
`ifstat` needs to be installed on the target device.

This can be achieved by issueing the following commands:

`sudo apt-get install ifstat`
## Execution
The script can be executed via the following command:

`bash script.sh [-a] [-f] [-t]`

`[-a]` Will specify how many samples will be taken. The default value is 10 samples.

`[-f]` Will specify what the name of the output file is. The default value is 'data'.

`[-t]` Will specify the amount of time between measurements in seconds. The default value is 10 seconds.


`bash script.sh -h`

Will output the aforementioned usage instructions.

## Output
The collected data will be saved in `.csv` file in the same directory as the script itself. The name of said output file can be customized using the `[-f]` argument.
