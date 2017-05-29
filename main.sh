#!/bin/ksh
#---------------------------------------------------------------------
# Script: MAIN_SCR
#---------------------------------------------------------------------
#
# Purpose: Calls fcm extract on a local machine and build
#          and/or run commands on a remote machine
#
# Created from umui vn8.6
#---------------------------------------------------------------------


#---------------------------------------------
# User defined environment variables and
# Job specific variables
#---------------------------------------------

export PROCESSED_DIR=$(dirname $(readlink -f $0))

. $PROCESSED_DIR/DIR_SCR
. $PROCESSED_DIR/COMP_SWITCHES

UM_RDATADIR=$UM_ROUTDIR
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

argv=$(echo $1 |tr -d '-'|tr '[:upper:]' '[:lower:]')
[[ -z $argv ]] && argv='empty'

case "${argv:0:3}" in
 ext )
    #Create the umuisubmit scripts
    $PROCESSED_DIR/submit.sh
    #---------------------------------------------
    # Do Extract if requested
    #---------------------------------------------
    echo
    echo main.sh: Calling Extract ...
    ssh $extr_host mkdir -p ${PROCESSED_DIR}
    rsync -avz ${PROCESSED_DIR%/}/* $extr_host:${PROCESSED_DIR%/}/
    if [ $? -eq 0 ];then
      echo main.sh: Copy ok
    else
       echo main.sh: Copy failed >&2
     exit $?
    fi
    ssh $extr_host $PROCESSED_DIR/extr_scr.sh
    RC=$?
    if test $RC -eq 0 ; then
      echo main.sh: Extract OK
    else
      echo main.sh: Extract failed >&2
      echo main.sh stopped with return code $RC
      exit
    fi
    echo $(basename $0): Creating git repository in $UM_ROUTDIR
    cd $UM_ROUTDIR 
    git init
    git add .
    git commit -am 'Fetched the source file (Happy Hacking)'
    exit 0
  ;;
com )
  #---------------------------------------------
  #   Submit to compile
  #---------------------------------------------

   RUN_FILE=stage_1_submit
   run='build'
   #echo
   #echo main.sh: Submitting build job for UM ...
   #  $PROCESSED_DIR/umsubmit.sh \
   #  -h raijin.nci.org.au \
   #  -u ${USERID} \
   #  -m 4 \
   #   ${RUNID}    \
   #   ${RUN_FILE}

   # RC=$?
   # if test $RC -eq 0 ; then
   #   echo main.sh: submission of build job ok
   # else
   #   echo main.sh: submission of build job failed >&2
   #   exit 1
   # fi
  ;;
sub|run )
  #---------------------------------------------
  #   Submit to run
  #---------------------------------------------
   RUN_FILE=stage_2_submit
   job='run'
    #$PROCESSED_DIR/umsubmit.sh \
    # -h raijin.nci.org.au \
    # -u ${USERID} \
    # -m 4 \
    #  ${RUNID}    \
    #  ${RUN_FILE}
    
  ;;
  *)
    echo "Usage $(basename $0) --{extract|compile|run|submit}" >&2
    exit 1
esac

cmd="qsub ${PROCESSED_DIR%/}/${RUN_FILE}"
echo
echo "main.sh: job submission of $cmd"
qsub ${PROCESSED_DIR%/}/${RUN_FILE}
RC=$?
if test $RC -eq 0 ; then
  echo "main.sh: submission of $run job ok"
  let ex=0
else
  echo "main.sh: submission of $run job failed >&2"
  let ex=1
fi
exit $ex
#EOF
