#!/usr/local/bin/bash

set -e #u
set -o pipefail
ARGS=("$@")
# . fun.sh    # Using super nerdy functional library as dependency

#shopt -s globstar # dotglob
echo "Bash Version" $BASH_VERSION

declare -A hashArray

hasFlag() {
    local flag=${1}
    for arg in $ARGS; do
        if [ "$flag" == "$arg" ]; then
            echo "true"
        fi
    done
    echo "false"
}

printMatch() {
    local i=($@)
    local n
    for K in "${!hashArray[@]}"; do
        for match in $@; do
             if [[ "${hashArray[$K]}" == $match ]]; then
                n+=($match:"$K")
             fi
        done
    done
    printf '%s\n' "${n[@]}"
}

getHash() {
     echo "$( shasum -a 1 "$1" 2> /dev/null | cut -c 1-40 - )"
}

listFiles() {
    local command="$1"
    local n
    loop() {
        for file in "$2"/*; do
            if [ -d "$file" ]; then
                loop "$1" "$file"
            elif [ -f "$file" ]; then
                hashArray+=( ["$file"]=$($command "$file") )
            fi
        done
    }
    loop "$@"
    echo $n
}

main() {
    for dir in "$@"; do
        if [ "-n" == "$dir" ]; then
            findNotMatch="1"
        elif [ -d "$dir" ]; then
            listFiles getHash "$dir"
        fi
    done
    printMatch $(printf '%s ' $(printf '%s\n' ${hashArray[@]} | sort | uniq -d)) | sort -t ":" -k 1
}
main "${ARGS[@]}"


# filterDup() {
#     local n
#     local outerhead
#     outerloop() {
#         if [[ ! $@ ]]; then return; fi
#         outerhead=$1
#         shift
#         loop() {
#             if [[ ! $2 ]]; then return; fi
#             if [ "$outerhead" == "$1" ]; then
#                 n+=("$outerhead")
#             fi
#             shift
#             loop $@
#         }
#         loop $@
#         outerloop $@
#     }
#     outerloop $@
#     echo ${n[@]}
# }

