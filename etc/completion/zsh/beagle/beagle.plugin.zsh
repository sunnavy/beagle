# add beagle completion function to path
fpath=($ZSH/plugins/beagle $fpath)
autoload -U compinit
compinit -i
