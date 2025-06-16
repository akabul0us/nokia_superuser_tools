#!/usr/bin/env bash
echo "This will build dependencies from source, which may take a considerable amount of time depending on your system."
echo "You will need a C/C++ compiler (preferably GCC), Golang, and Cargo (rust) installed to do this, plus any libraries required for each build."
echo "You will also need python3, git, and GNU make installed."
echo "Alternatively, you can search your package manager for compiled binaries of these dependencies."
sleep 10
if [ ! -e "$(which ipinfo)" ]; then
    echo "Building ipinfo"
    cd $HOME
    git clone https://github.com/ipinfo/cli ipinfo-cli
    cd ipinfo-cli
    go install ./ipinfo/
    ln -s $GOPATH/bin/ipinfo $HOME/.local/bin/ipinfo
else
    echo "ipinfo already installed!"
fi
if [ ! -e "$(which nmap)" ]; then
    echo "Building nmap"
    cd $HOME
    git clone https://github.com/nmap/nmap
    cd nmap
    ./configure
    make
    ln -s $HOME/nmap/nmap $HOME/.local/bin/nmap
else
    echo "nmap already installed!"
fi
if [ ! -e "$(which urlencode)" ]; then
    echo "Building urlencode"
    cargo install urlencode
    ln -s $HOME/.cargo/bin/urlencode $HOME/.local/bin/urlencode
else 
    echo "urlencode already installed!"
fi
python3 -c "import Crypto" && echo "python Crypto library already installed!" || echo "No python3 module named Crypto found - you can use pip or your package manager but for this one you must manually install it, as we don't want to be responsible for breaking your python installation"

