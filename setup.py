#!/usr/bin/env python2

import os,time,sys,re

def read(string):

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


def main(remote_host):


  read('It is time to process your umui job! Hit the "Process" button and wait until the job has finished. Continue?  [Y|n] ')

  remotepath=raw_input('The output of the umui process should give a output path (output in directory). Copy and paste that path\n')
  if len(remotepath) < 10:
    sys.exit('Error path to short please give the full path name')
  if remotepath[-1] == '/':
    remotepath=remotepath[:-1]
  thepath = os.path.dirname(os.path.abspath(sys.argv[0]))
  
  cmd='scp -q %s:%s/FCM_*_CFG %s' %(remote_host,remotepath,thepath)
  os.system(cmd)
  cmd='scp -q %s:%s/EXTR_SCR %s/.tmp' %(remote_host,remotepath,thepath)
  os.system(cmd)
  with open(os.path.join(thepath,'.tmp')) as f:
    jobsheet = f.readlines()
  export=[]
  for ii,j in enumerate(jobsheet):
    if 'UM_SVN_BIND=' in j:
      svn_serv=[j.strip()]
    elif j.startswith('export'):
      export.append(j.strip())
    if 'Job specific variables' in j:
      break
  
  export = svn_serv+export

  with open(os.path.join(thepath,'.DIR_SCR.bak')) as f :
    src = f.read()

  src +='\n\n#Environment variables for FCM bindings and repositories\n'
  src+='\n'.join(export)
  os.remove(os.path.join(thepath,'.tmp'))
  with open(os.path.join(thepath,'DIR_SCR'),'w') as f:
    f.write(src+'\n')
  print 'Installation done: Please edit now the paths file DIR_SCR how you like them'


if __name__ == '__main__':

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
    rh='accessdev.nci.org.au'
  main(rh)




