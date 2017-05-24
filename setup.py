#!/usr/bin/env python2

import os,time,sys,re


def checkhost(rh):
  '''
  Fuction the checks the host name is different from accessdev.nci.org.au 
     which should be given with the command parameter

      Vriables:
        rh (str-object): default value if no parameter is given
  '''

  try:
    args=sys.argv[1:]
    if args[0].startwith('-h'):
      try:
        rh = args[1]
      except IndexError:
        sys.exit('Please indicate the host where umui is running')
    else:
     args=args[0].split('=')
     if len(args != 2):
        sys.exit('Please indicate the host where umui is running')
     else:
       rh=args[-1]
  except IndexError:
    pass

  return rh


def read(string):
  '''
  Function that waits until the user hits yes
  '''
  ans = 'n'

  while True:
    print string,"              \r"
    #sys.stdout.write(string)
    ans=raw_input()
    #sys.stdout.write('\r')
    #sys.stdout.flush()
    try:
      ans=ans.lower()[0]
    except IndexError:
      ans='y'
    if ans == 'y':
      break
    time.sleep(1)

def get_path():
  '''
    Returns the directory of the this script
  '''
  return os.path.dirname(os.path.abspath(sys.argv[0])) #The the path of this script

def copy(sources,targets,remotehost,remotepath):
  '''
    Function to copy (via scp) important files from the remote host
  '''
  for s,t in zip(sources,targets):
    cmd='scp -q %s:%s/%s %s' %(remotehost,remotepath,s,t)
    os.system(cmd) #Copy the stuff

def read_info(f1,remotehost,old):

  '''
    This function opens the downloaded files and looks for important
    information in within them

    Variables:
      f1 (str-object):  filename of the file containing the info in the 
                        EXTR_SCR script that has been created by the umui
      remotehost (str-obj): The name of the host where the um source is stored
  '''

  old=old.split('\n') #Convert strng the list for later use
  #Read the original EXTR_SCR script (copied as .tmp)
  with open(f1) as f:
    jobsheet = f.readlines()
  export=[]
  svn_serv=[''],['']
  #Get all important variables that are created here (like UM_SVN_URL)
  for ii,j in enumerate(jobsheet):
    if 'UM_SVN_BIND=' in j: #The svn url
      svn_serv=[j.strip()]
    elif 'UM_ROUTDIR' in j or 'UM_RDATADIR' in j: #The dir's of the source
      export.append('export %s'%j.strip())
    elif j.startswith('export'): #Any other important variable
      export.append(j.strip())
    if 'Local Script Variables' in j or 'Loop through' in j : #From here on we are done, exit
      break

  #Create also a variable (extr_host) containig the info about the remotehost
  extr_host=['export extr_host=%s'%remotehost]
  #Merge all the relevant info
  if len(svn_serv):
    export = svn_serv+export+extr_host
  else:
    export = export+extr_host
    
  if len(old) == 1:
    export =[('#Environment variables for FCM bindings and repositories\n'\
      '#and also data paths for the run environment\n')]+export


  #Delete f1 because it is not needed
  os.remove(f1)
  src = []
  for l in export:
    if l not in old:
        src.append(l)

  return '\n'.join(old+src)

def get_remote_path(question):
  '''
    This function asks the usere where the infromation about the um job
    is stored

    Variables:
      question (str-object): The prompt that the user is asked to type the
                              directory name
    Returns:
      str-object 
  '''
  remotepath = raw_input(question).strip()
  if len(remotepath) < 10: #Thats not a full path, exit
    sys.exit('Error path to short please give the full path name')

  return remotepath.rstrip('/')


if __name__ == '__main__':

  #First get the server name hosting the umui environment
  remotehost = checkhost('accessdev.nci.org.au')

  #Get the name of this directory
  thepath = get_path()
  #Wait until the user confirms that umui has been processed
  read('It is time to process your umui job! Hit the "Process" button and wait until the job has finished. Continue?  [Y|n] ')

  #Ask the user for the path of the umui job script output
  remotepath = get_remote_path('The output of the umui process should give a output path (output in directory). Copy and paste that path\n')

  #What are the important files in the remotepath on the remote_server?
  sources = ('FCM_*_CFG','EXTR_SCR','MAIN_SCR')
  targets = (thepath,'%s/.tmp'%thepath,'%s/.tmp2'%thepath)
  #Copy some of the files that contain vital info from the remote_host
  copy(sources,targets,remotehost,remotepath)

  #Get all the important information from the just copied files
  info = read_info(os.path.join(thepath,'.tmp'),remotehost,'')
  info = read_info(os.path.join(thepath,'.tmp2'),remotehost,info)

  #And save the info to the DIR_SCR file
  with open(os.path.join(thepath,'DIR_SCR'),'w') as f:
    f.write(info+'\n')

  #We are done let the user know
  print 'Installation done: You can now run MAIN_SRC --extr extract the code on create a git repo'

