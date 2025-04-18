# Copyright 2024 6WIND S.A.

# This script is called by kubernetes from inside the VSR to advertise
# the readiness status of the VSR.
#
# For this use-case, the VSR is considered ready if the fast path is
# not enabled in configuration, or if:
# - the fast path is started
# - the number of master vrrp instances in state is the same than in config
# - the number of backup vrrp instances in state is the same than in config

echo check vm ready

# check systemd status
ret=$(systemctl is-system-running)
if [ "$ret" != "running" ] && [ "$ret" != "degraded" ]; then
	echo not ready, systemd status is $ret
	exit 1
fi

# check if fp is enabled in config
{
    echo netconf connect
    echo show config running fullpath system fast-path enabled
} | nc-cli -f - | grep -q true
if [ $? != 0 ]; then
  echo ready, fp disabled in config
  exit 0
fi

# check if fp is enabled in state
{
    echo netconf connect
    echo show state fullpath system fast-path enabled
} | nc-cli -f - | grep -q true
if [ $? != 0 ]; then
  echo not ready, fp disabled in state
  exit 1
fi

# fp is enabled in state

CONF_N_MASTER=$(
  {
    echo netconf connect
    echo "show config running fullpath | match 'vrrp ike_control_.* priority 200' count"
  } | nc-cli -f -
)
STATE_N_MASTER=$(
  {
    echo netconf connect
    echo "show state fullpath ha | match 'state master' count"
  } | nc-cli -f -
)
[ -z "$STATE_N_MASTER" ] && STATE_N_MASTER=0

echo conf_n_master="$CONF_N_MASTER" state_n_master="$STATE_N_MASTER"

if [ "$CONF_N_MASTER" != "$STATE_N_MASTER" ]; then
  echo not ready, conf_n_master/"$CONF_N_MASTER" != state_n_master/"$STATE_N_MASTER"
  exit 1
fi

CONF_N_BACKUP=$(
  {
    echo netconf connect
    echo "show config running fullpath | match 'vrrp ike_control_.* priority 100' count"
  } | nc-cli -f -
)
STATE_N_BACKUP=$(
  {
    echo netconf connect
    echo "show state fullpath ha | match 'state backup' count"
  } | nc-cli -f -
)
[ -z "$STATE_N_BACKUP" ] && STATE_N_BACKUP=0

echo conf_n_backup="$CONF_N_BACKUP" state_n_backup="$STATE_N_BACKUP"

if [ "$CONF_N_BACKUP" != "$STATE_N_BACKUP" ]; then
  echo not ready, conf_n_backup/"$CONF_N_BACKUP" != state_n_backup/"$STATE_N_BACKUP"
  exit 1
fi

echo ready
exit 0
