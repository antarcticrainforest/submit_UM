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


#Create the umuisubmit scripts
$PROCESSED_DIR/submit.sh


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
#---------------------------------------------
# Do Extract if requested
#---------------------------------------------
[[ -z $argv ]] && argv='empty'
if [ ${argv:0:3} == 'ext' ];then
   
   RC=0
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
      echo MAIN_SCR: Extract OK
   else
      echo MAIN_SCR: Extract failed >&2
      echo MAIN_SCR stopped with return code $RC
      exit
   fi
   echo $(basename $0): Creating git repository in $UM_ROUTDIR
  cd $UM_ROUTDIR 
  git init
  git add .
  git commit -am 'Fetched the source file (Happy Hacking)'
  exit
fi
#---------------------------------------------
#   Submit to compile or/and run
#---------------------------------------------

if test $RC -eq 0 ; then
   RUN_FILE=stage_1_submit
   echo
   echo MAIN_SCR: Calling UMSUBMIT ...

     $PROCESSED_DIR/umsubmit.sh \
     -h raijin.nci.org.au \
     -u ${USERID} \
     -m 4 \
      ${RUNID}    \
      ${RUN_FILE}

   RC=$?
   if test $RC -eq 0 ; then
     echo MAIN_SCR: Submit OK
   else
     echo MAIN_SCR: Submit failed >&2
   fi
fi 

exit 0

#EOF  
