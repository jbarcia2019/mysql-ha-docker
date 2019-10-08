#!/bin/bash
set -eo pipefail
shopt -s nullglob

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [ "$1" = 'pt-heartbeat' ]; then
  file_env 'PT_DATABASE'
  if [ -z "$PT_DATABASE" ]; then
    echo "you have to specify a DB!"
    exit 1
  fi
  file_env 'PT_MASTER'
  if [ -z "$PT_MASTER" ]; then
    echo "you have to specify a MySQL Server!"
    exit 1
  fi
	file_env 'PT_USER'
  if [ -z "$PT_USER" ]; then
    echo "you have to specify a user!"
    exit 1
  fi
	file_env 'PT_PASSWORD'
  if [ -z "$PT_PASSWORD" ]; then
    echo "you have to specify a password!"
    exit 1
  fi

  echo "Waiting MySQL Server..."

  while ! nc -z $PT_MASTER 3306; do
    sleep 10.0
  done

  pt-heartbeat -D $PT_DATABASE --update -h $PT_MASTER --user $PT_USER --password $PT_PASSWORD
  while [ $? -ne 0 ]; do
    pt-heartbeat -D $PT_DATABASE --update -h $PT_MASTER --user $PT_USER --password $PT_PASSWORD
  done

fi

exec "$@"
