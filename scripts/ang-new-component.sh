#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

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

[[ $is_module =~ ^[Yy]$ ]] && check_empty_string module_name "Please provide the name of the module"

check_YN is_export "Would you like to export the new component in a module?"

check_YN is_flat "Would you like to avoid creating component within new folder?"

check_YN at_spec_path "Would you like to create the new component at a specific path?"

[[ $at_spec_path =~ ^[Yy]$ ]] &&  get_path component_path

#Build options string
[[ $is_module =~ ^[Yy]$ ]] && options="$options--module=$module_name "
[[ $is_export =~ ^[Yy]$ ]] && options="$options--export "
[[ $is_flat =~ ^[Yy]$ ]] && options="$options--flat "
[[ $at_spec_path =~ ^[Yy]$ && -n $component_path ]] \
    && options="$options--path=${component_path%/} " #Leave it at the end

echo "ng generate component $component_name $options"
# shellcheck disable=SC2086
ng generate component "$component_name" $options #$options must be unquoted to treat it as separate options
