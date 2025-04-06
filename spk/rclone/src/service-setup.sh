#!/bin/sh

PATH="${SYNOPKG_PKGDEST}/bin:${PATH}"
GROUP="sc-rclone"

INST_ETC="/var/packages/${SYNOPKG_PKGNAME}/etc"
INST_VARIABLES="${INST_ETC}/installer-variables"
ENV_VARIABLES="${SYNOPKG_PKGVAR}/environment-variables"

# Web GUI port
WEB_PORT=5572

SVC_BACKGROUND=y
SVC_WRITE_PID=y

# function to read and export variables from a text file
# empty lines and lines starting with # are ignored
export_variables_from_file ()
{
   if [ -n "$1" -a -r "$1" ]; then
      while read -r _line; do
        if [ "$(echo ${_line} | grep -v ^[/s]*#)" != "" ]; then
           _key="$(echo ${_line} | cut --fields=1 --delimiter==)"
           _value="$(echo ${_line} | cut --fields=2- --delimiter==)"
           export "${_key}=${_value}"
        fi
      done < "$1"
   fi
}

service_prestart ()
{
   # Load custom variables
   export_variables_from_file "${ENV_VARIABLES}"

   # Create the data directory if it doesn't exist
   if [ ! -d "${SYNOPKG_PKGVAR}/data" ]; then
      mkdir -p "${SYNOPKG_PKGVAR}/data"
   fi

   # Create the config directory if it doesn't exist
   if [ ! -d "${SYNOPKG_PKGVAR}/config" ]; then
      mkdir -p "${SYNOPKG_PKGVAR}/config"
   fi

   # Start building the rclone command
   SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/rclone rcd --rc-addr=:${WEB_PORT} --rc-web-gui --rc-user=${RC_USER:-admin} --rc-pass=${RC_PASS:-admin} --rc-serve --rc-no-auth-redirect --rc-files=${SYNOPKG_PKGVAR}/data --config=${SYNOPKG_PKGVAR}/config/rclone.conf"

   # Add base URL if configured
   if [ -n "${RC_BASEURL}" ]; then
      SERVICE_COMMAND="${SERVICE_COMMAND} --rc-baseurl=${RC_BASEURL}"
   fi

   # Add no-open-browser option if enabled
   if [ "${RC_NO_OPEN_BROWSER}" = "true" ]; then
      SERVICE_COMMAND="${SERVICE_COMMAND} --rc-web-gui-no-open-browser"
   fi

   # Add metrics if enabled
   if [ "${RC_ENABLE_METRICS}" = "true" ]; then
      SERVICE_COMMAND="${SERVICE_COMMAND} --rc-enable-metrics"
   fi

   # Add read timeout if configured
   if [ -n "${RC_READ_TIMEOUT}" ]; then
      SERVICE_COMMAND="${SERVICE_COMMAND} --rc-server-read-timeout=${RC_READ_TIMEOUT}"
   fi

   # Add write timeout if configured
   if [ -n "${RC_WRITE_TIMEOUT}" ]; then
      SERVICE_COMMAND="${SERVICE_COMMAND} --rc-server-write-timeout=${RC_WRITE_TIMEOUT}"
   fi

   # Add TLS options if enabled and files exist
   if [ "${RC_ENABLE_TLS}" = "true" ]; then
      if [ -n "${RC_TLS_CERT}" ] && [ -n "${RC_TLS_KEY}" ] && [ -f "${RC_TLS_CERT}" ] && [ -f "${RC_TLS_KEY}" ]; then
         SERVICE_COMMAND="${SERVICE_COMMAND} --rc-cert=${RC_TLS_CERT} --rc-key=${RC_TLS_KEY}"

         # Add min TLS version if configured
         if [ -n "${RC_MIN_TLS_VERSION}" ]; then
            SERVICE_COMMAND="${SERVICE_COMMAND} --rc-min-tls-version=${RC_MIN_TLS_VERSION}"
         fi
      else
         # Log warning if TLS is enabled but cert/key files don't exist
         echo "Warning: TLS is enabled but certificate or key files are missing. Falling back to HTTP." >> ${SYNOPKG_PKGVAR}/rclone.log
      fi
   fi
}

service_postinst ()
{
    # Create default environment variables file if it doesn't exist
    if [ ! -f "${SYNOPKG_PKGVAR}/environment-variables" ]; then
        echo "# Custom rclone environment variables" > "${SYNOPKG_PKGVAR}/environment-variables"

        # Use wizard values if available, otherwise use defaults
        if [ -n "${wizard_username}" ]; then
            echo "RC_USER=${wizard_username}" >> "${SYNOPKG_PKGVAR}/environment-variables"
        else
            echo "RC_USER=admin" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        if [ -n "${wizard_password}" ]; then
            echo "RC_PASS=${wizard_password}" >> "${SYNOPKG_PKGVAR}/environment-variables"
        else
            echo "RC_PASS=admin" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        # Add advanced options from wizard
        if [ -n "${wizard_baseurl}" ]; then
            echo "RC_BASEURL=${wizard_baseurl}" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        if [ "${wizard_no_open_browser}" = "true" ]; then
            echo "RC_NO_OPEN_BROWSER=true" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        if [ "${wizard_enable_metrics}" = "true" ]; then
            echo "RC_ENABLE_METRICS=true" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        if [ -n "${wizard_read_timeout}" ]; then
            echo "RC_READ_TIMEOUT=${wizard_read_timeout}" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        if [ -n "${wizard_write_timeout}" ]; then
            echo "RC_WRITE_TIMEOUT=${wizard_write_timeout}" >> "${SYNOPKG_PKGVAR}/environment-variables"
        fi

        # Add TLS options if enabled
        if [ "${wizard_enable_tls}" = "true" ]; then
            echo "RC_ENABLE_TLS=true" >> "${SYNOPKG_PKGVAR}/environment-variables"

            if [ -n "${wizard_tls_cert}" ]; then
                # Replace ${SYNOPKG_PKGVAR} with actual path
                cert_path=$(echo "${wizard_tls_cert}" | sed "s|\${SYNOPKG_PKGVAR}|${SYNOPKG_PKGVAR}|g")
                echo "RC_TLS_CERT=${cert_path}" >> "${SYNOPKG_PKGVAR}/environment-variables"
            fi

            if [ -n "${wizard_tls_key}" ]; then
                # Replace ${SYNOPKG_PKGVAR} with actual path
                key_path=$(echo "${wizard_tls_key}" | sed "s|\${SYNOPKG_PKGVAR}|${SYNOPKG_PKGVAR}|g")
                echo "RC_TLS_KEY=${key_path}" >> "${SYNOPKG_PKGVAR}/environment-variables"
            fi

            if [ -n "${wizard_min_tls_version}" ]; then
                echo "RC_MIN_TLS_VERSION=${wizard_min_tls_version}" >> "${SYNOPKG_PKGVAR}/environment-variables"
            fi
        fi
    fi

    # Store wizard variables for future reference
    if [ -n "${wizard_username}" ] || [ -n "${wizard_password}" ]; then
        mkdir -p "${INST_ETC}"
        if [ -n "${wizard_username}" ]; then
            echo "wizard_username=${wizard_username}" > "${INST_VARIABLES}"
        fi
        if [ -n "${wizard_password}" ]; then
            echo "wizard_password=${wizard_password}" >> "${INST_VARIABLES}"
        fi
    fi

    # Create a README file with usage instructions
    cat > "${SYNOPKG_PKGVAR}/README.txt" << EOF
Rclone Web GUI Usage Instructions
================================

Accessing the Web GUI:
---------------------
The rclone web GUI is accessible at: http://your-synology-ip:${WEB_PORT}
Default credentials: ${RC_USER:-admin} / ${RC_PASS:-admin}

Configuration:
-------------
1. The main rclone configuration file is located at: ${SYNOPKG_PKGVAR}/config/rclone.conf
2. Environment variables and settings: ${SYNOPKG_PKGVAR}/environment-variables

TLS/HTTPS Setup:
--------------
If you enabled HTTPS, place your certificate and key files at:
- Certificate: ${RC_TLS_CERT:-${SYNOPKG_PKGVAR}/config/cert.pem}
- Private Key: ${RC_TLS_KEY:-${SYNOPKG_PKGVAR}/config/key.pem}

For more information, visit: https://rclone.org/gui/
EOF
}

service_postupgrade ()
{
    # Ensure data directory exists
    if [ ! -d "${SYNOPKG_PKGVAR}/data" ]; then
      mkdir -p "${SYNOPKG_PKGVAR}/data"
    fi

    # Ensure config directory exists
    if [ ! -d "${SYNOPKG_PKGVAR}/config" ]; then
      mkdir -p "${SYNOPKG_PKGVAR}/config"
    fi

    # Update README file
    if [ -f "${SYNOPKG_PKGVAR}/environment-variables" ]; then
        # Source the environment variables to get current settings
        export_variables_from_file "${SYNOPKG_PKGVAR}/environment-variables"

        # Create updated README
        cat > "${SYNOPKG_PKGVAR}/README.txt" << EOF
Rclone Web GUI Usage Instructions
================================

Accessing the Web GUI:
---------------------
The rclone web GUI is accessible at: http://your-synology-ip:${WEB_PORT}
Default credentials: ${RC_USER:-admin} / ${RC_PASS:-admin}

Configuration:
-------------
1. The main rclone configuration file is located at: ${SYNOPKG_PKGVAR}/config/rclone.conf
2. Environment variables and settings: ${SYNOPKG_PKGVAR}/environment-variables

TLS/HTTPS Setup:
--------------
If you enabled HTTPS, place your certificate and key files at:
- Certificate: ${RC_TLS_CERT:-${SYNOPKG_PKGVAR}/config/cert.pem}
- Private Key: ${RC_TLS_KEY:-${SYNOPKG_PKGVAR}/config/key.pem}

For more information, visit: https://rclone.org/gui/
EOF
    fi
}
