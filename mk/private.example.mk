##
# This file contains custom variables definition to override
# other values used in the different makefiles
##

# Your quay user as it is used for setting DOCKER_IMAGE_BASE
# Be sure the robot account has only the necessary permissions
export QUAY_USER := myuser+robotaccountname
export QUAY_TOKEN := TOKEN

# https://access.redhat.com/RegistryAuthentication
# https://access.redhat.com/RegistryAuthentication#creating-registry-service-accounts-6
# https://access.redhat.com/terms-based-registry/#/token/YOUR_TOKEN
export RH_REGISTRY_USER := 2819273|accountname
export RH_REGISTRY_TOKEN := TOKEN

