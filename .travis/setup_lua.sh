#! /bin/bash

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.1", "lua5.2" or "luajit".
# PLATFORM must be "linux" or "macosx".

LUAJIT_BASE="LuaJIT-2.0.3"

if [ -z "$PLATFORM" ]; then
  export PLATFORM=$TRAVIS_OS_NAME;
fi

if [ "$PLATFORM" == "osx" ]; then
  export PLATFORM="macosx";
fi

if [ -z "$PLATFORM" ]; then
  if [ "$(uname)" == "Linux" ]; then
    export PLATFORM="linux";
  else
    export PLATFORM="macosx";
  fi;
fi

if [ "$LUA" == "luajit" ]; then
  curl http://luajit.org/download/$LUAJIT_BASE.tar.gz | tar xz
  cd $LUAJIT_BASE
  make && sudo make install
  sudo ln -s /usr/local/bin/luajit /usr/local/bin/lua
  cd $TRAVIS_BUILD_DIR;
else
  if [ "$LUA" == "lua5.1" ]; then
    curl http://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
    cd lua-5.1.5;
  elif [ "$LUA" == "lua5.2" ]; then
    curl http://www.lua.org/ftp/lua-5.2.3.tar.gz | tar xz
    cd lua-5.2.3;
  fi
  sudo make $PLATFORM install
  cd $TRAVIS_BUILD_DIR;
fi

LUAROCKS_BASE=luarocks-$LUAROCKS
curl http://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz
cd $LUAROCKS_BASE;

if [ "$LUA" == "luajit" ]; then
  ./configure --lua-suffix=jit --with-lua-include=/usr/local/include/luajit-2.0;
else
  ./configure;
fi

make build && sudo make install

cd $TRAVIS_BUILD_DIR

rm -rf $LUAROCKS_BASE

if [ "$LUA" == "luajit" ]; then
  rm -rf $LUAJIT_BASE;
elif [ "$LUA" == "lua5.1" ]; then
  rm -rf lua-5.1.5;
elif [ "$LUA" == "lua5.2" ]; then
  rm -rf lua-5.2.3;
fi
