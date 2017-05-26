#!/bin/ksh
#---------------------------------------------------------------------
# Name: SUBMIT
# Purpose: Creates umuisubmit_compile, umuisubmit_rcf 
#          and umuisubmit_run and any required wrapper scripts
#          on the remote platform. 
#         
# Created from UMUI vn8.6
#---------------------------------------------------------------------  

##########################################################
# Header common to all platforms                         #
##########################################################
export SHELL=/bin/ksh
. /etc/profile
export JOBDIR=$(dirname $(readlink -f $0))
. $JOBDIR/DIR_SCR

export SUBMITID=138160107                   
TYPE=NRUN	
CJOBN=$RUNID

echo -e "\nYour job directory on host $RHOST_NAME is: $JOBDIR\n"

###################################################
# Get date-time stamp for output files            #
# and set output class                            #
###################################################

OUTPUT_D=`date +%y%j`
OUTPUT_T=`date +%H%M%S`
OCO=leave

export MY_OUTPUT=$HOME/um_output
if ! test -d "$MY_OUTPUT"; then
   echo "Creating directory $MY_OUTPUT"
   mkdir -p $MY_OUTPUT
fi
COMP_OUT_PATH=$MY_OUTPUT
TARGET_OUT_PATH=$MY_OUTPUT

COMP_OUTFILE=$CJOBN.$RUNID.d$OUTPUT_D.t$OUTPUT_T.comp.$OCO
RCF_OUTFILE=$CJOBN.$RUNID.d$OUTPUT_D.t$OUTPUT_T.rcf.$OCO
RUN_OUTFILE=$CJOBN.$RUNID.d$OUTPUT_D.t$OUTPUT_T.$OCO

COMP_OUTPUT_FILE=$COMP_OUT_PATH/$COMP_OUTFILE
RCF_OUTPUT_FILE=$TARGET_OUT_PATH/$RCF_OUTFILE
RUN_OUTPUT_FILE=$TARGET_OUT_PATH/$RUN_OUTFILE

####################################################
# Set RUN_COMPILE, RUN_MODEL  variables            #
# to appropriate file umuisubmit_[compile/run/rcf] #
####################################################

. $JOBDIR/COMP_SWITCHES

# Run switches for all models
RUN_ATM=true
RUN_RCF=true
RUN_NEMO=false
RUN_CICE=false
RUN_NEMO_CICE=false
RUN_UM_NEMO_CICE=false

# Loop through all submodels and set up RUN_COMPILE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run_compile=false
for item
in UMSCRIPTS UMATMOS UMRECON NEMO CICE NEMO_CICE UM_NEMO_CICE
do
  eval compval=\$COMP_${item}
  if test $compval = "true" ; then
    run_compile=true
    break
  fi
done

RUN_COMPILE=$run_compile

# Loop through all submodels and set up RUN_MODEL
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run_model=false
for item
in ATM RCF NEMO CICE NEMO_CICE UM_NEMO_CICE
do
  varrun=RUN_${item}
  if test $item != "RCF" ; then 
  eval varrunval=$`echo $varrun`
  if test $varrunval = "true" ; then
    run_model=true
    break
  fi
  fi
done

RUN_MODEL=$run_model

###################################################
# Indicates if new recon. execut. required        #
###################################################

export RCF_NEW_EXEC=true 
if [[ $RCF_NEW_EXEC = "true" && $TYPE = "CRUN" ]]; then
    echo "You have selected a compilation step and  a continuation run CRUN."
    echo "This is not allowed. Please modify your UMUI settings."
    exit
fi

######################################################
# Define script names from which stage_1_scr will be #
# composed for different tasks: compilation, run or  #
# reconfiguration. Stage_2_scr will be embedded into #
# stage_1_scr, when all three tasks together have to #
# be performed                                       #
######################################################

comp_header=$JOBDIR/umuisubmit_compile_header
comp_script=$JOBDIR/umuisubmit_compile
rcf_header=$JOBDIR/umuisubmit_rcf_header
rcf_script=$JOBDIR/umuisubmit_rcf
run_header=$JOBDIR/umuisubmit_run_header
run_script=$JOBDIR/umuisubmit_run
stage_1_scr=$JOBDIR/stage_1_submit
stage_2_scr=$JOBDIR/stage_2_submit

for f in "$comp_header" "$comp_script" "$rcf_header" "$rcf_script" "$run_header" "$run_script" "$stage_1_scr" "$stage_2_scr" ; do
  rm -f $f
done
###################################################
# Processor usage                                 #
###################################################

NMPPE=16           # E-W decomposition
NMPPN=16           # N-S decomposition
NEMO_NPROC=0
FLUME_IOS_NPROC=0

########################################
# Calculate total PEs for use in job   #
########################################
let UM_NPES=$NMPPE*$NMPPN
# Number of processors requested, including sub-models
((TOTAL_PE_REQ=$UM_NPES))
echo "Total PEs requested: $TOTAL_PE_REQ"

########################################
# Reconfiguration: Processor Usage     #
########################################
RCF_NPROCX=1      # E-W decomposition
RCF_NPROCY=1      # N-S decomposition
RCF_NPES=1

###################################################
#                               MACHINE SPECIFIC  #
###################################################
# TARGET_MC is used in path to small execs and scripts
export TARGET_MC=linux

# Submission command and output file names
export SUB_CMD="qsub"
export SUB_OUT_RCF=""
export SUB_OUT_RUN=""
export SUB_OUT_CMP=""

###################################################
# Create compilation header     MACHINE SPECIFIC  #
###################################################

COMP_WALLTIME="#PBS -l walltime=1:00:00"
COMP_WALLTIME="#PBS -l walltime=3600"

  cat >>$comp_header<<EOF
#!/bin/ksh
#PBS -l ncpus=4
#PBS -l mem=6000mb
$COMP_WALLTIME
#PBS -j oe
#PBS -o $COMP_OUTPUT_FILE
#PBS -l software=intel-compiler



# Load default programming environment for PBS Pro
. ~access/umdir/vn8.6/environment

EOF

###################################################
# Create reconfiguration header MACHINE SPECIFIC  #
###################################################

  cat >>$rcf_header<<EOF
#!/bin/ksh
#PBS -l walltime=600
#PBS -l ncpus=1
#PBS -l mem=2000mb
#PBS -j oe
#PBS -o $RCF_OUTPUT_FILE
#PBS -q express



# Load default programming environment for PBS Pro
. ~access/umdir/vn8.6/environment

# The reconfiguration script manually sets the stacksize with this variable,
# rather than using 'ulimit -s unlimited'
export RCF_STACK=1 # in GB
EOF

###################################################
# Create run header             MACHINE SPECIFIC  #
###################################################

  cat >>$run_header<<EOF
#!/bin/ksh
#PBS -l walltime=50:00
#PBS -l ncpus=256
#PBS -l mem=384000mb
#PBS -j oe
#PBS -o $RUN_OUTPUT_FILE



# Load default programming environment for PBS Pro
. ~access/umdir/vn8.6/environment

EOF

###################################################
# Concatinate headers with  platform independent  #
# body scripts                                    #
###################################################

# Compilation ===================
  cat $comp_header >>$comp_script
  cat $JOBDIR/COMP_SWITCHES >>$comp_script
  cat $JOBDIR/FCM_BLD_COMMAND >>$comp_script

# Reconfiguration =============
  cat $rcf_header >>$rcf_script
  cat >>$rcf_script<<EOF
export RUN_ATMOS=false
export RCF_ATMOS=true
export RCF_NEW_EXEC=false
EOF

# Run =========================
  cat $run_header >>$run_script
  cat >>$run_script<<EOF
export RUN_ATMOS=true
export RCF_ATMOS=false
export RCF_NEW_EXEC=false
EOF

################################################### 
# Set up common variables used in NRUNs and CRUNs #
###################################################

cat >>$JOBDIR/umuisubmit_vars<<EOF

# Choose shell "set" options for  lower level scripts
export SETOPT=""          
export TYPE=$TYPE

# SCM switch
export SCM_ATMOS=false 

export AUTO_RESUB=Y
export MY_OUTPUT=$MY_OUTPUT
export TARGET_MC=$TARGET_MC
export JOBDIR=$JOBDIR
export SUBMITID=$SUBMITID
export DONT_TIDY=false

# MPP time limits
export UM_NPES=$UM_NPES
export NPROC_MAX=$(($UM_NPES+$FLUME_IOS_NPROC))
export FLUME_IOS_NPROC=$FLUME_IOS_NPROC
export UM_ATM_NPROCX=$NMPPE
export UM_ATM_NPROCY=$NMPPN

export UM_THREAD_LEVEL=MULTIPLE 
export RCF_NPES=$RCF_NPES
export RCF_NPROCY=$RCF_NPROCY
export RCF_NPROCX=$RCF_NPROCX
EOF

###################################################
# Copy the above variables into run script        #
# and add the SCRIPT                              #
###################################################

  echo "export UMRUN_OUTPUT=$RUN_OUTPUT_FILE" >>$run_script
  cat $JOBDIR/umuisubmit_vars >> $run_script
  echo "# Flag to indicate fully coupled HadGEM3 run" >>$run_script
  echo "export HADGEM3_COUPLED=false" >>$run_script
  cat $JOBDIR/SCRIPT >>$run_script
  echo "exit \$RC" >>$run_script

###################################################
# Copy the above variables into rcf script        #
# and add the SCRIPT                              #
###################################################

  echo "export UMRUN_OUTPUT=$RCF_OUTPUT_FILE" >>$rcf_script
  cat $JOBDIR/umuisubmit_vars >> $rcf_script
  if [[ $RUN_MODEL = "true" ]]; then
    echo "export DONT_TIDY=true" >>$rcf_script
  else
    echo "export DONT_TIDY=false" >>$rcf_script 
  fi
  echo "export HADGEM3_COUPLED=false" >>$rcf_script
  cat $JOBDIR/SCRIPT >>$rcf_script
  echo "if test \$RC -ne 0; then" >>$rcf_script
  echo "exit \$RC" >>$rcf_script
  echo "fi" >>$rcf_script
    
###################################################
# Create a wrapper script and change permissions  #
###################################################

touch $stage_1_scr
chmod 755 $stage_1_scr
chmod 755 $comp_script
chmod 755 $rcf_script
chmod 755 $run_script

###################################################
# Compose stage_1_scr and stage_2_scr (if needed) #
###################################################

if [[ $RUN_COMPILE = "true" ]]; then
  # If true compile needs to be performed first by running script in stage 1.
  cat $comp_header >>$stage_1_scr
  cat <<EOF        >>$stage_1_scr
$comp_script $SUB_OUT_CMP
CC=\$?
EOF
  if [[ $RUN_RCF = "true" ]]; then
    # If true stage 2 is neeed and rcf needs to be run as script inside stage 2.
    if [[ $RUN_MODEL = "true" ]]; then
      # If true rcf to be run as script in stage 2 and model needs to be
      # scheduled inside stage 2.
      cat <<EOF >>$stage_1_scr
#if [ \$CC -eq 0 ]
#then
#  $SUB_CMD $stage_2_scr $SUB_OUT_RCF
#fi
EOF
      cat $rcf_header >>$stage_2_scr
      cat <<EOF       >>$stage_2_scr
$rcf_script $SUB_OUT_RCF
CC=\$?
if [ \$CC -eq 0 ]
then
  $SUB_CMD $run_script $SUB_OUT_RUN
fi
EOF
      chmod 755 $stage_2_scr
    else
      # We are not running model so schedule rcf inside stage 1.
      cat <<EOF >>$stage_1_scr
if [ \$CC -eq 0 ]
then
  $SUB_CMD $rcf_script $SUB_OUT_RCF
fi
EOF
    fi
  elif [[ $RUN_MODEL = "true" ]]; then
    # We are not running rcf so schedule model run inside stage 1.
    cat <<EOF >>$stage_1_scr
if [ \$CC -eq 0 ]
then
  $SUB_CMD $run_script $SUB_OUT_RUN
fi
EOF
  fi
elif [[ $RUN_RCF = "true" ]]; then
  # We are not compiling but running rcf so run rcf as script in stage 1.
  cat $rcf_header >>$stage_1_scr
  cat <<EOF       >>$stage_1_scr
$rcf_script $SUB_OUT_RCF
CC=\$?
EOF
  if [[ $RUN_MODEL = "true" ]]; then
    # We are runing model and rcf but not compiling so schedule model in 
    # stage 1.
    cat <<EOF >>$stage_1_scr
if [ \$CC -eq 0 ]
then
  $SUB_CMD $run_script $SUB_OUT_RUN
fi
EOF
  fi
else
  # We are not compiling or running rcf so run model as script in stage 1.
  cat $run_header >>$stage_1_scr
  cat <<EOF       >>$stage_1_scr
$run_script $SUB_OUT_RUN
EOF
fi

rm $JOBDIR/umuisubmit_vars
rm $JOBDIR/umuisubmit_compile_header
rm $JOBDIR/umuisubmit_rcf_header
rm $JOBDIR/umuisubmit_run_header

# Generate various scripts related to archiving

ARCHIVE_OUTFILE=$COMP_OUT_PATH/$CJOBN.$RUNID.d$OUTPUT_D.t$OUTPUT_T.'$(jobid)'.archive.$OCO
archi_sub=$JOBDIR/archi_submit
archi_scr=$JOBDIR/archi_script
archi_todo=$JOBDIR/archive.todo
archi_name=um_archiving
archi_path=/projects/cr/cprod/archiving/bin
rm -f $archi_sub $archi_scr $archi_todo

touch $archi_sub
touch $archi_scr
touch $archi_todo
# Generate the archi_submit script for archiving
cat >>$archi_sub<<EOF
#!/bin/ksh
#@ shell           = /usr/bin/ksh
#@ class           = serial
#@ job_type        = serial
#@ job_name        = ${RUNID}_arch
#@ output          = ${ARCHIVE_OUTFILE}
#@ error           = ${ARCHIVE_OUTFILE}
#@ notification    = never
#@ resources       = ConsumableMemory(300Mb)
#@ wall_clock_limit = 01:00:00
#@ node_usage      = shared
#@ queue

$archi_path/$archi_name ${DATAW%/}
EOF

# Generate the archi_script script for submitting archi_submit

cat >>$archi_scr<<EOF
#!/bin/ksh

llsubmit archi_submit
EOF

# Generate the archive_$RUNID.todo file. This contains the header information
# used by qsarchive.py

cat >>$archi_todo<<EOF
[header]
RUNID:${RUNID}
HOME:$HOME
DATAM:${DATAW%/}
VN:$VN

EOF
# END OF FILE
#echo "Submitting $stage_1_scr (compile job) via '$SUB_CMD' "
#$SUB_CMD $stage_1_scr $SUB_OUT_RCF

