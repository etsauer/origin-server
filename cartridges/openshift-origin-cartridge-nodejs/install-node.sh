#!/bin/bash

NODE_VERSION="$1"
NODE_TARBALL="http://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz"
NODE_INSTALL_DIR='/opt/nodejs'
OPENSHIFT_PATH_ELEMENT='/etc/openshift/env/PATH'
PROFILE_D_NODEJS='/etc/profile.d/node.sh'

rm -f /tmp/node-*.tar.gz
cd /tmp && { curl -O $NODE_TARBALL ; cd -; }

pushd $NODE_INSTALL_DIR
tar zxf /tmp/node-*.tar.gz
popd

NODE_HOME=$(find $NODE_INSTALL_DIR -name "node-v${NODE_VERSION}*")
echo "export PATH=\"${NODE_HOME}/bin:\$PATH\"" > ${PROFILE_D_NODEJS}

if [ $(grep -c "$NODE_INSTALL_DIR" $OPENSHIFT_PATH_ELEMENT) -lt 1 ]; then
  echo "${NODE_HOME}/bin:$(cat ${OPENSHIFT_PATH_ELEMENT})" > $OPENSHIFT_PATH_ELEMENT
fi

# Check that the system properly recognizes the node install
if [ "$(node -v)" != "v${NODE_VERSION}" ] || [ "$(which npm)" != "${NODE_HOME}/bin/npm" ]; then
  echo "Wrong node version installed. Something in the PATH settings was likely not set up correctly.
Check the following files for misinformation:
  - ${OPENSHIFT_PATH_ELEMENT}
  - ${PROFILE_D_NODEJS}"
  exit 1
fi

# Install Modules
modulefile=$(find /var/lib/openshift/.cartridge_repository/redhat-nodejs/ -name npm_global_module_list | tail -n1)
modules=$(grep -v '#' $modulefile | grep -v '^$')

for mod in $modules; do
  echo "Installing ${mod}..."
  npm install -g $mod
done
