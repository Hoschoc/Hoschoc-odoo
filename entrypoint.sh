#!/bin/bash

# Define a header for all echo statements
HEADER="[entrypoint.sh]"

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
echo "$HEADER Setting up database connection parameters..."
: ${DB_HOST:=${POSTGRES_HOST:='db'}} # Sets DB_HOST to its current value, or to POSTGRES_HOST if available, or defaults to 'db'.
: ${DB_PORT:=${POSTGRES_PORT:=5432}}
: ${DB_USER:=${POSTGRES_USER:='odoo'}}
: ${DB_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}
: ${DB_NAME:=${POSTGRES_DB:='odoo'}}

DB_ARGS=()
# Adds the parameter (prefixed with "--") and its value to DB_ARGS, using config file value if available.
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$DB_HOST"
check_config "db_port" "$DB_PORT"
check_config "db_user" "$DB_USER"
check_config "db_password" "$DB_PASSWORD"
check_config "database" "$DB_NAME"


# This section of the script handles different input arguments: 
# if the first argument is "--" or "odoo", it either scaffolds a new module or waits for PostgreSQL to be ready before running Odoo with appropriate database parameters; 
# if the first argument is a flag, it similarly waits for PostgreSQL before executing Odoo with the provided flags; 
# for any other input, it executes the command directly.
case "$1" in
    odoo) # If the first argument is "odoo".
        shift # removes $1.

        # Check if the next argument is "scaffold". usage: odoo scaffold my_module /path/to/your/addons
        if [[ "$1" == "scaffold" ]] ; then
            echo "$HEADER Running scaffold command..."
            # If it is "scaffold", execute the odoo command with the remaining arguments.
            exec odoo "$@"
        else
            # Wait for PostgreSQL to be ready using the updated check-db-status.py script
            echo "$HEADER Checking PostgreSQL readiness and database initialization..."
            check-db-status.py ${DB_ARGS[@]} --timeout=30
            result=$?
            if [ $result -eq 2 ]; then
                echo "$HEADER Database not initialized. Running initialization..."
                exec odoo -i base --stop-after-init "${DB_ARGS[@]}"
            fi
            # Run Odoo with the remaining arguments and database parameters
            echo "$HEADER Database is initialized. Starting Odoo..."
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    *)
        # For any other command, execute it directly.
        echo "$HEADER Executing custom command: $@"
        exec "$@"
esac

exit 1

