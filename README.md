# PostgreSQL with PgTune and PgBouncer installation

Intended for an offline setting up, tested on Debian 11. `acl` and<br>
`psycopg2-binary` should be installed on remote machines. All components,<br>
except PgTune, are compiled from source within Docker<br>

## 1 How to run

On a machine with Internet link and Docker commence with Bash scripts<br>
from `scripts` directory in the following order:<br>
- `bash postgresql-compile.sh`<br>
- `bash pgbouncer-compile.sh`<br>
That compiles binaries and places them into appropriate folders<br>
in `ansible-playbooks` directory as tarballs. Then a playbook can be started
