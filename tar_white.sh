#!/bin/bash      

# Title        : tar_white
# Author       : sambaTux <sambatux AT web DOT de>
# Start date   : 21.04.2011 
# OS tested    : Ubuntu10.04
# BASH version : 4.1.5(1)-release
# Requires     : awk, sed, tr, cut, grep, expr and bash build'ins like cutting vars, the "let" cmd, etc...
# Version      : 0.1
# Task(s)      : If you are using SSH and want to do a remote backup (e.g. using BackupPC), you probably have to login as "root". 
#                This is insecure. In order to allow "root" only the execution of "tar" and some of its 
#                commands, this script may be used. Thus, this script is intended to run on the backup clients.
#                In fact, this script works like a white list for tar commands.


#####################################################################
# ADVICE 1: There are some (syntax) rules to follow, in order to use this script.
#           1) If tar lets us the choice between long and the corresponding short commands, I mean every command
#              which has a "=" sign, then only the long commands are allowed.
#           2) Not every ARG type is supported. I.e. PATTERN, COMMAND etc. are not supported (yet).   
#           3) More information about the restrictions on specific ARG types can be found below in function argchecker()
#           4) Wildcards and spaces in file/dir names are not allowed. 
#           5) Regex, for instance in pattern/rules etc, are not allowed.
#           6) Each short command has to begin with a hyphen. I.e "-c -f" is ok, "-cf" is NOT ok.
#           7) Each long command has to have a "=" sign to commit its parameter. I.e. --mtime=2010-01-01 is ok, but 
#              --mtime 2010-01-01 is NOT ok.
#           8) A date must have this format: YYYY-MM-DD (Note the hyphens!)
#           9) --totals[=SIGNAL] is changed to --totals, because Backuppc uses that command, thus --totals=SIGHUB etc 
#              is not allowed anymore
 
# ADVICE 2: As you can see, this script doesn't cover every tar command/function, but the most common one should be.

# ADVICE 3: If you want to disallow/allow some commands, you can do it below by changing the content of 
#           the array named "badcmds". Every cmd in that array is disallowed.

# ADVICE 4: The default tar command from Backuppc has to be changed a bit, in order to let this script work:
#           default is: $sshPath -q -x -n -l root $host env LC_ALL=C $tarPath -c -v -f - -C $shareName+ --totals
#           changed is: $sshPath -q -x -n -l root $host env LC_ALL=C $tarPath -c -v --file=- --directory=$shareName+ --totals

#####################################################################


# set -x  #expand every step while running script; good for debugging"
# set -u  #find unbound vars in script"
# set -n  #only check syntax without executing script"


# Set this var to "on" to capture debugging output in logfile
debug="on"
logfile="/var/log/tar_white/tar_$(date +%d.%m.%Y-%k:%M:%S).log"
logdir="/var/log/tar_white/"

# Create dir for logfile if it doesn't exist
if [ ! -d "$logdir" ]; then 
   mkdir "$logdir" &&
   chmod 0770 "$logdir"
fi

# Delete logfiles older than 12 days
find "$logdir" -type f -mtime +12 -exec rm '{}' \;


########################################################################
# Original ssh cmd from $SSH_ORINGINAL_COMMAND
original_ssh_cmd="$SSH_ORIGINAL_COMMAND"
[ "$debug" = "on" ] && echo "Incoming CMD is: \"$original_ssh_cmd\"" >>"$logfile" && echo "" >>"$logfile"


# For testing purpose we can use a regular file as input cmd
# original_ssh_cmd=`cat oricmd.txt`


####################################################################
# Array with bad cmds. This list is build manually. Just copy the commands 1:1 in this array. The brackets will be 
# removed in the next step.
# So, if you want a command to be excluded (means treat it as bad cmd), just enter/add it in this array.
badcmds=("--sparse-version=MAJOR[.MINOR]" "-S" "--sparse" "--to-command=COMMAND" "-f" "--force-local" "-F" "--info-script=NAME" "--new-volume-script=NAME" "-L" "--tape-length=NUMBER" "-M" "--multi-volume" "--rmt-command=COMMAND" "--rsh-command=COMMAND" "--volno-file=FILE" "--pax-option=keyword[[:]=value][,keyword[[:]=value]]..." "-I" "--use-compress-program=PROG" "--backup[=CONTROL]" "--transform=EXPRESSION" "--xform=EXPRESSION" "--checkpoint-action=ACTION" "--totals[=SIGNAL]" "-?" "--help" "-g" "-b" "-H" "-V" "-C" "-K" "-N" "-T" "-X")

# Get number of bad cmds
numbadcmds=${#badcmds[@]}
[ "$debug" = "on" ] && echo "Number of manually defined bad cmds: $numbadcmds" >>"$logfile"

# Now we must eliminate the brackets in the array "badcmds"
index=0
while [ $index -lt $numbadcmds ]
do
    badcmds[$index]=`echo "${badcmds[$index]}" | tr -d '[' | tr -d ']'`
    ((index++))
done
unset index

#####################################################################
# This list of cmds is copied from "tar --help" and manipulated a bit to fit our needs.
# Hint: Never use TAB for adding new options! Use only spaces, or cutting the options will not work correct.
fullcmdlist='
-A, --catenate
    --concatenate  
-c, --create           
-d, --diff
    --compare   
    --delete        
-r, --append         
-t, --list            
    --test-label       
-u, --update            
-x, --extract
    --get     
    --check-device                                     
-g, --listed-incremental=FILE 
-G, --incremental        
    --ignore-failed-read 
-n, --seek                
    --no-check-device                            
    --occurrence[=NUMBER]                 
    --sparse-version=MAJOR[.MINOR]      
-S, --sparse                                            
-k, --keep-old-files  
    --keep-newer-files                          
    --no-overwrite-dir  
    --overwrite         
    --overwrite-dir                          
    --recursive-unlink 
    --remove-files    
-U, --unlink-first   
-W, --verify        
    --ignore-command-error
    --no-ignore-command-error                             
-O, --to-stdout           
    --to-command=COMMAND
    --atime-preserve[=METHOD]                                                                                
    --delay-directory-restore                                                          
    --group=NAME          
    --mode=CHANGES       
    --mtime=DATE-OR-FILE
-m, --touch             
    --no-delay-directory-restore                                             
    --no-same-owner  
    --no-same-permissions
    --numeric-owner     
    --owner=NAME       
-p, --preserve-permissions
    --same-permissions                                                     
    --preserve           
    --same-owner        
-s, --preserve-order
    --same-order                         
-f, --file=ARCHIVE      
    --force-local      
-F, --info-script=NAME
    --new-volume-script=NAME           
-L, --tape-length=NUMBER  
-M, --multi-volume       
    --rmt-command=COMMAND 
    --rsh-command=COMMAND
    --volno-file=FILE   
-b, --blocking-factor=BLOCKS  
-B, --read-full-records    
-i, --ignore-zeros        
    --record-size=NUMBER
-H, --format=FORMAT
    --old-archive
    --portability                          
    --pax-option=keyword[[:]=value][,keyword[[:]=value]]...                           
    --posix               
-V, --label=TEXT 
-a, --auto-compress                          
-I, --use-compress-program=PROG                      
-j, --bzip2          
    --lzma             
    --no-auto-compress                       
-z, --gzip
    --gunzip
    --ungzip
-Z, --compress
    --uncompress   
-J, --xz                   
    --lzop                
    --add-file=FILE                             
    --backup[=CONTROL] 
-C, --directory=DIR   
    --exclude=PATTERN
    --exclude-caches                             
    --exclude-caches-all  
    --exclude-caches-under                           
    --exclude-tag=FILE                           
    --exclude-tag-all=FILE 
    --exclude-tag-under=FILE                               
    --exclude-vcs         
-h, --dereference                                
    --hard-dereference                       
-K, --starting-file=MEMBER-NAME                            
    --newer-mtime=DATE     
    --no-null             
    --no-recursion       
    --no-unquote        
    --null             
-N, --newer=DATE-OR-FILE
    --after-date=DATE-OR-FILE                      
    --one-file-system 
-P, --absolute-names 
    --recursion     
    --suffix=STRING                                            
-T, --files-from=FILE   
    --unquote          
-X, --exclude-from=FILE 
    --strip-components=NUMBER                              
    --transform=EXPRESSION
    --xform=EXPRESSION                                                       
    --anchored            
    --ignore-case        
    --no-anchored                              
    --no-ignore-case  
    --no-wildcards   
    --no-wildcards-match-slash   
    --wildcards
    --wildcards-match-slash  
    --checkpoint[=NUMBER]                            
    --checkpoint-action=ACTION  
    --index-file=FILE     
-l, --check-links        
    --no-quote-chars=STRING 
    --quote-chars=STRING   
    --quoting-style=STYLE                          
-R, --block-number                             
    --show-defaults   
    --show-omitted-dirs                           
    --show-transformed-names
    --show-stored-names                        
    --totals                                                                              
    --utc        
-v, --verbose   
-w, --interactive
    --confirmation               
-o
-?, --help    
    --restrict         
    --usage           
    --version'

####################################################################
# Define arrays
declare -a badcmds shortcmds longcmds oricmds  i_specialcmds #indexed arrays
declare -A specialcmds                                       #associative array

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
       # First we have to remove each bracket in $cmd, because we want to check the cmd against the cmds in 
       # array "badcmds". And in "badcmds" are cmds without brackets.  
       cmd=`echo "$cmd" | tr -d '[' | tr -d ']'`          

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

    done
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


#Unset $index used in function build_specialcmds for building indexed array "i_specialcmds"
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

      # First we have to remove each bracket in $cmd, because we want to check the cmd against the cmds in 
      # array "badcmds". And in "badcmds" are cmds without brackets.  
      cmd=`echo "$cmd" | tr -d '[' | tr -d ']'`

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

    done
    unset cmd x loopstop index longshortcmd
 
} # End function build_longshortcmds()


#####################################################################
# Build array with list of short commands
shortcmd=`echo "$fullcmdlist" | cut -c 1-2`
# Call function build_longshortcmds
build_longshortcmds "$shortcmd" "shortcmds"


########################################################################
# Build array with list of long commands, but without special cmds!
longcmd=`echo "$fullcmdlist" | cut -c 5-59 | grep -v '='`

# Call function build_longshortcmds
build_longshortcmds "$longcmd" "longcmds"


##################################################################
# Build array with cmds received from tar.
# These are the cmds which will be executed (if they are not bad cmds)

# Get original cmds from $SSH_ORIGINAL_COMMAND
oricmd="$original_ssh_cmd"

index=0
concatcmds=0
for cmd in $oricmd
do   
     
    if [[ "$cmd" = "env" ]] && [[ $index -eq 0 ]]; then
       # That means that the 2. and 3. cmd must be "LC_ALL=C" and "/bin/tar"
       # so we gonna concat the 1. 2. and 3. cmd into first element (index=0) of array
       # The first element will than contain this string: "envLC_ALL=C/bin/tar". Yes, without spaces!
       # This will be controlled later in the script.
       concatcmds=3
    fi
    
    # Concat 1. 2. and 3. cmd into first element of array.
    if [ $concatcmds -gt 0 ]; then 
       oricmds[$index]="${oricmds[$index]}${cmd}"
       ((concatcmds--))
       ((index--)) 
    fi
        
    # When there is nothing (more) to concat, then import the cmds as usual, one per element.
    if [ $concatcmds -eq 0 -a $index -gt 0 ]; then
       oricmds[$index]="$cmd"
    fi

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
     "DIR"|"FILE"|"MEMBER-NAME"|"ARCHIVE")

           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

           # Test if we have a correct absolute or relative path. 
           # If not, exit script. No spaces and wildcards allowed. Max 100 chars. 
           chkpath=`echo "$arg" | sed 's#^[\/a-zA-Z0-9\._-]\{1,100\}#x#'`

           if [[ "$chkpath" = "x" ]]; then
              goodcmd=1    #means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\" name." >>"$logfile"
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" name !! Quitting ..." >>"$logfile"
              exit 1                               
           fi
     ;;

     "NUMBER"|"BLOCKS")
        
           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"
            
           # Test if we have a correct number/digit. If not, exit script
           chkdigit=`echo "$arg" | sed 's#[[:digit:]]\{1,20\}#x#'`

           if [[ "$chkdigit" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile" 
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
              exit 1
           fi 
           
     ;;

     "DATE-OR-FILE"|"DATE")

           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"" >>"$logfile"
 
           # Test if we have a correct date in format YYYY-MM-DD. A FILE NAME IS NOT ALLOWED!
           chkdate=`echo "$arg" | sed 's/^[1-2]\{1\}[0-9]\{3\}-\(0\{1\}[1-9]\{1\}\|1[0-2]\{1\}\)-\(0[1-9]\{1\}\|[1-2]\{1\}[0-9]\|3[0-1]\{1\}\)$/x/'`
      
           if [[ "$chkdate" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"."  >>"$logfile"
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
             exit 1
          fi
     ;;            
     
           
     "FORMAT")

           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"
           
           # Test if we have a correct format FORMAT.
           # The format has to be exactly one of the following words: gnu, oldgnu, pax, posix, ustar, V7
           chkformat=`echo "$arg" | sed 's#^\(gnu\|oldgnu\|pax\|posix\|ustar\|V7\)\{1\}$#x#'`

           if [[ "$chkformat" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
              exit 1
           fi
           
     ;;


     "STRING"|"NAME"|"TEXT")   # Is a string

           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"
           
           # Test if we have a correct suffix. Chars like "." and "-" and "_" and digits are allowed. Max 100 chars.
           chkstring=`echo "$arg" | sed 's#^[_\.[:alnum:]-]\{1,100\}#x#'`

           if [[ "$chkstring" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"" >>"$logfile"
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
              exit 1
           fi
     ;;

     "CHANGES")
  
           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"
 
           # Test is we have correct rights like --mode=640. SUID bits not allowed.
           chkchanges=`echo "$arg" | sed 's#^[0-7]\{3\}$#x#'`

           if [[ "$chkchanges" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
           else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
              exit 1
           fi
     ;;
          
     "METHOD")  
 
           [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"
                    
           # Test if we have correct method like --atime-preserve='replace' or --atime-preserve='system'
           chkmethod=`echo "$arg" | sed 's#^'\''\(replace\|system\)\{1\}'\''$#x#'`
                     
           if [[ "$chkmethod" = "x" ]]; then
              goodcmd=1    # Means that arg is ok
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is a correct \"$argtype\"." >>"$logfile"
          else
              [ "$debug" = "on" ] && echo "ARG \"$arg\" for cmd \"$leftcmd\" is NOT a correct \"$argtype\" !! Quitting ..." >>"$logfile"
              exit 1
          fi
     ;;
          
     "STYLE")

          [ "$debug" = "on" ] && echo "Now executing argchecker() with parameter \"$argtype\"." >>"$logfile"

          # Test if we have one of these styles: literal, shell, shell-always, c, c-maybe, escape, locale, clocale 
          # Note that the styles must be between single quotes
          chkstyle=`echo "$arg" | sed 's#^'\''\(literal\|shell\|shell-always\|c\|c-maybe\|escape\|locale\|clocale\)\{1\}'\''$#x#'`
                     
          if [[ "$chkstyle" = "x" ]]; then
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


 # The first cmd must be "/bin/tar" or "env" followed by "LC_ALL=C" and "/bin/tar", else quit script
 if [ $i -eq 0 ]; then
    if [[ "$cmd" = "/bin/tar" ]] || [[ "$cmd" = "envLC_ALL=C/bin/tar" ]]; then
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
 
 # If cmd is just one hyphen, then it is a good cmd. "-" stands for stdin. I.e. tar -f - -C / 
 if [[ $i -gt 0 ]] && [[ "$cmd" =~ ^-$ ]]; then
    goodcmd=1
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
           echo "Special CMD \"$leftcmd\" found => searching his ARG type ... " >>"$logfile"
     
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
                  "FILE"|"DIR"|"MEMBER-NAME"|"ARCHIVE"|"NUMBER"|"NAME"|"DATE-OR-FILE"|"METHOD"|"BLOCKS"|"FORMAT"|\
                  "PATTERN"|"CHANGES"|"TEXT"|"DATE"|"STRING"|"STYLE")
               
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


#############################################################################################
# When every test is passed, exec. $SSH_ORIGINAL_COMMAND
[ "$debug" = "on" ] && echo "EXECUTION of \"$original_ssh_cmd\" GRANTED. " >>"$logfile"

# Exec. rsync command
$SSH_ORIGINAL_COMMAND

# Happy end
exit 0




