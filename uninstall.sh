#!/bin/bash
vars=$1
script=$2
INSECURE=--insecure
DOMAIN='--domain Domain1'

source $vars

security_delete() {
id=$1
echo "Удаление группы безопасности: $id произойдет в конце"
echo "echo \"Удаление группы безопасности $id\"" >> ./func_tmp_file.tmp
echo "openstack security group delete $id $INSECURE 2> /dev/null " >> ./func_tmp_file.tmp
}

volume_delete() {
id=$1
disk_da=$(openstack volume show $id -c attachments -f yaml $INSECURE | wc -l)
if [[ $disk_da -gt 2 ]]; then
server_id=$(openstack volume show $id -c attachments -f yaml $INSECURE | grep '^  server_id:' | awk -F ':' '{print$2}')
openstack server remove volume $server_id $id $INSECURE
fi
echo "Удаление тома: $id"
openstack volume delete $id $INSECURE
}

loadbalancer_delete() {
id=$1
echo "Удаление балансировщика нагрузки: $id"
openstack loadbalancer delete $id $INSECURE
}

loadbalancer_pool_delete() {
id=$1
if [[ $id == "create" ]]; then
lb_name=$(cat $script | grep 'pool create' | sed -n 's/.*--loadbalancer[[:space:]]\+\([^ ]\+\).*/\1/p')
id=$(openstack loadbalancer show $lb_name -c pools -f value $INSECURE)
fi
echo "Удаление пула балансировки нагрузки: $id"
openstack loadbalancer pool delete $id $INSECURE
}

loadbalancer_member_delete() {
id=$1
lmd_string=$(cat $script | grep $id)
pool=$(parser "$lmd_string" "--name" | sed 's/--insecure//g' | awk '{print $NF}' )
echo "Удаление участника балансировки нагрузки: $id из пула $pool"
openstack loadbalancer member delete $pool $id $INSECURE
}

loadbalancer_listener_delete() {
id=$1
openstack loadbalancer listener delete $(openstack loadbalancer show $id  -c listeners -f value $INSECURE) $INSECURE
echo "Удаление слушателя балансировщика нагрузки: $id"
}

floating_delete() {
id=$(openstack floating ip list --port $1 -c ID -f value $INSECURE)
echo "Удаление плавающего ip: $id"
openstack floating ip delete $id $INSECURE
}

port_delete() {
id=$1
echo "Удаление порта: $id"
openstack port delete $id $INSECURE 2> /dev/null
}

keypair_delete() {
id=$1
echo "Удаление ключевой пары: $id"
openstack keypair delete $id $INSECURE
}

router_delete() {
id=$1
PORTS_ID=$(openstack port list --router $id -c ID -f value $INSECURE)
echo "Отключение маршрутизатора: $id"
openstack router set "$id" --disable --no-route $INSECURE
echo "$PORTS_ID" | while read -r port_id; do
    openstack router remove port "$id" "$port_id" $INSECURE 2> /dev/null
done 
echo "Удаление маршрутизатора: $id"
openstack router delete $id $INSECURE
echo "$PORTS_ID" | while read -r port_id; do
    port_delete "$port_id"
done 
}

server_delete() {
id=$1
PORTS_ID=$(openstack port list --server $id -c Name -f value $INSECURE)
volumes_id=$(openstack server show $id -c attached_volumes -f yaml $INSECURE | grep '^  id:' | awk -F ':' '{print$2}')
echo "Удаление сервера: $id"
openstack server delete $id $INSECURE --wait
echo "$PORTS_ID" | while read -r port_id; do
    port_delete $port_id 2> /dev/null
done
echo $volumes_id | while IFS= read -r disk_id; do
volume_delete "$disk_id"
done
}

network_delete() {
id=$1
echo "Удаление сети: $id"
openstack network delete $id $INSECURE
}

subnet_delete() {
id=$1
echo "Удаление подсети: $id"
openstack subnet delete $id $INSECURE
}

user_delete() {
id=$1
echo "Удаление пользователя: $id"
openstack user delete $id $INSECURE $DOMAIN
}

project_delete() {
id=$1
echo "Удаление проекта: $id"
openstack project delete $id $INSECURE
}

domain_delete() {
id=$1
echo "Удаление домена: $id"
openstack domain set --disable $id $INSECURE
openstack domain delete $id $INSECURE
}

parser() {
    local line="$1"
    local result=()
    local nameopt=0
    local skip_next=false
    local add_flags=$2
    local flags_with_args=(
        --domain --project --project-domain --user-domain --password --email --description
        --default-project --public-key --image --flavor --volume --snapshot --boot-from-volume
        --volume-type --availability-zone --host --security-group --network --nic  --key-name
        --property --file --hint --user-data --config-drive --swap --ephemeral --min --max
        --block-device --block-device-mapping --metadata --prefix --url --container-format
        --disk-format --architecture --os-distro --os-version --kernel-id --ramdisk-id
        --min-disk --min-ram --checksum --owner --visibility --protected --size
        --backend --share-type --share-network --share-protocol --export-location
        --path --marker --limit --sort-key --sort-dir --share-type-access --target
        --proto --cidr --gateway --host-route --dns-nameserver --allocation-pool --mac-address
        --vnic-type --binding-profile --fixed-ip --floating-ip-address --floating-ip-pool
        --internal-ip --external-ip --interface --bandwidth --port-security-enabled
        --dhcp --host-id --device-id --device-owner --qos-policy --service-type --admin-state
        --mtu --router --external-gateway --enable-snat --disable-snat
        --auth-url --os-username --os-password --os-project-name --os-project-id --os-domain-name
        --os-user-domain-name --os-project-domain-name --image-property --trusted-image-cert
        --no-property --no-share-network --os-auth-type --os-token --token
        --auth-token --username --cert --key --cacert --client-id --client-secret
        --region-name --endpoint --api-version --output-format
        --log-file --status --reason --target-project --availability-zone-hint
        --router:external --lbaas-version --description-en --os-interface
        --os-region-name --os-auth-url --os-identity-api-version
        --format -f -c --loadbalancer --lb_algorithm --protocol --vip_port_id --address --default-pool --device --dst-port --protocol-port
    )
    if [[ -n $add_flags ]]; then
        line=$(echo "$line" | sed -E "s/\s*$add_flags\s+[^ ]+//g; s/\s*$add_flags\s*//g")
    fi
    read -ra words <<< "$line"
    for ((i=0; i<${#words[@]}; i++)); do
        if [[ "${words[i]}" == "--name" && $((i+1)) -lt ${#words[@]} ]]; then
            lname="${words[i+1]}"
	    nameopt=1
            continue
        fi
        if $skip_next; then
            skip_next=false
            continue
        fi
        for flag in "${flags_with_args[@]}"; do
            if [[ "${words[i]}" == "$flag" ]]; then
                skip_next=true
                continue 2  # skip flag and its value
            fi
        done
        result+=("${words[i]}")
    done
    if [[ $nameopt == 1 ]]; then
        echo "${result[@]}" $lname
    else
        echo "${result[@]}"
    fi
}

if [ $# -ne 2 ]; then
    echo "Использование: $0 <файл_переменных> <файл_установки>"
    exit 1
fi

if [ ! -f "$script" ]; then
    echo "Файл не найден: $script"
    exit 1
fi

grep '^openstack.*create' "$script" > ./uninstall_script_tmp_file.tmp
tac ./uninstall_script_tmp_file.tmp | \
while IFS= read -r line; do
    line1=$(echo "$line" | sed 's/--insecure//g')
    clear_line=$(echo $line1 | tr ' ' '\n' | grep -v 'public' | tr '\n' ' ')
    i_result=$(parser "$clear_line")
    result=$(echo $i_result |  sed -E 's/--[^ ]+//g')
    if [[ $? -eq 0 ]]; then
    type=$(echo "$result" | awk '{print $2}')
    if echo "$line" | grep -q loadbalancer; then
        if  echo "$result" | awk '{print$3}' | grep -q '^create$'; then
            type=$(echo "$result" | awk '{print $2}')
        else
            type=$(echo "$result" | awk '{print $2"_"$3}') 
        fi
    else 
    type=$(echo "$result" | awk '{print $2}')
    fi
    name=$(echo "$result" | awk '{print $NF}')
    func="${type}_delete $name $add_var1"
    eval "$func"
    fi
done
if [[ -f ./func_tmp_file.tmp ]]; then
	bash ./func_tmp_file.tmp
	rm -rf ./func_tmp_file.tmp
fi
rm -rf ./uninstall_script_tmp_file.tmp
