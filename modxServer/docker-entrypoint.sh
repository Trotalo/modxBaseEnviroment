#!/bin/bash
set -e

TMP_STORE=/tmp/modx
HT_FILENAME=$TMP_STORE/siteConfig/.htaccess
MODX_EXTRAS=/var/www/html/_data/modxExtras

echo "Starting Modx container startup configuration"

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ -n "$MYSQL_PORT_3306_TCP" ]; then
		if [ -z "$MODX_DB_HOST" ]; then
			MODX_DB_HOST='mysql'
		else
			echo >&2 'warning: both MODX_DB_HOST and MYSQL_PORT_3306_TCP found'
			echo >&2 "  Connecting to MODX_DB_HOST ($MODX_DB_HOST)"
			echo >&2 '  instead of the linked mysql container'
		fi
	fi

	if [ -z "$MODX_DB_HOST" ]; then
		echo >&2 'error: missing MODX_DB_HOST and MYSQL_PORT_3306_TCP environment variables'
		echo >&2 '  Did you forget to --link some_mysql_container:mysql or set an external db'
		echo >&2 '  with -e MODX_DB_HOST=hostname:port?'
		exit 1
	fi

	# if we're linked to MySQL and thus have credentials already, let's use them
	: ${MODX_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}
	if [ "$MODX_DB_USER" = 'root' ]; then
		: ${MODX_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
	fi
	: ${MODX_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
	: ${MODX_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-modx}}

	if [ -z "$MODX_DB_PASSWORD" ]; then
		echo >&2 'error: missing required MODX_DB_PASSWORD environment variable'
		echo >&2 '  Did you forget to -e MODX_DB_PASSWORD=... ?'
		echo >&2
		echo >&2 '  (Also of interest might be MODX_DB_USER and MODX_DB_NAME.)'
		exit 1
	fi
	echo >&2 "Creating connection!"

	TERM=dumb php -- "$MODX_DB_HOST" "$MODX_DB_USER" "$MODX_DB_PASSWORD" "$MODX_DB_NAME" <<'EOPHP'
<?php
$stderr = fopen('php://stderr', 'w');
list($host, $port) = explode(':', $argv[1], 2);

$maxTries = 50;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', (int)$port);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(10);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '` ' .
	'DEFAULT CHARACTER SET = \'utf8\' DEFAULT COLLATE \'utf8_general_ci\'')) {

	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
EOPHP

  if ! [ -e index.php -a -e $MODX_CORE_LOCATION/config/config.inc.php ]; then
		echo >&2 "MODX not found in $(pwd) - copying now..."

		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi

		tar cf - --one-file-system -C /usr/src/modx . | tar xf -

    echo >&2 "Complete! MODX has been successfully copied to $(pwd)"

    #Now we move the core to the configured location
    echo >&2 "Moving core to $MODX_CORE_LOCATION"
    mv /var/www/html/core  $MODX_CORE_LOCATION

		: ${MODX_ADMIN_USER:='admin'}
		: ${MODX_ADMIN_PASSWORD:='admin'}

		cat > setup/config.xml <<EOF
<modx>
	<database_type>mysql</database_type>
	<database_server>$MODX_DB_HOST</database_server>
	<database>$MODX_DB_NAME</database>
	<database_user>$MODX_DB_USER</database_user>
	<database_password>$MODX_DB_PASSWORD</database_password>
	<database_connection_charset>utf8</database_connection_charset>
	<database_charset>utf8</database_charset>
	<database_collation>utf8_general_ci</database_collation>
	<table_prefix>$MODX_TABLE_PREFIX</table_prefix>
	<https_port>443</https_port>
	<http_host>localhost</http_host>
	<cache_disabled>0</cache_disabled>

	<inplace>1</inplace>
	<unpacked>0</unpacked>
	<language>en</language>

	<cmsadmin>$MODX_ADMIN_USER</cmsadmin>
	<cmspassword>$MODX_ADMIN_PASSWORD</cmspassword>
	<cmsadminemail>$MODX_ADMIN_EMAIL</cmsadminemail>

	<core_path>$MODX_CORE_LOCATION</core_path>
	<context_mgr_path>/var/www/html/manager/</context_mgr_path>
	<context_mgr_url>/manager/</context_mgr_url>
	<context_connectors_path>/var/www/html/connectors/</context_connectors_path>
	<context_connectors_url>/connectors/</context_connectors_url>
	<context_web_path>/var/www/html/</context_web_path>
	<context_web_url>/</context_web_url>

	<remove_setup_directory>1</remove_setup_directory>
</modx>
EOF
		chown www-data:www-data setup/config.xml
    echo >&2 "Starting modx installation, be patient, this can take some time"
    sudo -u www-data php setup/index.php --installmode=new --core_path=$MODX_CORE_LOCATION/
    echo >&2 "We copy the ht access file"
    mv /var/www/html/.htaccess /var/www/html/.htaccess.base
    cp -rfp $HT_FILENAME /var/www/html/
    chown www-data:www-data $HT_FILENAME

    echo >&2 "Now we configure the Gitify command "
    # mkdir $TMP_STORE
    git clone https://github.com/modmore/Gitify.git $TMP_STORE/Gitify
    cd $TMP_STORE/Gitify
    composer install --no-dev

    chmod +x bin/gitify
    cd /usr/bin/
    ln -s /tmp/modx/Gitify/bin/gitify Gitify
    cd /var/www/html/
    # We install the required plugins
    if [ -e .gitify ]; then
      Gitify package:install --all
      #Finally we call the database creation script
      cd /var/www/html/modxMonster/modelConfig/
      for f in *.gen; do
        mv -- "$f" "${f%.xml.gen}.xml"
      done
    fi


  # fi
  else
    echo >&2 "Modx its installed, checking for Gitify installation"
    if ! [ -e $TMP_STORE/Gitify ]; then
      echo >&2 "Installing Gitify command......"
      # mkdir $TMP_STORE
      git clone https://github.com/modmore/Gitify.git $TMP_STORE/Gitify
      cd $TMP_STORE/Gitify
      if (composer install --no-dev) then
        echo >&2 "Worked at first"
      else
        echo >&2 "updating file and reinstalling"
        mv $TMP_STORE/Gitify/vendor/kbjr/git.php/Git.php $TMP_STORE/Gitify/vendor/kbjr/git.php/git.php
        composer install --no-dev
      fi
      chmod +x bin/gitify
      cd /usr/bin/
      ln -s /tmp/modx/Gitify/bin/gitify Gitify
    fi
  fi
fi

exec "$@"
