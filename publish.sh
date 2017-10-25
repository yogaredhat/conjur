#!/bin/bash -e

export DEBUG=true
export GLI_DEBUG=true

COMPONENT=${1:-conjur}

debify publish --component $COMPONENT $(cat VERSION_APPLIANCE) conjur
