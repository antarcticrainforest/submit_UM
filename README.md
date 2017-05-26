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
The ouptut directory is : /home/565/mb6059/umui_jobs/vasxa 
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

`setup.py` creates a file called `DIR_SCR`. This file needs to be edited. You should edit the following variables:

| Variable Name | Purpose |
| ------ | ------ |
|extr_host | the server host name where the model source is located (default accessdev.nci.org.au) | 
|RHOST_NAME | the name of the host server (default raijin.nci.org.au)|
|RUNID | The id of the experiment |
|UM_RDATADIR| The extract location on extr_host|
|UM_ROUTDIR|The final location of the model source|

This variables are needed but don't have to be necessarily change 

| Variable Name | Purpose |
| ------ | ------ |
|DATAW |The path where the model output is saved|


### Running the script

The model source code should only be extracted once from the svn server. To initially extract the source simply run:
```sh
$ ./main.sh --extr
```
This will extract the model source into the directory you have chosen in `DIR_SCR`(`UM_ROUTDIR`). By default the scripts also creates a git repository in the source code folder. Once the source is extracted you can start changing the model source code. 

Once changes are done and committed in your local git repository (not neseccary but recommended) you can run the ``MAIN_SCR`` script without any parameters

```sh
$ ./main.sh
```

This compiles the edited model version and submits the job for calculation.