# PostgreSQL with Patroni  

Intended for an offline setting up, tested on Rocky Linux 8. All components  
are compiled from source within Docker.  

## 1 Requirements  

- at least 2 Rocky Linux 8 VMs with interconnectivity  
- 3 hard drives on each VM  
- etcd already set up and running  

## 2 How to run  

On a machine with Internet link and Docker, commence with a Bash script  
`compile_components.sh`. It compiles binaries and places them into appropriate  
folders in `ansible-playbooks` one as tarballs. Then a playbook can be  
executed with  
`ansible-playbook \  
   -e database_name=test \  
   -e data_drive=/dev/sdb \  
   -e etcd_url=etcd_server_name \  
   -e log_drive=/dev/sdc \  
   -e wal_drive=/dev/sdd \  
   -i inventories/dev.yml \  
   playbooks/install.yml`.
