#!/bin/bash

config_path="/opt/conf/cluster.xml"
target_path="/home/omm/cluster.xml"
data_path="/opengauss/cluster"
db_prefix=""
cms_prefix=""
name="$HOSTNAME"
pod_ips=()
pod_names=()

if [ "$IS_CMS" == "true" ]
then
    name=`hostname | sed 's/-cms//1'`
fi

function get_db_name() {
        name=$(echo "$name" | sed 's/-[0-9]*$//')
        db_prefix="${name}-"
        for i in {0..2}
        do
                pod_names+=("${db_prefix}${i}")
        done
        echo 'pod_names: '${pod_names[@]:0:3}
}

function get_cms_name() {
        cms_prefix="${name}-cms-"
        for i in {0..2}
        do
                pod_names+=("${cms_prefix}${i}")
        done
        echo 'pod_names: '${pod_names[@]:0:6}
}


function get_db_ip() {
        until [[ ${#pod_ips[@]} -eq 3 ]]; do
                for i in {0..2}; do
                        local pod_name="${db_prefix}${i}.${db_prefix}${i}-svc"
                        if [[ -z ${pod_ips[i]} ]]; then
                                local pod_ip=$(ping -c1 $pod_name | grep PING | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
                                echo ${pod_name}" -> "${pod_ip}
                                sleep 3;
                                if [[ -n ${pod_ip} ]]; then
                                        pod_ips[i]="$pod_ip"
                                fi
                        fi
                done
        done
}

function get_cms_ip() {
        until [[ ${#pod_ips[@]} -eq 6 ]]; do
                for i in {0..2}; do
                        local pod_name="${cms_prefix}${i}.${cms_prefix}${i}-svc"
                        if [[ -z ${pod_ips[i+3]} ]]; then
                                local pod_ip=$(ping -c1 $pod_name | grep PING | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
                                echo ${pod_name}" -> "${pod_ip}
                                sleep 3;
                                if [[ -n ${pod_ip} ]]; then
                                        pod_ips[i+3]="$pod_ip"
                                fi
                        fi
                done
        done
}

get_db_name
get_cms_name
get_db_ip "$db_prefix"
get_cms_ip "$cms_prefix"
cp "$config_path" "$target_path"
chmod 755 "$target_path"
chown omm:omm "$target_path"
chmod 700 "$data_path"
chown omm:omm "$data_path"
sed -i "s/{POD_IP_1}/${pod_ips[0]}/g; s/{POD_IP_2}/${pod_ips[1]}/g; s/{POD_IP_3}/${pod_ips[2]}/g; s/{POD_IP_4}/${pod_ips[3]}/g; s/{POD_IP_5}/${pod_ips[4]}/g; s/{POD_IP_6}/${pod_ips[5]}/g" "$target_path"
sed -i "s/{clusterName}/${name}/g; s/{nodeNames}/${pod_names[0]},${pod_names[1]},${pod_names[2]},${pod_names[3]},${pod_names[4]},${pod_names[5]}/g; s/{name1}/${pod_names[0]}/g; s/{name2}/${pod_names[1]}/g; s/{name3}/${pod_names[2]}/g; s/{name4}/${pod_names[3]}/g; s/{name5}/${pod_names[4]}/g; s/{name6}/${pod_names[5]}/g;" "$target_path"

echo "${pod_ips[@]:0:6}"
export primaryname=${pod_names[0]}
export standbynames=${pod_names[1]},${pod_names[2]},${pod_names[3]},${pod_names[4]},${pod_names[5]}
export primaryhost=${pod_ips[0]}
export standbyhosts=${pod_ips[1]},${pod_ips[2]},${pod_ips[3]},${pod_ips[4]},${pod_ips[5]}
