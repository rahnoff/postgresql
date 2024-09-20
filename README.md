# PostgreSQL with Patroni  

Intended for an offline setting up, tested on Rocky Linux 8. All components  
are compiled from source within Docker.  

## 1 Requirements  

- at least 2 Rocky Linux 8 VMs with interconnectivity  
- 3 unpartitioned hard drives on each VM  
- etcd already set up and running  

## 2 How to run  

On a machine with Internet link and Docker, commence with a Bash script  
`compile_components.sh`. It compiles binaries and places them into appropriate  
folders in `ansible-playbooks` as tarballs. Then a playbook with 4 CPUs and
4GB of RAM VMs can be executed with `ansible-playbook -e checkpoint_completion_target='0.9' -e default_statistics_target=100 -e effective_cache_size=3GB -e effective_io_concurrency=200 -e huge_pages=off -e maintenance_work_mem=256MB -e max_connections=200 -e max_parallel_maintenance_workers=2 -e max_parallel_workers=4 -e max_parallel_workers_per_gather=2 -e max_worker_processes=4 -e max_wal_size=4GB -e min_wal_size=1GB -e random_page_cost='1.1' -e shared_buffers=1GB -e wal_buffers=16MB -e work_mem=2621kB -e database_name=test -e data_drive=/dev/sdb -e etcd_url=linux-mint -e log_drive=/dev/sdc -e wal_drive=/dev/sdd -i inventories/dev.yml playbooks/install.yml`.
