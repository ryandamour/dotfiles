export ZSH="/var/home/hac/.oh-my-zsh"
ZSH_THEME="alanpeabody"
plugins=(git)

alias vi="nvim"
alias vim="nvim"
alias vagrant='sudo podman run --rm -it \
        --volume /run/libvirt:/run/libvirt \
        --volume "${HOME}:${HOME}:rslave" \
        --env "HOME=${HOME}" \
        --workdir "$(pwd)" \
        --net host \
        --privileged \
        --security-opt label=disable \
        --entrypoint /usr/bin/vagrant \
        localhost/vagrant-container:latest'

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/.cargo/bin
export PATH=$PATH:~/bin/
export GOPATH=$HOME/go
export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock

source $ZSH/oh-my-zsh.sh
source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
