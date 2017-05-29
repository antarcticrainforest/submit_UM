# Submit scripts for the UM
A collection of command line based tools to fetch and compile the source code as well as to submit jobs of the UK Met Offices Unified Model (UM)

This collection should be able to do the following:

- Extract the source code of the UM from a given repository into a chosen file-structure
- Compile edited source code 
- Submit the compiled model code to a HPC computing cluster

It should ease the workflow when the user has to modify the source code and wants to avoid using the umui graphical user interface.

### Pre-requisits
You will need a working `umui` (the graphical user interface for the UM) job configuration. 
### Installation
Once a working configuration is created. You will need hit the  `extract` button from within the `umui`. Once this is done the program will tell you the output directory path (e.g):
```sh
----------------------------------------------------------------------
Jobsheet Processing completed.
Processing complete, output in directory: /home/565/mb6059/umui_jobs/vasxa
```
Copy this directory and run the `setup.py` script:
```sh
$ python setup.py
```
During the execution of the script you will be ask for the location of the umui output path. Simply paste the copied path.
You can also change the host server name where the umui output is located (default is accessdev.nic.org.au):
```sh
$ python setup.py -h someservername.org
```

`setup.py` creates a file called `DIR_SCR`. This file stores some important environment variables that are needed to extract, compile and submit the model code.

### Running the script

The run script `main.sh` has three parameters:

|Command | Purpose |
| ------ |  ------ |
|--extr | Extracts the UM source code into the `UM_ROUTDIR` folder |
|--compile | Builds the extracted source |
|--run/--submit | Submits the UM job |

When running this script for the first time it is essential to extract the UM source code from the svn repository via: 
```sh
$ ./main.sh --compile
```

The extracted command will fetch the model source into the directory you have chosen by the `umui` (`UM_ROUTDIR`). The script also creates a git repository in this folder. Once the source is extracted you can start changing the code. Once changes are done and committed in your local git repository (not neseccary but recommended) you can compile the source with:
```sh
$ ./main.sh --compile
```
This compiles the edited model version. The built source can finally be submitted via:

```sh
$ ./main.sh --run
```
or:
```sh
$ ./main.sh --submit
```
