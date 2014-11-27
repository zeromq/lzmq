
source .travis/platform.sh

echo "==============================="
echo " Platform : $PLATFORM          "
echo "==============================="
echo 

if [ "$PLATFORM" == "linux" ]; then
  sudo apt-get remove libzmq3;
fi

ZMQ_BASE_DIR="libzmq"

ZMQ_REPO="libzmq"

if   [ "$ZMQ_VER" == "3.2" ]; then
  ZMQ_REPO="zeromq3-x";
elif [ "$ZMQ_VER" == "4.0" ]; then
  ZMQ_REPO="zeromq4-x";
elif [ "$ZMQ_VER" == "4.1" ]; then
  ZMQ_REPO="zeromq4-1";
elif [ "$ZMQ_VER" == "4.2" ]; then
  ZMQ_REPO="libzmq";
elif [ "$ZMQ_VER" == "scm" ]; then
  ZMQ_REPO="libzmq";
else
  ZMQ_REPO="libzmq";
fi

git clone https://github.com/zeromq/$ZMQ_REPO.git ./$ZMQ_BASE_DIR

cd ./$ZMQ_BASE_DIR

./autogen.sh
./configure
sudo make
sudo make install

cd $TRAVIS_BUILD_DIR