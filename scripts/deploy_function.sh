#!/bin/bash

# Default values
node_function_name=
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
-fn    | --node_function_name                  | Required
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
        -fn | --node_function_name )
            shift
            node_function_name=$1
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

[[ -z ${node_function_name} ]] && error "Node function name is required"
kubeless_function_name="${node_function_name//_/-}"

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
        status=$(kubeless function ls | grep "${kubeless_function_name}.*0/[0-9]* NOT READY")
        [[ -z $status ]] && break || sleep 2
    done & spinner
    printf "\\r$(print_info) Waiting for ${kubeless_function_name} to be ready ... Ready!\n"
    sleep 1
}

wait_for_delete() {
    printf "$(print_info) Waiting for ${kubeless_function_name} to be deleted ...  "
    while true; do
        status=$(kubeless function ls "${kubeless_function_name}")
        not_deleted=$(echo $status | grep "not found")
        [[ -z $not_deleted ]] && break || sleep 2
    done & spinner
    printf "\\r$(print_info) Waiting for ${kubeless_function_name} to be deleted ... Deleted!\n"
    sleep 1
}

http_trigger (){
    $(kubeless trigger http create "${kubeless_function_name}" \
        --function-name "${kubeless_function_name}" \
        --gateway "${kubeless_trigger_gateway}" \
        $([[ ! -z $(echo ${kubeless_trigger_hostname} | grep 'localhost') ]] \
            && echo "" || echo "--hostname ${kubeless_function_name}.${kubeless_trigger_hostname}") \
        $([[ ! -z $kubeless_trigger_cors ]] \
            && echo "--cors-enable" || echo "") \
        $([[ ! -z $kubeless_trigger_basic_auth_secret ]] \
            && echo "--basic-auth-secret $kubeless_trigger_basic_auth_secret" || echo "")) 
}

# Install dependencies (including dev dependencies)
yarn install

# Build
yarn build:dev || exit

# Delete if exists
kubeless_function_exists=$(kubeless function ls | grep "${kubeless_function_name}.*1/[0-9]*2 READY")
[[ -z $kubeless_function_exists ]] && \
    echo "$(print_info) Deleting ${kubeless_function_name}" && \
    $(kubeless function delete "${kubeless_function_name}") && \
    wait_for_delete

# Deploy
$(kubeless function deploy "${kubeless_function_name}" \
        --runtime "${kubeless_function_runtime}" \
        --from-file "${kubeless_function_zip_filename}" \
        --handler "${kubeless_function_handler_filename}.${node_function_name}" --dependencies package.json) \
    && http_trigger \
    && wait_for_function \
    && echo "$(print_info) View logs:" \
    && echo kubectl logs -f -l function=${kubeless_function_name}
