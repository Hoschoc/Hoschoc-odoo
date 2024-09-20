#!/bin/bash

# Define a header for all echo statements
HEADER="[entrypoint.sh]"
echo "$HEADER Running with PID $$ at $(date)"

# Define the path to odoo-bin
ODOO_BIN="/usr/src/app/odoo/odoo-bin"

# Function to combine general and sensitive config files into a single config If the environment variable CONF_OVERRIDE_WITH_SECURE is set to "true", it merges the content of the general config file (/etc/odoo/odoo_general.conf) and the sensitive config file (/etc/odoo/odoo_sensitive.conf) into a single file (/etc/odoo/odoo.conf). This merged file will then be used by Odoo during startup.
#
# If CONF_OVERRIDE_WITH_SECURE is not set or is set to "false", the function skips the merge process and continues using the default configuration that was either copied into the container during the Dockerfile build process (typically /etc/odoo/odoo.conf) or mounted into the container via docker-compose or similar methods. This ensures that sensitive configuration data is only included when explicitly enabled, and the system falls back to a default configuration if no override is needed.
function combine_general_and_sensitive_configs() {
    if [ "$CONF_OVERRIDE_WITH_SECURE" == "true" ]; then
        echo "$HEADER CONF_OVERRIDE_WITH_SECURE is set to 'true'. Proceeding with config merge..."

        # Verify both general and sensitive config files exist before merging
        if [ -f /etc/odoo/odoo_general.conf ] && [ -f /etc/odoo/odoo_sensitive.conf ]; then
            echo "$HEADER Found both general and sensitive config files."
            cat /etc/odoo/odoo_general.conf /etc/odoo/odoo_sensitive.conf > /etc/odoo/odoo.conf
            echo "$HEADER Config files merged into /etc/odoo/odoo.conf"
        else
            echo "$HEADER Error: One or both of the config files are missing. Merge aborted."
            exit 1
        fi

    # Handle invalid or missing values for CONF_OVERRIDE_WITH_SECURE
    elif [ -z "$CONF_OVERRIDE_WITH_SECURE" ]; then
        echo "$HEADER CONF_OVERRIDE_WITH_SECURE is not set. Using default config."
    else
        echo "$HEADER Warning: CONF_OVERRIDE_WITH_SECURE is set to an invalid value. Using default config."
    fi
}


# Call the function at the start
combine_general_and_sensitive_configs


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
            exec $ODOO_BIN "$@"
        else
            # Wait for PostgreSQL to be ready using the updated check-db-status.py script
            echo "$HEADER Checking PostgreSQL readiness and database initialization..."
            check-db-status.py ${DB_ARGS[@]} --timeout=30
            result=$?
            if [ $result -eq 2 ]; then
                echo "$HEADER Database not initialized. Running initialization..."
                exec $ODOO_BIN -i base --stop-after-init "${DB_ARGS[@]}"
            fi
            # Run Odoo with the remaining arguments and database parameters
            echo "$HEADER Database is initialized. Starting Odoo..."
            exec $ODOO_BIN "$@" "${DB_ARGS[@]}"
        fi
        ;;
    *)
        # For any other command, execute it directly.
        echo "$HEADER Executing custom command: $@"
        exec "$@"
esac

exit 1

