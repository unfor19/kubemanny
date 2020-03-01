#!/bin/bash
function_name="greet-promise"
host_name=$(kubectl get ing ${function_name} -o=jsonpath="{.spec.rules[0].host}")
name="meir"
response=$(curl --silent --location --request POST $host_name --header 'Content-Type: application/json' --header 'Authorization: Basic bXlfdXNlcl9uYW1lOm15X3Bhc3N3b3Jk' --data-raw '{ "name": "'$name'" }')
echo $response