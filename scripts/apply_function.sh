#!/bin/bash

# Default values
code_function_name=
kubeless_function_name=
kubeless_function_runtime="nodejs12"
kubeless_function_zip_filename="./dist/main.js.zip"
kubeless_function_handler_filename="main"
kubeless_trigger_gateway="nginx"
kubeless_trigger_cors="true"
kubeless_trigger_hostname=
kubeless_trigger_basic_auth_secret="basic-auth"

error (){
    local msg=$1
    echo -e "\033[31mFATA[0000]\e[0m ${msg}"
    usage
    exit
}

usage(){
  cat << EOF
Usage: bash ./scripts/deploy_function.sh -fn greet_promise -hn dev.example.com
Short  | Full                                  | Default
-fn    | --code_function_name                  | Required
-hn    | --kubeless_trigger_hostname           | Required
-rt    | --kubeless_function_runtime           | nodejs12
-zf    | --kubeless_function_zip_filename      | main.js.zip
-hf    | --kubeless_function_handler_filename  | main
-gw    | --kubeless_trigger_gateway            | nginx
-cr    | --kubeless_trigger_cors               | true
-ba    | --kubeless_trigger_basic_auth_secret  | basic-auth
-h     | --help
EOF
}

while [ "$1" != "" ]; do
    case $1 in
        -fn | --code_function_name )
            shift
            code_function_name=$1
        ;; 
        -hn | --kubeless_trigger_hostname )
            shift
            kubeless_trigger_hostname=$1
        ;;                  
        -rt | --kubeless_function_runtime )
            shift
            kubeless_function_runtime=$1
        ;;   
        -zf | --kubeless_function_zip_filename )
            shift
            kubeless_function_zip_filename=$1
        ;;            
        -hf | --kubeless_function_handler_filename )
            shift
            kubeless_function_handler_filename=$1            
        ;;      
        -gw | --kubeless_trigger_gateway )
            shift
            kubeless_trigger_gateway=$1            
        ;;   
        -cr | --kubeless_trigger_cors )
            shift
            kubeless_trigger_cors=$1            
        ;;       
        -ba | --kubeless_trigger_basic_auth_secret )
            shift
            kubeless_trigger_basic_auth_secret=$1            
        ;;                                                             
        -h | --help ) usage
            exit
        ;;
        * )          usage
            exit 1
    esac
    shift
done

[[ -z ${code_function_name} ]] && error "Node function name is required"
kubeless_function_name="${code_function_name//_/-}"

[[ -z ${kubeless_trigger_hostname} ]] && error "Host name is required"

print_info() {
    printf "\033[0;36mINFO\033[0m[0000]"
}

spinner() {
    pid=$! # Process Id of the previous running command
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
        i=$(( (i+1) %4 ))
        printf "\b${spin:$i:1}"
        sleep .1
    done
}

wait_for_function() {
    printf "$(print_info) Waiting for ${kubeless_function_name} to be ready ...  "
    while true; do
        kubeless_status=$(kubeless function ls | grep "${kubeless_function_name}.*0/[0-9]* NOT READY")
        pod_status=$(kubectl get pods -l function=${kubeless_function_name} | grep "Init:")
        [[ -z $kubeless_status && -z $pod_status ]] && break || sleep 2
    done & spinner
    printf "\\r$(print_info) Waiting for ${kubeless_function_name} to be ready ... Ready!\n"
    sleep 1
}

create_http_trigger (){
    if [[ -z $(kubeless trigger http ls | grep "${kubeless_function_name}") ]]; then
    $(kubeless trigger http create "${kubeless_function_name}" \
        --function-name "${kubeless_function_name}" \
        --gateway "${kubeless_trigger_gateway}" \
        $([[ ! -z $(echo ${kubeless_trigger_hostname} | grep 'localhost') ]] \
            && echo "" || echo "--hostname ${kubeless_function_name}.${kubeless_trigger_hostname}") \
        $([[ ! -z $kubeless_trigger_cors ]] \
            && echo "--cors-enable" || echo "") \
        $([[ ! -z $kubeless_trigger_basic_auth_secret ]] \
            && echo "--basic-auth-secret $kubeless_trigger_basic_auth_secret" || echo ""))
    else
        echo "$(print_info) HTTP Trigger exists"
    fi
}

# Install dependencies (including dev dependencies)
yarn install

# Build
yarn build:dev || exit


CHECKSUM_SHA256="sha256:$(cat ${kubeless_function_zip_filename} | sha256sum - | cut -d' ' -f1)"
FUNCTION_BASE64=$(cat ${kubeless_function_zip_filename} | base64)

# TODO: deal with python dependencies
DEPENDENCIES=$(cat ./package.json | jq '. | { "dependencies": .dependencies }')

cat ./templates/kubeless_template.yml | yq .  \
 | jq --arg check_sum "${CHECKSUM_SHA256}" '.spec.checksum=$check_sum' \
 | jq --arg function_base64 "${FUNCTION_BASE64}" '.spec.function=$function_base64' \
 | jq --arg runtime "${kubeless_function_runtime}" '.spec.runtime=$runtime' \
 | jq --arg handler "${kubeless_function_handler_filename}.${code_function_name}" '.spec.handler=$handler' \
 | jq --arg name "${kubeless_function_name}" '.metadata.name=$name' \
 | jq --arg name "${kubeless_function_name}" '.metadata.label.function=$name' \
 | jq --arg name "${kubeless_function_name}" '.spec.service.selector.function=$name' \
 | jq --arg deps "${DEPENDENCIES}" '.spec.deps=$deps' \
 | yq . > ./templates/kubeless_temp_template.json \
 && kubectl apply -f ./templates/kubeless_temp_template.json \
 && create_http_trigger \
 && wait_for_function \
 && echo "$(print_info) View logs:" \
 && echo kubectl logs -f -l function=${kubeless_function_name}
