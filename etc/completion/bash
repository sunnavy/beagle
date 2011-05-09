# the contained completion routines provide support for completing:
#
#    *) beagle 'subcommands'
#
# to use these routines:
#
#    1) copy this file to somewhere (e.g. ~/.beagle-completionrc).
#    2) add the following line to your .bashrc:
#        source ~/.beagle-completionrc
#

if [[ "$BEAGLE_CMDS" = "" ]]; then
    BEAGLE_CMDS=`beagle cmds`;
fi

if [[ "$BEAGLE_ALIAS" = "" ]]; then
    BEAGLE_ALIAS=`beagle cmds --alias`;
fi

_beagle ()
{
    local cur prev

    COMPREPLY=()
    _get_comp_words_by_ref -n : cur prev

    case $prev in
        (beagle)
            COMPREPLY=( $( compgen -W "use switch which $BEAGLE_CMDS $BEAGLE_ALIAS" -- "$cur" ) )
            ;;
        (help)
            COMPREPLY=( $( compgen -W "$BEAGLE_CMDS" -- "$cur" ) )
            ;;
        (unfollow|--name|-n|use|switch|rename|root)
            local names
            names=`beagle root --names | tr "\\n" ' '`
            COMPREPLY=( $( compgen -W "$names" -- "$cur" ) )
            ;;
        (--root|-r)
            local roots
            roots=`beagle roots --only-roots | tr "\\n" ' '`
            COMPREPLY=( $( compgen -W "$roots" -- "$cur" ) )
            ;;
        (*)
            _filedir
            ;;
    esac
}

complete -F _beagle beagle

