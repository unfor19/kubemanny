#!/bin/bash
code_function_name=
kubeless_function_name=

error (){
    local msg=$1
    echo -e "\033[31mFATA[0000]\e[0m ${msg}"
    usage
    exit
}

print_info() {
    printf "\033[0;36mINFO\033[0m[0000]"
}

usage(){
  cat << EOF
Usage: bash ./scripts/deploy_function.sh -fn greet_promise -hn dev.example.com
Short  | Full                                  | Default
-fn    | --code_function_name                  | Required
-h     | --help
EOF
}

while [ "$1" != "" ]; do
    case $1 in
        -fn | --code_function_name )
            shift
            code_function_name=$1
        ;;                                                            
        -h | --help ) usage
            exit
        ;;
        * )          usage
            exit 1
    esac
    shift
done

[[ -z ${code_function_name} ]] && error "Code function name is required"
kubeless_function_name="${code_function_name//_/-}"

kubeless_function_ingress=$(kubectl get ing -l "created-by=kubeless" -o json | jq -r '.items[].metadata.name' | grep "${kubeless_function_name}")
[[ ! -z $kubeless_function_ingress ]] && kubectl delete ingress "${kubeless_function_ingress}"

kubeless function delete "${kubeless_function_name}"

kubectl delete all -l function=${kubeless_function_name}
