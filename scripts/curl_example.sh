#!/bin/bash
name="meir"
username="my_user_name"
password="my_password"
function_name="greet-promise"

error (){
    local msg=$1
    echo -e "\033[31mFATA[0000]\e[0m ${msg}"
    usage
    exit
}

usage(){
  cat << EOF
Usage: bash ./scripts/curl_example.sh -n Willy
Short  | Full                  | Default
-n     | --name                | meir
-u     | --username            | username
-p     | --password            | my_password
-fn    | --function_name       | greet-promise
-hn    | --host_name           | [automatically-fetched]
-h     | --help
EOF
}

print_info() {
    printf "\033[0;36mINFO\033[0m[0000]"
}

while [ "$1" != "" ]; do
    case $1 in
        -u | --username )
            shift
            username=$1
        ;;      
        -p | --password )
            shift
            password=$1
        ;;       
        -fn | --function_name )
            shift
            function_name=$1
        ;;      
        -hn | --host_name )
            shift
            host_name=$1
        ;;   
        -ba | --basic_auth_secret )
            shift
            basic_auth_secret=$1
        ;;                
        -n | --name )
            shift
            name=$1
        ;;                                                                       
        -h | --help ) usage
            exit
        ;;
        * )          usage
            exit 1
    esac
    shift
done

host_name=$(kubectl get ing ${function_name} -o=jsonpath="{.spec.rules[0].host}")

[[ -z $function_name ]] && error "Kubeless Function Name secret is required"
[[ -z $host_name ]] && error "Kubeless Host Name is required"
[[ -z $username ]] && error "User name is required"
[[ -z $password ]] && error "Password is required"

echo "$(print_info) Function Name:     ${function_name}"
echo "$(print_info) Hostname:          ${host_name}"
echo "$(print_info) Username:          ${username}"
echo "$(print_info) Password:          ${password}"
echo "$(print_info) Invoking a request ..."

response=$(curl --silent --location --request POST "${host_name}" --user "${username}:${password}" --header 'Content-Type: application/json' --data-raw '{ "name": "'$name'" }' -w "\n$(print_info) Response time: %{time_starttransfer}ms\n")
echo "$(print_info) Response:      ${response}"
