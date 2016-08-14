export REMOTE_user    ?=
export REMOTE_machine ?=

### Functions
define REMOTE_mkRemoteCall = # exe, remote_root
  $(MAKE_utilsDir)/remote.sh '$(1)' '$(2)'
endef
