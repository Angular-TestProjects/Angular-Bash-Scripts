#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

is_lazy_route=""
lazy_route_url=""
need_import=""
import_module_name=""
is_flat="" #The component will be created without creating a new folder for it
at_spec_path=""
module_path=""

module_name=""

options=""

check_empty_string module_name "What name would you like to use for the module?"

check_YN is_lazy_route "Would you like to create it as a lazy load route with a new component?"

[[ $is_lazy_route =~ ^[Yy]$ ]] && check_empty_string lazy_route_url "Please provide a lazy route url"

#If $is_lazy_route is Y import module name required and we don't need to ask
[[ $is_lazy_route =~ ^[Nn]$ ]] \
    && check_YN need_import "Would you like to import it in another module?"

[[ $need_import =~ ^[Yy]$ || $is_lazy_route =~ ^[Yy]$ ]] \
    && check_empty_string import_module_name "Please provide a module name to import"

check_YN is_flat "Would you like to avoid creating module within new folder?"

check_YN at_spec_path "Would you like to create the new module at a specific path?"

[[ $at_spec_path =~ ^[Yy]$ ]] &&  get_path module_path

#Build options string
[[ $is_lazy_route =~ ^[Yy]$ ]] && options="$options--route=$lazy_route_url "
[[ $need_import =~ ^[Yy]$ || $is_lazy_route =~ ^[Yy]$ ]] \
    && options="$options--module=$import_module_name "
[[ $is_flat =~ ^[Yy]$ ]] && options="$options--flat "
[[ $at_spec_path =~ ^[Yy]$ && -n $module_path ]] \
    && options="$options--path=${module_path%/} " #Leave it at the end

echo "ng generate module $module_name $options"
# shellcheck disable=SC2086
ng generate module "$module_name" $options #$options must be unquoted to treat it as separate options
