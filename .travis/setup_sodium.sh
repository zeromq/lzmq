# PLATFORM must be "linux" or "macosx"

set -eufo pipefail

git clone git://github.com/jedisct1/libsodium.git
cd libsodium
./autogen.sh
./configure && make check
sudo make install
sudo ldconfig

cd $TRAVIS_BUILD_DIR