#!/usr/bin/env bash
#this is a non-priviledged setup script to make links for these scripts available in $HOME/.local/bin
if [ "$EUID" -eq 0 ]; then
	echo "Don't run this as root -- it's not for system-wide installation"
	exit 1
fi
#check if this script was executed in $HOME/nokia_superuser_tools
pwd="$(pwd)"
if [ "$pwd" != "$HOME/nokia_superuser_tools" ]; then
	echo "Please run this script from the top directory, i.e. $HOME/nokia_superuser_tools"
	echo "Alternatively, edit this script"
	exit 1
fi
#check if directories exist
if [ ! -d "$HOME/.local" ]; then
	echo "Creating directory at $HOME/.local"
	mkdir -p $HOME/.local
fi
if [ ! -d "$HOME/.local/bin" ]; then
	echo "Creating directory at $HOME/.local/bin"
	mkdir -p $HOME/.local/bin
fi
#check if they are on the user's $PATH variable
echo $PATH | grep "$HOME/.local/bin" > /dev/null
local_bin_in_path="$?"
if [ "$local_bin_in_path" -ne 0 ]; then
	 #detect user default shell
	 grep $(whoami) /etc/passwd | grep zsh > /dev/null
	 shell_is_zsh="$?"
	 if [ "$shell_is_zsh" -eq 0 ]; then
		 echo "Zsh detected as user default shell"
		 echo "Appending $HOME/.local/bin to your PATH variable"
		 printf "export PATH=$HOME/.local/bin:" >> $HOME/.zshrc
		 printf '$PATH' >> $HOME/.zshrc
		 printf "\n" >> $HOME/.zshrc
		 source $HOME/.zshrc
	 else
		 grep $(whoami) /etc/passwd | grep bash > /dev/null
		 shell_is_bash="$?"
		 if [ "$shell_is_bash" -eq 0 ]; then
			 echo "Bash detected as user default shell"
			 echo "Appending $HOME/.local/bin to your PATH variable"
			 printf "export PATH=$HOME/.local/bin:" >> $HOME/.bashrc
			 printf '$PATH' >> $HOME/.bashrc
			 printf "\n" >> $HOME/.bashrc
			 source $HOME/.bashrc
		 else
			 echo "You will have to add $HOME/.local/bin to your PATH environment variable"
		fi
	fi
fi
#make the links already
make_links() {
ln -s $HOME/nokia_superuser_tools/targeting/zoomeye.sh $HOME/.local/bin/nokia-zoomeye && echo "nokia-zoomeye linked"
ln -s $HOME/nokia_superuser_tools/targeting/host-back-online.sh $HOME/.local/bin/nokia-back-online && echo "nokia-back-online linked"
ln -s $HOME/nokia_superuser_tools/targeting/ip-range-scan.sh $HOME/.local/bin/nokia-ip-range-scan && echo "nokia-ip-range-scan linked"
ln -s $HOME/nokia_superuser_tools/exploitation/autopwn.sh $HOME/.local/bin/nokia-autopwn && echo "nokia-autopwn linked"
ln -s $HOME/nokia_superuser_tools/exploitation/decrypt-all.sh $HOME/.local/bin/nokia-decrypt-all && echo "nokia-decrypt-all linked"
ln -s $HOME/nokia_superuser_tools/exploitation/nokia-use-ip-cfg $HOME/.local/bin/nokia-use-ip-cfg && echo "nokia-use-ip-cfg linked"
ln -s $HOME/nokia_superuser_tools/exploitation/nokia-xml-editor $HOME/.local/bin/nokia-xml-editor && echo "nokia-xml-editor linked"
ln -s $HOME/nokia_superuser_tools/exploitation/print-all.sh $HOME/.local/bin/nokia-print-all && echo "nokia-print-all linked"
}
make_links || echo "Something went wrong!" && exit 1
exit 0
