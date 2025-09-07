export ZSH="/var/home/hac/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)

alias docker="podman"
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
export PATH=$PATH:~/go/bin/
export GOPATH=$HOME/go
export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -U +X bashcompinit && bashcompinit

# The next line updates PATH for the Google Cloud SDK.
if [ -f "${HOME}/bin/google-cloud-sdk/path.zsh.inc" ]; then . "${HOME}/bin/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then . "${HOME}/google-cloud-sdk/completion.zsh.inc"; fi
