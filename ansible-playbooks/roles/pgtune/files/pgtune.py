import argparse

DB_TYPE_DESKTOP = "desktop"
DB_TYPE_DW = "dw"
DB_TYPE_MIXED = "mixed"
DB_TYPE_OLTP = "oltp"
DB_TYPE_WEB = "web"
DEFAULT_DB_VERSION = "15"
HARD_DRIVE_HDD = "hdd"
HARD_DRIVE_SAN = "san"
HARD_DRIVE_SSD = "ssd"
SIZE_UNIT_GB = "GB"
SIZE_UNIT_MB = "MB"

checkpoint_completion_target: float = 0.9
default_statistics_target: int = 0
effective_cache_size: int = 0
effective_io_concurrency: int = 0
final_connection_num: int = 0
huge_pages: str = ""
maintenance_work_mem: int = 0
max_wal_size: int = 0
min_wal_size: int = 0
random_page_cost: float = 0.0
shared_buffers: int = 0
wal_buffers_value: int = 0
work_mem_base: int = 0
work_mem_result: int = 0
work_mem_value: int = 0

def byte_size(size: int) -> str:
    result: int = 0
    if size % 1024 != 0 or size < 1024:
        return f"{size}KB"
    result = size // 1024
    if result % 1024 != 0 or result < 1024:
        return f"{result}MB"
    result = result // 1024
    if result % 1024 != 0 or result < 1024:
        return f"{result}GB"
    return str(size)

def pg_tune():
    parser = argparse.ArgumentParser()
    parser.add_argument("--connections", type=int, default=0, help="Maximum number of PostgreSQL client connections")
    parser.add_argument("--cpus", type=int, default=0, help="Number of CPUs, which PostgreSQL can leverage\nCPUs = threads per core * cores per socket * sockets")
    parser.add_argument("--db-type", type=str, default=DB_TYPE_WEB, help="What type of application PostgreSQL is installed for")
    parser.add_argument("--db-version", type=str, default=DEFAULT_DB_VERSION, help="PostgreSQL version - can be found out via 'SELECT version();'")
    parser.add_argument("--hd-type", type=str, default=HARD_DRIVE_SSD, help="Type of data storage device")
    parser.add_argument("--total-memory", type=int, default=0, help="How much memory can PostgreSQL take advantage of")
    parser.add_argument("--total-memory-unit", type=str, default=SIZE_UNIT_GB, help="Memory unit")
    args = parser.parse_args()
    
    SIZE_UNIT_MAP = {
        "KB": 1024,
        "MB": 1048576,
        "GB": 1073741824,
        "TB": 1099511627776
    }

    total_memory_bt = args.total_memory * SIZE_UNIT_MAP[args.total_memory_unit]

    total_memory_kb = total_memory_bt / SIZE_UNIT_MAP["KB"]

    # connections
    if args.connections > 0:
        print("# Connection num:", args.connections)
    
    # default statistics target
    DEFAULT_STATISTICS_TARGET_MAP = {
        DB_TYPE_DESKTOP: 100,
        DB_TYPE_DW: 500,
        DB_TYPE_MIXED: 100,
        DB_TYPE_OLTP: 100,
        DB_TYPE_WEB: 100
    }
    default_statistics_target = DEFAULT_STATISTICS_TARGET_MAP[args.db_type]

    # effective cache size
    EFFECTIVE_CACHE_SIZE_MAP = {
        DB_TYPE_DESKTOP: total_memory_kb // 4,
        DB_TYPE_DW: (total_memory_kb * 3) // 4,
        DB_TYPE_MIXED: (total_memory_kb * 3) // 4,
        DB_TYPE_OLTP: (total_memory_kb * 3) // 4,
        DB_TYPE_WEB: (total_memory_kb * 3) // 4
    }
    effective_cache_size = EFFECTIVE_CACHE_SIZE_MAP[args.db_type]

    # effective io concurrency
    EFFECTIVE_IO_CONCURRENCY = {
        HARD_DRIVE_HDD: 2,
        HARD_DRIVE_SAN: 300,
        HARD_DRIVE_SSD: 200
    }
    effective_io_concurrency = EFFECTIVE_IO_CONCURRENCY[args.hd_type]
    
    # connections
    if args.connections < 1:
        CONNECTION_NUM_MAP = {
            DB_TYPE_DESKTOP: 20,
            DB_TYPE_DW: 40,
            DB_TYPE_MIXED: 100,
            DB_TYPE_OLTP: 300,
            DB_TYPE_WEB: 200
        }
        final_connection_num = CONNECTION_NUM_MAP[args.db_type]
    else:
        final_connection_num = args.connections

    # huge pages
    if total_memory_kb >= 33554432:
        huge_pages = "try"
    else:
        huge_pages = "off"

    # maintenance work memory
    MAINTENANCE_WORK_MEM_MAP = {
        DB_TYPE_DESKTOP: total_memory_kb / 16,
        DB_TYPE_DW: total_memory_kb / 8,
        DB_TYPE_MIXED: total_memory_kb / 16,
        DB_TYPE_OLTP: total_memory_kb / 16,
        DB_TYPE_WEB: total_memory_kb / 16
    }
    maintenance_work_mem = MAINTENANCE_WORK_MEM_MAP[args.db_type]
    # Cap maintenance RAM at 2 GB on servers with lots of memory
    memory_limit = (SIZE_UNIT_MAP["GB"] * 2) / SIZE_UNIT_MAP["KB"]
    if maintenance_work_mem > memory_limit:
        maintenance_work_mem = memory_limit

    # max wal size
    MAX_WAL_SIZE_MAP = {
        DB_TYPE_DESKTOP: (SIZE_UNIT_MAP["MB"] * 2048) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_DW: (SIZE_UNIT_MAP["MB"] * 16384) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_MIXED: (SIZE_UNIT_MAP["MB"] * 4096) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_OLTP: (SIZE_UNIT_MAP["MB"] * 8192) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_WEB: (SIZE_UNIT_MAP["MB"] * 4096) / SIZE_UNIT_MAP["KB"]
    }
    max_wal_size = MAX_WAL_SIZE_MAP[args.db_type]

    # min wal size
    MIN_WAL_SIZE_MAP = {
        DB_TYPE_DESKTOP: (SIZE_UNIT_MAP["MB"] * 100) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_DW: (SIZE_UNIT_MAP["MB"] * 4096) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_MIXED: (SIZE_UNIT_MAP["MB"] * 1024) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_OLTP: (SIZE_UNIT_MAP["MB"] * 2048) / SIZE_UNIT_MAP["KB"],
        DB_TYPE_WEB: (SIZE_UNIT_MAP["MB"] * 1024) / SIZE_UNIT_MAP["KB"]
    }
    min_wal_size = MIN_WAL_SIZE_MAP[args.db_type]

    # random page cost
    RANDOM_PAGE_COST_MAP = {
        HARD_DRIVE_HDD: 4,
        HARD_DRIVE_SAN: 1.1,
        HARD_DRIVE_SSD: 1.1
    }
    random_page_cost = RANDOM_PAGE_COST_MAP[args.hd_type]

    # shared buffers
    SHARED_BUFFERS_MAP = {
        DB_TYPE_DESKTOP: total_memory_kb / 16,
        DB_TYPE_DW: total_memory_kb / 4,
        DB_TYPE_MIXED: total_memory_kb / 4,
        DB_TYPE_OLTP: total_memory_kb / 4,
        DB_TYPE_WEB: total_memory_kb / 4
    }
    shared_buffers = SHARED_BUFFERS_MAP[args.db_type]

    # Follow auto-tuning guideline for 'wal_buffers' added in 9.1, where it's
	# set to 3% of 'shared_buffers' up to a maximum of 16 MB
    wal_buffers_value = (shared_buffers * 3) / 100
    max_wal_buffer = (SIZE_UNIT_MAP["MB"] * 16) / SIZE_UNIT_MAP["KB"]
    if wal_buffers_value > max_wal_buffer:
        wal_buffers_value = max_wal_buffer
    wal_buffer_near_value = (SIZE_UNIT_MAP["MB"] * 14) / SIZE_UNIT_MAP["KB"]
    if wal_buffers_value > wal_buffer_near_value and wal_buffers_value < max_wal_buffer:
        wal_buffers_value = max_wal_buffer
    # If less than 32 KB then set it to minimum
    if wal_buffers_value < 32:
        wal_buffers_value = 32

    # 'work_mem' is assigned any time a query calls for a sort, or a hash,
	# or any other structure that needs a space allocation, which can happen
	# multiple times per query. So you're better off assuming
	# max_connections * 2 or max_connections * 3 is the amount of RAM that
	# will actually be leveraged. At the very least, you need to subtract
	# 'shared_buffers' from the amount you distribute to connections
	# in 'work_mem'. The other stuff to consider is that there's no reason
	# to run on the edge of available memory. If you carry out that, there's
	# a high risk the out-of-memory killer will come along and start killing
	# PostgreSQL backends. Always leave a buffer of some kind in case of
	# spikes in memory usage. So your maximum amount of memory available
	# in 'work_mem' should be
	# ((RAM - shared_buffers) / (max_connections * 3)) /
	# max_parallel_workers_per_gather
    if args.cpus >= 2:
        work_mem_base = args.cpus / 2
    else:
        work_mem_base = 1

    work_mem_value = ((total_memory_kb - shared_buffers) /
                      (final_connection_num * 3)) / work_mem_base
    WORK_MEM_MAP = {
        DB_TYPE_DESKTOP: work_mem_value / 6,
        DB_TYPE_DW: work_mem_value / 2,
        DB_TYPE_MIXED: work_mem_value / 2,
        DB_TYPE_OLTP: work_mem_value,
        DB_TYPE_WEB: work_mem_value
    }
    work_mem_result = WORK_MEM_MAP[args.db_type]
    
    if work_mem_result < 64:
        work_mem_result = 64

    # Configuration
    print("# CPUs num:", args.cpus)
    print("# Data Storage:", args.hd_type)
    print("# DB Type:", args.db_type)
    print("# DB Version:", args.db_version)
    print("# OS Type:", "Linux")
    print("# Total Memory (RAM):", args.total_memory, args.total_memory_unit)
    print("")
    print("checkpoint_completion_target =", checkpoint_completion_target)
    print("default_statistics_target =", default_statistics_target)
    print("effective_cache_size =", byte_size(effective_cache_size))
    print("effective_io_concurrency =", effective_io_concurrency)
    print("huge_pages =", huge_pages)
    print("maintenance_work_mem =", byte_size(maintenance_work_mem))
    print("max_connections =", final_connection_num)
    print("max_parallel_workers =", args.cpus)
    print("max_wal_size =", byte_size(max_wal_size))
    print("min_wal_size =", byte_size(min_wal_size))
    print("random_page_cost =", random_page_cost)
    print("shared_buffers =", byte_size(shared_buffers))
    print("wal_buffers =", byte_size(wal_buffers_value))
    print("work_mem =", byte_size(work_mem_result))

def main():
    pg_tune()

if __name__ == '__main__':
    main()
