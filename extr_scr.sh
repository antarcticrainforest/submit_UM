#!/bin/ksh
#---------------------------------------------------------------------
# Script: EXTR_SCR
# Purpose: generates extract command(s) depending on model's switches
#         
# Created from UMUI vn8.6
#---------------------------------------------------------------------  
  
#---------------------------------------------
# Job specific variables
#---------------------------------------------
export PROCESSED_DIR=$(dirname $(readlink -f $0))

. $PROCESSED_DIR/DIR_SCR
export UM_RDATADIR=$UM_ROUTDIR
export USERID=$USER


export UM_RHOST=$RHOST_NAME
export UM_RLOGNAME=$USERID
export UM_REMOTE_SHELL=ssh
export UM_MAINDIR=$UM_RDATADIR

# Local Script Variables
REPOS_DECL=${UM_CONTAINER%/*}
UM_RMAINDIR=$UM_ROUTDIR

. $PROCESSED_DIR/COMP_SWITCHES
   
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Extract Base Repository
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for item
in UMATMOS JULES FLAKE NEMO CICE
do

   eval extrval=\$EXTR_${item}
   if test ${extrval} = "true" ; then
      if test ! -d ${UM_MAINDIR}/baserepos/${item} ; then
          mkdir -p ${UM_MAINDIR}/baserepos/${item}
      fi

      export UM_OUTDIR=${UM_MAINDIR}/baserepos/${item}
      export UM_ROUTDIR=${UM_RMAINDIR}/baserepos/${item}

      if test -e $PROCESSED_DIR/FCM_EXTRACT_${item}_CFG ; then
         export UM_JOB_CFG=$PROCESSED_DIR/FCM_EXTRACT_${item}_CFG
      else
         export UM_JOB_CFG=/dev/null       
      fi


      RC=0
      echo "Extracting ${item} base repository..."
      export UM_REPOS_DECL=${REPOS_DECL}/${item}_repos.cfg@HEAD

     fcm extract  -v 3 $UM_CONTAINER #1> $UM_OUTDIR/ext.out 2>&1
      RC=$?
      if test $RC -eq 0 ; then
         echo ${item} base repository extract is OK
      else
         echo ${item} base repository extract failed
         exit $RC
      fi
   fi
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Extract Requested Sub-Models
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for item
in UMSCRIPTS UMATMOS UMRECON NEMO CICE NEMO_CICE UM_NEMO_CICE
do

   eval compval=\$COMP_${item}
   typeset -l blddir
   blddir=${item}

   if test $compval = "true" ; then
      if test ! -d ${UM_MAINDIR}/${blddir} ; then
         echo "created $blddir sub-directory."
         mkdir -p ${UM_MAINDIR}/${blddir}
      fi

      export UM_OUTDIR=${UM_MAINDIR}/${blddir}
      export UM_ROUTDIR=${UM_RMAINDIR}/${blddir}
  
     # Set overrides files properly before atmos or reconf extract   
      if test ${item} = "UMATMOS" -o ${item} = "UMRECON" ; then
         export UM_USR_MACH_OVRDS=$PROCESSED_DIR/USR_MACH_OVRDS
         export UM_USR_FILE_OVRDS=$PROCESSED_DIR/USR_FILE_OVRDS
         export UM_USR_PATHS_OVRDS=$PROCESSED_DIR/USR_PATHS_OVRDS
      else 
         export UM_USR_MACH_OVRDS=/dev/null
         export UM_USR_FILE_OVRDS=/dev/null  
         export UM_USR_PATHS_OVRDS=/dev/null 
      fi

      if test  ${item} = "NEMO" -o ${item} = "CICE" -o \
         ${item} = "NEMO_CICE" -o ${item} = "UM_NEMO_CICE" ; then
         export UM_REPOS_DECL=/dev/null
         cfg_script="NEMOCICE"
      else
         export UM_REPOS_DECL=${REPOS_DECL}/UMATMOS_repos.cfg@HEAD
         cfg_script=${item}
      fi

      echo "Extracting ${item} including any branches..."    
      export UM_JOB_CFG=$PROCESSED_DIR/FCM_${cfg_script}_CFG
      fcm extract  -v 3 $UM_CONTAINER #1> $UM_OUTDIR/ext.out 2>&1
      RC=$?
      if test $RC -eq 0 ; then
         echo ${item} extract is OK
      else
         echo ${item} extract failed
         exit $RC
      fi
   fi
done

