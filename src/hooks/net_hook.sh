
##
# Network configuration hook.
# Please note that you have to use either
# env_execChroot or env_execChrootH (both
# defined in env.conf) to modify the configuration
# in the already bootstrapped environment!
##
net_hook(){
  # There cannot be a systemclt config statement because
  # the appropriate daemon isn't running yet!
  :
}
