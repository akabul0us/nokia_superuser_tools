#!/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clear_color='\033[0m'
echo "This will build dependencies from source, which may take a considerable amount of time depending on your system."
echo "You will need a C/C++ compiler (preferably GCC), Golang, and Cargo (rust) installed to do this, plus any libraries required for each build."
echo "You will also need python3, git, and GNU make installed."
echo "Alternatively, you can search your package manager for compiled binaries of these dependencies."
sleep 6
printf "Checking for C compiler... "
if command -v cc &> /dev/null; then
    printf "${green}yes${clear_color}\n"
else
    printf "${red}no${clear_color}\n" 
    echo "Please install a C compiler"
    exit 1
fi
printf "Checking for C++ compiler... "
if command -v c++ &> /dev/null; then
    printf "${green}yes${clear_color}\n"
else
    printf "${red}no${clear_color}\n"
    echo "Please install a C++ compiler"
    exit 1
fi
printf "Checking for Go compiler... "
if command -v go &> /dev/null; then
    echo "yes"
else
    echo "no" 
    echo "Please install Golang"
    exit 1
fi
printf "Checking for Cargo (Rust package manager)... "
if command -v cargo &> /dev/null; then
    echo "yes"
else
    echo "no"
    echo "Please install Rust"
    exit 1
fi
printf "Checking for Python3..."
if command -v python3 &> /dev/null; then
    echo "yes"
else
    echo "no"
    echo "Please install python3"
    exit 1
fi
printf "Checking for make..."
if command -v make &> /dev/null; then
    echo "yes"
else
    echo "no"
    echo "Please install make"
    exit 1
fi
printf "Checking for git..."
if command -v git &> /dev/null; then
    echo "yes"
else
    echo "no"
    echo "Please install git"
    exit 1
fi
check_local_bin() {
echo $PATH | grep .local/bin >/dev/null
local_bin_on_path="$?"
if [ $local_bin_on_path -eq 1 ]; then
        echo "Directory $HOME/.local/bin found, but it isn't on your PATH"
        echo 'To change this, run `export PATH=$HOME/.local/bin:$PATH`'
else
        echo "Directory $HOME/.local/bin found and is along PATH"
fi
}
if [ -d $HOME/.local/bin ]; then
    check_local_bin
else
    mkdir -p $HOME/.local/bin
fi
if command -v ipinfo &> /dev/null; then
    echo "ipinfo already installed!"
else
    echo "Building ipinfo"
    cd $HOME
    if [ ! -d ipinfo-cli; then
        git clone https://github.com/ipinfo/cli ipinfo-cli
        cd ipinfo-cli
    else
        echo "Git repo already cloned"
        cd ipinfo-cli 
        git pull
    fi
    go install ./ipinfo/
    ln -s $(pwd)/ipinfo/ipinfo $HOME/.local/bin/ipinfo
fi
if command -v nmap &> /dev/null; then
    echo "nmap already installed!"
else
    echo "Building nmap"
    cd $HOME
    git clone https://github.com/nmap/nmap
    cd nmap
    ./configure
    make
    ln -s $HOME/nmap/nmap $HOME/.local/bin/nmap
fi
if command -v urlencode &> /dev/null; then
    echo "urlencode already installed!"
else
    echo "Building urlencode"
    cargo install urlencode
    ln -s $HOME/.cargo/bin/urlencode $HOME/.local/bin/urlencode
fi
python3 -c "import Crypto" && echo "python Crypto library already installed!" || echo "No python3 module named Crypto found - you can use pip or your package manager but for this one you must manually install it, as we don't want to be responsible for breaking your python installation"
check_local_bin
