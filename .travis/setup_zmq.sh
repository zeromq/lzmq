# ZMQ_VER must be "libzmq", "zeromq3" or "zeromq4"
# PLATFORM must be "linux" or "macosx"

if [ "$PLATFORM" == "linux" ]; then
  sudo apt-get remove libzmq3;
fi

if [ "$ZMQ_VER" == "libzmq" ]; then
  git clone https://github.com/zeromq/$ZMQ_VER.git ./$ZMQ_VER;
else
  git clone https://github.com/zeromq/$ZMQ_VER-x.git ./$ZMQ_VER;
fi

cd ./$ZMQ_VER
./autogen.sh
./configure
sudo make
sudo make install

cd $TRAVIS_BUILD_DIR