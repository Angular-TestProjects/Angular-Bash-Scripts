#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

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


is_module=""
module_name=""
is_export=""
at_spec_path=""
component_path=""
is_flat="" #The component will be created without creating a new folder for it
component_name=""

options=""

check_empty_string component_name "What name would you like to use for the component?"

check_YN is_module "Would you like to add the new component to a specific module?"

[[ $is_module =~ ^[Yy]$ ]] && check_empty_string module_name "Enter module name"

check_YN is_export "Would you like to export the new component in a module?"

check_YN is_flat "Would you like to avoid creating component within new folder? "

check_YN at_spec_path "Would you like to create the new component at a specific path?"

[[ $at_spec_path =~ ^[Yy]$ ]] &&  get_path component_path # Loop until the user aborts the process

[[ $is_module =~ ^[Yy]$ ]] && options="$options--module=$module_name "
[[ $is_export =~ ^[Yy]$ ]] && options="$options--export "
[[ $is_flat =~ ^[Yy]$ ]] && options="$options--flat "
[[ $at_spec_path =~ ^[Yy]$ && -n $component_path ]] \
    && options="$options--path=${component_path%/} " #Leave it at the end

echo "ng generate component $component_name $options"
# shellcheck disable=SC2086
ng generate component "$component_name" $options

#echo "is_module: $is_module"
#echo "module_name: $module_name"
#echo "is_export: $is_export"
#echo "at_spec_path: $at_spec_path"
#echo "component_path: $component_path"
