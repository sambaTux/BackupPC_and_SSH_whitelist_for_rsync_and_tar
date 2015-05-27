#!/bin/bash

# Title        : rsync_white
# Author       : sambaTux <sambatux AT web DOT de>
# Start date   : 04.04.2011
# OS tested    : Ubuntu10.04
# OS supported : Ubuntu10.04 ...
# BASH version : 4.1.5(1)-release
# Requires     : awk, sed, cut, grep, expr and bash build'ins like cutting vars, the "let" cmd, etc...
# Version      : 0.2
# Task(s)      : If you are using SSH and want to do a remote backup (e.g. using BackupPC), you probably have to login as "root". 
#                This is insecure. In order to allow "root" only the execution of "/usr/bin/rsync" and some of its 
#                commands, this script may be used. Thus, this script is intended to run on the backup clients.
#                In fact, this script works like a white list for rsync commands.

# LICENSE      : Copyright (C) 2011 Robert Schoen

#                This program is free software: you can redistribute it and/or modify it under the terms 
#                of the GNU General Public License as published by the Free Software Foundation, either 
#                version 3 of the License, or (at your option) any later version.
#                This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#                without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#                See the GNU General Public License for more details. [http://www.gnu.org/licenses/]


#####################################################################
# ADVICE 1: There are some (syntax) rules to follow, in order to use this script.
#           1) If rsync lets us the choice between long and the corresponding short commands, I mean every command
#              which has a "=" sign, then only the long commands are allowed.
#           2) Not every ARG type is supported. I.e. PATTERN and CONVERT_SPEC are not supported (yet).   
#           3) More information about the restrictions on specific ARG types can be found below in function argchecker()
#           4) Wildcards and spaces in file/dir names are not allowed. 
#           5) Regex, for instance in pattern/rules etc, are not allowed.
#           6) Every short command has to begin with a hyphen. I.e "-a -v" is ok, "-av" is not ok.

# ADVICE 2: As you can see, this script doesn't cover every rsync command/function, but the most common one should be.

# ADVICE 3: If you want to disallow/allow some commands, you can do it below by changing the content of 
#           the array named "badcmds". Every cmd in that array is disallowed.

#####################################################################


# set -x  #expand every step while running script; good for debugging
# set -u  #find unbound vars in script
# set -n  #only check syntax without executing script


# Set this var to "on" to capture debugging output in logfile
debug="on"
logfile="/var/log/rsync_white/rsync_$(date +%d.%m.%Y-%k:%M:%S).log"
logdir="/var/log/rsync_white/"

# Create dir for logfile if it doesn't exist
if [ ! -d "$logdir" ]; then 
   mkdir "$logdir" &&
   chmod 0770 "$logdir"
fi

# Delete logfiles older than 12 days (change this to fit your needs)
find "$logdir" -type f -mtime +12 -exec rm '{}' \;


########################################################################
# Original ssh cmd from $SSH_ORINGINAL_COMMAND
# original_ssh_cmd="$SSH_ORIGINAL_COMMAND"
# [ "$debug" = "on" ] && echo "Incoming CMD is: \"$original_ssh_cmd\"" >>"$logfile" && echo "" >>"$logfile"

# For testing purpose we can use a regular file as input cmd. Otherwise uncomment the 2 lines above and comment this one.
original_ssh_cmd=`cat oricmd.txt`


####################################################################
# Array with bad cmds. This list is build manually. Yes by typing :(
# So, if you want a command to be excluded (means treat it as bad cmd), just enter/add it in this array.
badcmds=("-R" "--relative" "--no-implied-dirs" "-e" "--rsh=COMMAND" "--rsync-path=PROGRAM"\
     "--password-file=FILE" "--protocol=NUM" "--deamon" "-T" "-B" "-f" "-F" "--sockopts=OPTIONS"\
       "--super" "--no-OPTION" )

# Get number of bad cmds
numbadcmds=${#badcmds[@]}
[ "$debug" = "on" ] && echo "Number of manually defined bad cmds: $numbadcmds" >>"$logfile"


#####################################################################
# This list of cmds is copied from the rsync man page. Only the option "(-h) --help" were cut out, because of the parentheses.
# Hint: The 2 last options "--server" "--sender" were added manually.
# Hint: Never use TAB for adding new options! Use only spaces, otherwise cutting the options will not work correct!
fullcmdlist='
 -0, --from0                
 -4, --ipv4                 
 -6, --ipv6                 
 -8, --8-bit-output         
 -A, --acls                 
 -a, --archive              
     --address=ADDRESS      
     --append               
     --append-verify        
     --backup-dir=DIR       
 -b, --backup               
 -B, --block-size=SIZE      
     --blocking-io          
     --bwlimit=KBPS         
 -c, --checksum             
 -C, --cvs-exclude          
     --chmod=CHMOD          
     --compare-dest=DIR     
     --compress-level=NUM   
     --contimeout=SECONDS   
     --copy-dest=DIR        
     --copy-unsafe-links    
 -d, --dirs                 
     --del                  
     --delay-updates        
     --delete-after         
     --delete-before        
     --delete-delay         
     --delete               
     --delete-during        
     --delete-excluded      
     --devices              
 -D                         
 -E, --executability        
 -e, --rsh=COMMAND          
     --exclude-from=FILE    
     --exclude=PATTERN      
     --existing             
     --fake-super           
 -f, --filter=RULE          
     --files-from=FILE      
     --force                
 -F                         
 -g, --group                
 -H, --hard-links           
 -h, --human-readable       
     --iconv=CONVERT_SPEC   
     --ignore-errors        
     --ignore-existing      
 -I, --ignore-times         
 -i, --itemize-changes      
     --include-from=FILE    
     --include=PATTERN      
     --inplace              
 -k, --copy-dirlinks        
 -K, --keep-dirlinks        
 -L, --copy-links           
     --link-dest=DIR        
     --list-only            
 -l, --links                
     --log-file=FILE        
     --log-file-format=FMT  
     --max-delete=NUM       
     --max-size=SIZE        
     --min-size=SIZE        
     --modify-window=NUM    
 -m, --prune-empty-dirs     
 -n, --dry-run              
     --no-implied-dirs      
     --no-motd              
     --no-OPTION            
     --numeric-ids          
     --only-write-batch=FILE
 -O, --omit-dir-times       
 -o, --owner                
     --out-format=FORMAT    
     --partial-dir=DIR      
     --partial              
     --password-file=FILE   
     --port=PORT            
 -p, --perms                
     --progress             
     --protocol=NUM         
 -P                         
 -q, --quiet                
     --read-batch=FILE      
     --remove-source-files                              
 -r, --recursive            
 -R, --relative             
     --rsync-path=PROGRAM   
     --safe-links           
     --size-only            
     --skip-compress=LIST   
     --sockopts=OPTIONS     
     --specials             
 -s, --protect-args         
 -S, --sparse               
     --stats                
     --suffix=SUFFIX        
     --super                
     --timeout=SECONDS      
 -T, --temp-dir=DIR         
 -t, --times                
 -u, --update               
     --version              
 -v, --verbose              
     --write-batch=FILE     
 -W, --whole-file           
 -x, --one-file-system      
 -X, --xattrs               
 -y, --fuzzy                
 -z, --compress
     --server
     --sender'

####################################################################
####################################################################
# Define arrays
declare -a badcmds shortcmds longcmds oricmds  i_specialcmds  #indexed arrays
declare -A specialcmds                                        #associative array

####################################################################
# Build indexed array "i_specialcmds" and associative array "specialcmds", without bad cmds.
specialcmd1=`echo "$fullcmdlist" | awk '{if($1 ~ "=") print $1}'`
specialcmd2=`echo "$fullcmdlist" | awk '{if($2 ~ "=") print $2}'`


# Init index for indexed array "i_specialcmds"
index=0

# This func. builds associative and indexed arrays
function build_specialcmds()
{
  [ "$debug" = "on" ] && echo "Now executing function build_specialcmds() ..." >>"$logfile"


  local specialcmdx="$1"
  local arraytype="$2"


  for cmd in $specialcmdx
  do

      # Check if cmd is a bad cmd
      x=0           # Index for array "badcmds"
      loopstop=0
      while [ $x -lt $numbadcmds -a $loopstop -eq 0 ]
      do
         if [ "${badcmds[$x]}" = "$cmd" ]; then
            loopstop=1

            if [ "$debug" = "on" -a "$arraytype" = "associative" ]; then
               echo "Build \"specialcmds\" => bad cmd found: "${badcmds[$x]}"" >>"$logfile"
            elif [ "$debug" = "on" -a "$arraytype" = "indexed" ]; then
               echo "Build \"i_specialcmds\" => bad cmd found: "${badcmds[$x]}"" >>"$logfile"
            fi
         fi
         ((x++))
      done

      # Import only good cmds in array
      if [ $loopstop -eq 0 ]; then
         # Cut away RIGHT part of cmd until first "=" incl.  (use "=" as delimiter) and append "=" again
         subscript="${cmd%=*}="

         if [ "$arraytype" = "associative" ]; then
            [ "$debug" = "on" ] && echo "Build \"specialcmds\" => GOOD cmd found: "$cmd"" >>"$logfile"
            # Cut away LEFT part of cmd until first "=" incl.  (use "=" as delimiter)
            value="${cmd#*=}"
            specialcmds[$subscript]="$value"

         elif [ "$arraytype" = "indexed" ]; then
              [ "$debug" = "on" ] && echo "Build \"i_specialcmds\" => GOOD cmd found: "$cmd"" >>"$logfile"
              i_specialcmds[$index]="$subscript"
              ((index++))
         fi
      fi

  done # End for loop

  unset cmd x loopstop subscript value specialcmdx  
  # Hint: $index is not unset here because this function is called twice,
  # for specialcmd1 and specialcmd2, to build ONE indexed array! Unsetting it later...

}  # End function "build_specialcmds"


#######################################################################
# Build associative array with special cmds, means cmds with args (look for sign "=")
# Build first part of associative array "specialcmds"
# Call function build_specialcmds
build_specialcmds "$specialcmd1" "associative"

# Build second part of associative array "specialcmds"
# Call function build_specialcmds
build_specialcmds "$specialcmd2" "associative"


#######################################################################
# Build first part of indexed array "i_specialcmds",
# means cmds with args, but only take the name from that cmds. With the "=" sign.
# Call function build_specialcmds
build_specialcmds "$specialcmd1" "indexed"

# Build second part of indexed array "i_specialcmds"
# Call function build_specialcmds
build_specialcmds "$specialcmd2" "indexed"

# Unset $index used in function build_specialcmds for building indexed array "i_specialcmds"
unset index 


#####################################################################
# Function to build array "shortcmds" and "longcmds"


function build_longshortcmds()
{
  [ "$debug" = "on" ] && echo "Now executing function build_longshortcmds() ..." >>"$logfile"

  local longshortcmd="$1"
  local arrayname="$2"
  local index=0

  for cmd in $longshortcmd
  do
     x=0           # Index for array "badcmds"
     loopstop=0

     while [ $x -lt $numbadcmds -a $loopstop -eq 0 ]
     do
        if [ "${badcmds[$x]}" = "$cmd" ]; then
           loopstop=1
           if [ "$debug" = "on" -a "$arrayname" = "shortcmds" ]; then
              echo "Build \"shortcmds\" => bad cmd found: "${badcmds[$x]}"" >>"$logfile"
           elif [ "$debug" = "on" -a "$arrayname" = "longcmds" ]; then
                echo "Build \"longcmds\" => bad cmd found: "${badcmds[$x]}"" >>"$logfile"
           fi
        fi
        ((x++))
     done

     # Import only good cmds in array and inc. index
     if [ $loopstop -eq 0 ]; then

        if [ "$arrayname" = "shortcmds" ]; then
           [ "$debug" = "on" ] && echo "Build \"shortcmds\" => GOOD cmd found: "$cmd"" >>"$logfile"
           shortcmds[$index]="$cmd"
        else
           [ "$debug" = "on" ] && echo "Build \"longcmds\" => GOOD cmd found: "$cmd"" >>"$logfile"
           longcmds[$index]="$cmd"
        fi

        ((index++))
     fi

  done # End for loop

  unset cmd x loopstop index longshortcmd

} # End function build_longshortcmds()


#####################################################################
# Build array with list of short commands
shortcmd=`echo "$fullcmdlist" | cut -c 2-3`

# Call function build_longshortcmds
build_longshortcmds "$shortcmd" "shortcmds"


########################################################################
# Build array with list of long commands, but without special cmds!
longcmd=`echo "$fullcmdlist" | cut -c 6-28 | grep -v '.*='`

# Call function build_longshortcmds
build_longshortcmds "$longcmd" "longcmds"


##################################################################
# Build array with cmds received from rsync.
# These are the cmds which will be executed (if they are not bad cmds)

# Get original cmds from $SSH_ORIGINAL_COMMAND
oricmd="$original_ssh_cmd"

index=0
for cmd in $oricmd
do   
   oricmds[$index]="$cmd"

   # Delete $cmd in oricmd string
   oricmd=`echo "$oricmd" | sed "s#"$cmd"##"`

   ((index++))
done

unset index cmd


########################################################################
# Debugging => show content of every array
if [ "$debug" = "on" ]; then
   echo ""                                             >>"$logfile"
   echo "Content of indexed array \"shortcmds\":"      >>"$logfile"
   echo "${shortcmds[@]}"                              >>"$logfile"
   echo ""                                             >>"$logfile"
   echo "Content of indexed array \"longcmds\":"       >>"$logfile"
   echo "${longcmds[@]}"                               >>"$logfile"
   echo ""                                             >>"$logfile"
   echo "Content of ASSOCIATIVE array \"specialcmds\":" >>"$logfile"
   echo "${specialcmds[@]}"                            >>"$logfile"
   echo ""                                             >>"$logfile"
   echo "Content of indexed array \"i_specialcmds\":"  >>"$logfile"
   echo "${i_specialcmds[@]}"                          >>"$logfile"
   echo ""                                             >>"$logfile"
   echo "Content of indexed array \"badcmds\":"        >>"$logfile"
   echo "${badcmds[@]}"                                >>"$logfile"
   echo ""                                             >>"$logfile"
   echo "Content of indexed array \"oricmds\":"        >>"$logfile"
   echo "${oricmds[@]}"                                >>"$logfile"
   echo ""                                             >>"$logfile"
fi

########################################################################
###############             CHECK CMDs                  ################
########################################################################

# Now we have to check if there is any bad cmd or special cmd with bad args 
# among the received cmds. If so, exit script.

# This function checks if the argument of a special cmd is good or bad. If bad, exit script.
function argchecker()
{

  [ "$debug" = "on" ] && echo "Now executing function argchecker() ..." >>"$logfile"

  local argtype="$1"
  local arg="$2"

  case "$argtype" in
       "DIR"|"FILE")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a correct absolute or relative path. 
            # If not, exit script. No spaces and wildcards allowed. Max 100 chars. 
            chkpath=`echo "$arg" | sed 's#^[\/a-zA-Z0-9\._-]\{1,100\}#x#'`

            if [[ "$chkpath" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\" name." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" name !! Quitting ..." >>"$logfile"
               exit 1                               
            fi
       ;;

      "NUM"|"SECONDS"|"PORT"|"KBPS")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"

            # Test if we have a correct number/digit. If not, exit script
            chkdigit=`echo "$arg" | sed 's#[[:digit:]]\{0,20\}#x#'`

            if [[ "$chkdigit" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"."	>>"$logfile"	
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi

      ;;

      "PATTERN")  # Not supported (yet) !!

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"
            [ "$debug" = "on" ] && echo "ARGs with type \"$argtype\" are not supported!! Quitting ..."  >>"$logfile"
            exit 1
      ;;

      "CONVERT_SPEC")  # Not supported (yet) !!
      
            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"
            [ "$debug" = "on" ] && echo "ARGs with type \"$argtype\" are not supported!! Quitting ..."  >>"$logfile"
            exit 1
      ;;

      "RULE")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"

            # Test if we have a correct rule. Only long names like "exclude", "include" etc. are allowed!
            # Please note that we must use a underscore instead of a space to delimit! 
            # I.e. --filter='exclude_folder1' is ok, but --filter='exclude folder1' is NOT ok.
            # Rules like --filter=:C  or  --filter=-C (as mentioned in rsync man page) are not allowed.
            chkrule=`echo "$arg" |
                     sed 's#^'\''\(include_\|exclude_\|merge_\|dir-merge_\|hide_\|show_\|\
                                   protect_\|risk_\|clear_\)[\/a-zA-Z0-9\._-]\{1,\}['\'']$#x#'`

            if [[ "$chkrule" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi	

      ;;

      "FORMAT"|"FMT")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a correct format FORMAT. i.e. for output format
            # The format has to look like this: %n%L or %n %L (please note that max. 2 spaces between are allowed)
            chkformat=`echo "$arg" | sed 's#^[%][ a-zA-Z]\{1,2\}[%]\{0,1\}[ a-zA-Z]\{0,2\}$#x#'`

            if [[ "$chkformat" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi

      ;;

      "LIST")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a correct list of file suffixes, separated by "/". 
            # Max 20 suffixes witch max. 10 chars per suffix. No wildcards or regex allowed.
            chklist=`echo "$arg" | sed 's#^[[:alnum:]]\{1,10\}\(\/\{1\}[[:alnum:]]\{1,10\}\)\{0,20\}#x#'`

            if [[ "$chklist" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi
      ;;

      "SUFFIX")   # Is a string

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a correct suffix. Chars like "." and "-" and "_" and digits are allowed. Max 5 chars.
            chkstring=`echo "$arg" | sed 's#^[_\.[:alnum:]-]\{1,5\}#x#'`

            if [[ "$chkstring" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"" >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi
      ;;

      "SIZE")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a correct size format. 
            # Test if we have a float number with or without this units (KiB, MiB, GiB, KB, MB, GB) 
            # I.e. 1.5MiB or 5MB or only 5 is ok. 
            # Signed numbers like -1 and +1 (as mentioned in rsync man page) are not allowed.
            chksize=`echo "$arg" | sed 's#^[[:digit:]]\{1,5\}[\.]\{0,1\}[[:digit:]]\{1,5\}\([kKmMgG]i\{0,1\}[Bb]\)\{0,1\}$#x#'`
            if [[ "$chksize" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi
      ;;

      "CHMOD")

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"
 
            # Test is we have correct rights like chmod=ugo=rwX. Upper and lower case allowed, SUID bits are not.
            chkchmod=`echo "$arg" | sed 's#^[ugo]\{1,3\}=[rwx]\{1,3\}$#x#'`

            if [[ "$chkchmod" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi
      ;;

      "ADDRESS")  # Only IPv4 addresses allowed, no names or IPv6

            [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

            # Test if we have a valid IPv4 address
            chkip=`echo "$arg" | sed 's#^\(25[0-5]\|2[0-4][0-9]\|[01]\{0,1\}[0-9][0-9]\{0,1\}\)\.\(25[0-5]\|2[0-4][0-9]\|[01]\{0,1\}[0-9][0-9]\{0,1\}\)\.\(25[0-5]\|2[0-4][0-9]\|[01]\{0,1\}[0-9][0-9]\{0,1\}\)\.\(25[0-5]\|2[0-4][0-9]\|[01]\{0,1\}[0-9][0-9]\{0,1\}\)$#x#'`


            if [[ "$chkip" = "x" ]]; then
               goodcmd=1    # Means that arg is ok
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
            else
               [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
               exit 1
            fi
      ;;

      *)

            [ "$debug" = "on" ] &&
            echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile" 
            echo "ERROR: ARGTYPE \"$argtype\" not supported by argchecker() !!! Quitting ..." >>"$logfile"
            exit 1
      ;;

   esac

   unset argtype arg

} # End function argchecker()



#################################################################################################
#################################################################################################
# Run through "oricmds" array and check if cmd is in one of the arrays

# Get number of elements in "oricmds" array
numoricmds=${#oricmds[@]}

# Get number of elements in "shortcmds" array
numshortcmds=${#shortcmds[@]}

# Get number of elements in "longcmds" array
numlongcmds=${#longcmds[@]}

# Get number of elements in "i_specialcmds" array
numi_specialcmds=${#i_specialcmds[@]}



# Run through array "oricmds" and check if cmd is good or bad
for ((i=0; i < $numoricmds; i++))
do
  cmd="${oricmds[$i]}"
  goodcmd=0     # Indicates if cmd is good or bad. 0=bad, 1=good
  cmdispath=0   # Indicates if cmd is a path or not. 0=no, 1=yes

  [ "$debug" = "on" ] && echo "Now checking cmd \"$cmd\" ..." >>"$logfile"


  # The first cmd must be "/usr/bin/rsync", else quit script
  if [ $i -eq 0 ]; then
     if [[ "$cmd" = "/usr/bin/rsync" ]]; then
        goodcmd=1
     else
        [ "$debug" = "on" ] && echo "CMD \"$cmd\" NOT ALLOWED => Quitting ..." >>"$logfile"
        exit 1
     fi
  fi
 
  # If cmd doesn't start with an hyphen, treat it as path or file name => call argchecker()
  if [[ $i -gt 0 ]] && [[ "$cmd" =~ ^[^-] ]]; then
     [ "$debug" = "on" ] && echo "CMD \"$cmd\" is treated as path. Call argchecker() with parameter \"DIR\"." >>"$logfile"
     argchecker "DIR" "$cmd"
     cmdispath=1
  fi


  index=0

  # Go trough array "shortcmds" and check if cmd is within it
  [ "$debug" = "on" -a $goodcmd -eq 0 -a $cmdispath -eq 0 ] && echo "Entering shortcmds loop" >>"$logfile"

  while [ $index -lt $numshortcmds -a $goodcmd -eq 0 -a $cmdispath -eq 0 ]
  do
     if [[ "$cmd" = "${shortcmds[$index]}" ]]; then
        goodcmd=1
     fi
     ((index++))
  done

  index=0

  # Go trough array "longcmds" and check if cmd is within it
  [ "$debug" = "on" -a $goodcmd -eq 0 -a $cmdispath -eq 0 ] && echo "Entering longcmds loop" >>"$logfile"

  while [ $goodcmd -eq 0 -a $index -lt $numlongcmds -a $cmdispath -eq 0 ]
  do
     if [[ "$cmd" = "${longcmds[$index]}" ]]; then
        goodcmd=1
     fi
     ((index++))
  done

  [ "$debug" = "on" -a $goodcmd -eq 0 -a $cmdispath -eq 0 ] && echo "Entering i_specialcmds loop" >>"$logfile"
  # Go trough array "i_specialcmds" and check if cmd is within it.
  if [ $goodcmd -eq 0 -a $cmdispath -eq 0 ] && [[ "$cmd" =~ "=" ]]; then
     # In order to verify if special cmd is allowed or not,
     # we need only the left part of the cmd (but with the "=" sign)
     # So we cut away the right part of the cmd and append the "=" sign again
     leftcmd="${cmd%%=*}="
     [ "$debug" = "on" ] &&
     echo "Searching for special CMD \"$leftcmd\" in array \"i_specialcmds\" ..." >>"$logfile"

     index=0

     # Go trough array "i_specialcmds" and check if cmd is within it If so, cmd is good => call argchecker()
     while [ $index -lt $numi_specialcmds ]
     do
        if [[ "$leftcmd" = "${i_specialcmds[$index]}" ]]; then
           [ "$debug" = "on" ] &&
           echo "Special CMD \"$leftcmd\" found => searching its ARG type ... " >>"$logfile"

           # To know which parameter argchecker() is started with, we need the cmd argtype,
           # i.e. DIR, FILE, NUM, KBPS, RULE etc... For that we use the associative
           # array "specialcmds".

           # Get arg type
           argtype="${specialcmds["$leftcmd"]}"

           if [ -n $argtype ]; then
              # Now we need also the actual ARG of the cmd.
              # So we cut away the left part of the cmd inclusive the "=" sign.
              arg="${cmd#*=}"

              if [ "$debug" = "on" ]; then
                 echo "ARG type \"$argtype\" for cmd \"$leftcmd\" found."              >>"$logfile"
                 echo "Call argchecker() with parameter \"$argtype\" and arg \"$arg\"" >>"$logfile"
              fi

              # Call argchecker() with appropriate parameter and the arg. itself
              case "$argtype" in
                   "FILE"|"DIR"|"NUM"|"SECONDS"|"PORT"|"KBPS"|"FORMAT"|"FMT"|\
                   "PATTERN"|"CONVERT_SPEC"|"RULE"|"LIST"|"SUFFIX"|"SIZE"|"CHMOD"|"ADDRESS")

                        argchecker "$argtype" "$arg"
                   ;;

                   *)

                        [ "$debug" = "on" ] &&
                        echo "Error: UNDEFINED ARGTYPE \"$argtype\" !!!" >>"$logfile" 
                        echo "Thus, unable to call argchecker(). Quitting ..." >>"$logfile"
                        exit 1
                   ;;

              esac

           else
               [ "$debug" = "on" ] &&
               echo "NO argtype for cmd \"$leftcmd\" found !! Quitting ..." >>"$logfile"
               exit 1
           fi # End check if arg is ok or not
        fi # End searching $leftcmd in array "i_specialcmds"

        ((index++))
     done # End while loop for checking specialcmds
  fi  # End check for special cmds


  # If $goodcmd is not 1 then cmd is NOT allowed and the game is over !! => exit script.
  # This test includes also the results from func. "argchecker()".
  if [ $goodcmd -ne 1 ]; then
     [ "$debug" = "on" ] && echo "CMD \"$cmd\" NOT ALLOWED !!! Quitting ..." >>"$logfile"
     exit 1
  else
     [ "$debug" = "on" ] && echo "CMD \"$cmd\" is allowed. Checking next cmd ..." >>"$logfile"
     unset leftcmd arg argtype cmd
  fi

done # End for loop


###############################################################################################
# When every test is passed, exec. $SSH_ORIGINAL_COMMAND
[ "$debug" = "on" ] && echo "EXECUTION of \"$original_ssh_cmd\" GRANTED. " >>"$logfile"

# Exec. rsync command
$SSH_ORIGINAL_COMMAND

# Happy end
exit 0




