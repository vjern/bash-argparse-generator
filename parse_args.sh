shopt -s expand_aliases

cl() {
    # Prints color escape sequences, except if stderr (2) is redirected (assumed to be used together with 'info' which only writes to stderr)
    [ -t 2 ] && echo -ne "\033[$1m"
}

info() {
    # return
    # Echo anything to stderr
    echo -e $(cl 95)info: $(cl 96)$@ 1>&2 $(cl 0)
}

decho() {
    depth="$1"
    shift
    [[ -z "$mini" ]] && for i in $(seq $depth); do
        echo -n '    '
    done
    if [[ -z "$mini" ]]; then
        echo "$@" 
    elif [ "$@" ]; then
        echo -n "$@ "
    fi
}

sc() {
    echo -n ';'
}

parse() {
    info args="'$@'"

    posparams=""

    # Parse for actual arguments

    for i in $@; do
        case "$i" in
            +*)
                name=$(echo $i | tr -d '+')
                eval "$name=true"
        esac
    done

    # 

    decho 0 'posargs="";'
    decho 0
    decho 0 'while [[ $# -gt 0 ]]; do'
    decho 1 'case "$1" in'

    while [ $# -gt 0 ]; do
        case "$1" in
            -*) 
                name=`echo $1 | rev | cut -d- -f1 | rev`
                info "flag? $1 => $name";
                capture=$(echo $1 | tr ',' '|')
                decho 2 "$capture)"
                tar='true'
                if [ "$2" == "{}" ]; then
                    tar='"$2"; shift'
                fi
                decho 3 "$name="$tar';'
                [[ -z "$mini" ]] && decho 3 "echo KW.ARG: $name = "'$'"$name"';'
                decho 3 ';;'
                ;;
            \"*):
                break
                ;;
            {})
                # Check if flag name exists;
                # If it doesn't, raise an error;
                # If it does make it a storage flag;
                ;;
            +*)
                ;;
            *)
                info "pos? $1"
                posparams="$posparams:$1"
                # Store it in positional args;
                ;;
        esac
        shift
    done

    info posparams="$posparams"

    decho 2 '*)'
    if [ -n "$posparams" ]; then
        # Add *) case
        # decho 2 '*)'
        decho 3 'posargs="$posargs:$1";'
    else
        decho 3 'echo 2>&1 "Unexpected positional argument";'
        decho 3 'exit 1;'
    fi


    decho 1 'esac;'
    decho 1 'shift;'
    decho 0 'done;'
    decho 0
    if [ -n "$posparams" ]; then
        it=2
        [[ -z "$mini" ]] && decho 0 '# Parse positional arguments'
        [[ -z "$mini" ]] && decho 0 "echo posargs="'$posargs'
        decho 0 'if [[ -n "$posargs" ]]; then'
        for param in $(echo $posparams | tr ':' '\n'); do
            decho 1 "$param="'$(echo "$posargs" | cut -d: -f'"$it"');'
            [[ -z "$mini" ]] && decho 1 "echo POS.ARG: $param = "'$'"$param"';'
            it=$((it + 1))
        done
        decho 0 'fi'
    fi
}

arg-make() {
    parse "$@"
}

revargs() {
    args="$1"
    shift
    info shellargs="$args"
    # info "$@"
    # script=`$@`
    # info "script=$script"
    # eval "$script"
    # echo flag=$flag
    # echo allow=$allow

    arg2 "$*" "$args"
}

arg2() {
    info gaga="$@"
    info 1="$1"
    script=`$@`
    while [ $# -gt 1 ]; do
        shift
    done
    info trimmed="$@"
    args=$(echo $@ | sed -e 's/^"//g' | sed -e 's/"$//g')
    arg3 "$script" "$args"
}

arg3() {
    script="$1"
    info arg3script="$script"
    shift
    echo arg3args="$@"
    eval "$script"
    info return=$?
}

sss() {
    # source <($@)
    # eval "$($@)"
    eval "$@"
}

prefix() {
    # Parse a command whose name is separated by dashes, but provided with a space separator as would be arguments.
    # [ ${script} get latest revision {service} ]
    # is translated to
    # [ ${script} get-latest-revision {service} ]
    # if 'get-region' does exist in the current context
    pre="$1"
    cmd="$2"

    cmd="$pre-$cmd"

    shift
    shift

    if type -t "$cmd" > /dev/null; then
        info `cl 94`prefix`cl 0` [ $cmd ]
        result=`$cmd $@`
        [ ! -t 1 ] && info `cl 93`'⋅='`cl 0` $result
    else
        result=`prefix $cmd $@`
    fi

    [ -n "$result" ] && echo "$result"

}

if [ $# -gt 0 ]; then
    cmd=$1
    shift
    args=$@
    if type -t "$cmd" > /dev/null && [[ `type -t "$cmd" > /dev/null` != "file" ]]; then
        $cmd $args
    else
        prefix $cmd $args
    fi
    exit
fi


# echo "$(
#     parse \
#         file \
#         -a,--allow {} \
#         -f,--flag
# )"

alias argparse='source <'
# alias argmake='parse'

# argparse(
#     argmake \
#     file \
#     -a,--allow {} \
#     -f,--flag
# )

# source <(parse \
#     file \
#     -a,--allow {} \
#     -f,--flag
# )

# alias arg='revargs "$*"'

# echo "$*"
# revargs "\"$*\"" parse \
#     file \
#     files* \
#     -a,--allow {} \
#     -f,--flag

# echo files=$files
# echo flag=$flag
# echo allow=$allow

# sss a=3
# echo a=$a
