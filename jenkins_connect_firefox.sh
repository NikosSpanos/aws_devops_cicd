#Open a jenkins instance using firefor web browset
vm_ipaddress=$(terraform output -json | jq -r '.output_eip_public_ip.value')
firefox --new-tab $vm_ipaddress:8080
echo -e "\tSuccessfully opened jenkins environment"
