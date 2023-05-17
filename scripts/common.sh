#!/usr/bin/env bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

# Update text on the current line
function update_line {
  local echo_message=""
  local needs_go_to_start=false
  local steps=0
  local needs_go_back=false

  OPTIND=1 # Must have for correct work of the getopts command
  local opt
  local optspec=":s:tb-:"

  while getopts "$optspec" opt; do
    case $opt in
      s)
        local prev_val=$((OPTIND - 1))

        [[ $OPTARG != "${!prev_val}" ]] \
            && echo "Invalid value of -s option. Use -s $OPTARG instead of -s$OPTARG." >&2 \
            && return 1 #The argument must follow a space

        ! [[ $OPTARG =~ ^-{0,1}[0-9]+$ ]] \
            && echo "Invalid value of -s option. Must be a number." >&2 \
            && return 1 #The argument must be a number

        steps=$OPTARG ;;
      t)
        needs_go_to_start=true ;;
      b)
        needs_go_back=true ;;
      -) #double dash section for long-name positional parameters
        case "$OPTARG" in
          steps)
            ! [[ ${!OPTIND} =~ ^-{0,1}[0-9]+$ ]] \
                && echo "Invalid value of -s option. Must be a number." >&2 && return 1

            steps="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
          steps=*)
            val=${OPTARG#*=}
            ! [[ ${OPTARG#*=} =~ ^-{0,1}[0-9]+$ ]] \
                && echo "Invalid value of -s option. Must be a number." >&2 && return 1

            steps=${OPTARG#*=} ;;
          to-start)
            needs_go_to_start=true; OPTIND=$((OPTIND + 1)) ;;
          go-back)
            needs_go_back=true; OPTIND=$((OPTIND + 1)) ;;
          *)
            echo "Invalid option --${OPTARG}" >&2; return 1 ;;
        esac;;
      \?)
        echo "Invalid option: -$OPTARG" >&2; return 1 ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2; return 1 ;;
    esac
  done

  shift $((OPTIND - 1)) # shift the positional parameters to get the message argument
  echo_message=$1

  [[ $# -gt 1 ]] && \
      echo "The message must be the last one. Move the remaining options of '$*' to the beginning, or use parentheses." >&2 \
      && return 1

  { [[ $steps -gt 0 ]] && tput cuu "$steps"; } || { [[ $steps -lt 0 ]] && tput cud "${steps#*-}"; }

  tput el
  echo -en "$echo_message"

  $needs_go_to_start && tput cr

  $needs_go_back && { { [[ $steps -gt 0 ]] && tput cud "$steps"; } || \
      { [[ $steps -lt 0 ]] && tput cuu "${steps#*-}"; } }
}

# Loop until regex expression is false
function input_validation {
  local -n input=$1
  local message=$2
  local pattern=$3
  local error_message=${4:-$message}
  local sym_num=${5:-999999999}

  cnt=0
  while ! [[ "$input" =~ $pattern ]]; do
    if [[ $cnt -gt 0 ]]; then
      tput cuu 1
      tput el
    fi

    read -rep "$(echo -en "$([[ $cnt -gt 0 ]] && echo "$error_message" || echo "$message")")" -n "$sym_num" input

    ((cnt++))
  done
}

# Loop until a valid response Y or N is received
function check_YN {
  local -n val=$1
  local message_in=$2
  local message_color=${3:-$BWhite}

  local message="$Green? $message_color$message_in"
  local error_message="$Red? $Red$message_in"

  input_validation val "$message $Color_Off(y/N) " ^[YyNn]$ "$error_message $Color_Off(y/N) " 2

  #Display the reading result appropriately
  [[ "$val" =~ ^[Yy]$ ]] && update_line -s 1 "$message ${Green}Yes$Color_Off\n"
  [[ "$val" =~ ^[Nn]$ ]] && update_line -s 1 "$message ${Red}No$Color_Off\n"
}

# Loop until any symbol is entered
function check_empty_string {
  local -n val=$1
  local message_in=$2
  local message_color=${3:-$BWhite}

  local message="$Green? $message_color$message_in"
  local error_message="$Red? $message_in"

  input_validation val "$message: $Color_Off" [^\ ]+ "$error_message: $Color_Off"

  update_line -s 1 "$message: $Color_Off$val\n" #Display the reading result appropriately
}

function up_down_enter_esc {
  escape_char=$(printf "\u1b")

  while : ; do
    read -rsn1

    if [[ -z $REPLY ]]; then
      echo ENTER
      break
    elif [[ $REPLY == "$escape_char" ]]; then
      read -rsn2 -t0.01

      case $REPLY in
        '[A') echo UP; break ;;
        '[B') echo DN; break ;;
  #      '[D') echo LEFT ;;
  #      '[C') echo RIGHT ;;
        '') echo ESC; break ;;
#        *) >&2 echo 'ERR bad input' ;;
      esac
    fi
  done
}

shopt -s extglob

function print_subfolders {
  local sel=$1; shift
  local ar=("$@")

  # Print the initial list with > next to the first option
  for i in "${!ar[@]}"; do
    if [[ $i -eq $sel ]]; then
      echo -e "${Cyan}> ${ar[$i]}${Color_Off}"
    else
      echo -e "  ${ar[$i]}"
    fi
  done
}

function clear_subfolders {
  local cur_el=${1:-0}; shift
  local list=("$@")

  for el in "${!list[@]}"; do #Clear all lines
    update_line -bs $((cur_el - el))
  done

  update_line -s "$cur_el" #Go to the first empty line
}

function prompt_subfolders {
  local -n l_path=$1
  local -n l_selected=$2; l_selected=0
  local -n l_subfolders=$3; l_subfolders=("$l_path"*/)
  local message=$4

  [[ "$(find "${l_path:-./}" -maxdepth 1 -type d | wc -l)" -le 1 ]] \
      && { l_path=${l_path:=./}; return 1; } #If there are no folders, return error.

  [[ -n $message  ]] && echo -e "$message"

  print_subfolders $l_selected "${l_subfolders[@]}"

  tput cuu ${#l_subfolders[@]} # Move the cursor to the first line of the list
}

function get_path {
  shopt -s dotglob # Get all folders, even hidden

  local -n path=$1;
  local message_in=${2:-"Which folder would you like to choose?"}
  local message_color=${3:-$BWhite}

  local message="$Green? $message_color$message_in"
  local subfolders=("$path"*/)
  local selected=0

  ! prompt_subfolders path selected subfolders \
      "$message $Color_Off(Use arrow keys, Enter to select or Esc to finish)" \
      && return #If there are no folders, let's finish.

  tput civis # Suppress cursor showing

  while : ; do
    key=$(up_down_enter_esc) # Move the cursor up or down depending on the arrow key pressed

    if [[ $key == "UP" || $key == "DN" ]]; then
      update_line -t "  ${subfolders[$selected]}"

      local st=0; [[ $key == "UP" ]] && st=1 || st=-1 #When we move down it's minus 1
      [[ $key == "UP" && $selected -eq 0 || $key == "DN" && $selected -eq $((${#subfolders[@]} - 1)) ]] \
          && st=$((st * -(${#subfolders[@]} - 1))) #If we are at the top or bottom, we go back the entire length of the list.

      selected=$((selected - st))

      update_line -ts $st "${Cyan}> ${subfolders[$selected]}${Color_Off}"
    elif [[ $key == "ENTER" ]]; then
      path=${subfolders[$selected]}

      clear_subfolders "$selected" "${subfolders[@]}"

      ! prompt_subfolders path selected subfolders && break #If there are no folders, let's finish.
    elif [[ $key == "ESC" ]]; then
      clear_subfolders $selected "${subfolders[@]}"; break;
    fi

    update_line -bts $((selected + 1)) "$message $Green${path:-./}$Color_Off" #update message
  done

  update_line -bts $((selected + 1)) "$message $Green${path:-./}$Color_Off" #update message
  tput cnorm #Enable cursor visibility
}
