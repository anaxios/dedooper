#!/bin/bash
. fun.sh    # Using super nerdy functional library as dependency

#shopt -s globstar # dotglob
echo "Bash Version" $BASH_VERSION

# Get the first argument passed in and remove any spaces                                
    declare -a workingDir=$(list "$1" | sed -e 's/[[:space:]]/_/g')

# Recursively get directories by using ls -R and removing everything but the full paths of the directories. Also replacing
    declare -a directoriesToSearch=( "$(ls -R "$1" | grep -e '^/' | sed -e 's/://') ")



# maps shasum over all the directories and calls all the files inside. and replacing spaces with underscores
    declare -a hashesFromShasum=( "$(list "${directoriesToSearch[@]}" \
                                   | map lambda x . 'shasum -a 1 "$x"/* 2> /dev/null \
                                   | sed -e 's/[[:space:]]/_/g' ')" ) 
                                

# turns hashesFromShasum and file names into tuples can cut a section out of the middle to make it a little easier to read.
    tupify() {
        local -a r
        local -a x=("$@")
        local -a number of elements

        r+=("$(list "${x[@]}" | map lambda a . \
                                              'tup $(echo "$a" | cut -c 1-40 ) \
                                                   $(echo "$a" | cut -c 41- )')" )

        echo "${r[@]}"  
            
    }

# Tupify recursively but runs too sloww

    tupifyRecur() {
        local a
            tupify_itr() {
                local w=$@
                shift
                local x=$@

                if [[ -z $x ]]; then echo "${a[@]}"
                else a+=($(tup $(list $x | take 1 | cut -c 1-40) \
                               $(list $x | take 1 | cut -c 41-)))

                    tupify_itr $x 
                fi
            }

        tupify_itr $@
    }


# if item in array is  > the item above it, move it one before. check next item in array
# repeat on entire list until no more swaps are needed

sortAnArray() {
    local -a listOfItems=("$*")
    local swapCounter=1 # <- Starts at one to initiate loop

    while [[ $swapCounter -gt 0 ]]; do 
        local itemIndex=0
        local nextItemIndex=1 # look to see if next item in array is < or >

        swapCounter=0

        for i in "${listOfItems[@]}"; do
 
            if [[ "${listOfItems[$nextItemIndex]}" > "${listOfItems[$itemIndex]}" ]]; then
                local originalItem="${listOfItems[$itemIndex]}"
                listOfItems[$itemIndex]="${listOfItems[$nextItemIndex]}"
                listOfItems[$nextItemIndex]=$originalItem
                swapCounter=$(($swapCounter + 1))
            fi

            itemIndex=$(($itemIndex + 1))
            nextItemIndex=$(($nextItemIndex + 1))

        done
    done

    echo "${listOfItems[@]}"
}

# checks the head of the hash list with the tail and repeats on the tail until the list is empty
    checkForMatch() {
            local x=$@
            local -a hashes=( $(list ${x[@]} | map lambda a . 'tupl $a ') )
            #local firstElement
            local -a accumulator
            local firstElement    
            local -a hashesfor

            while [[ ${#hashes[@]} -gt 0 ]]; do
                firstElement=${hashes[0]}

                for (( i = 1; i < ${#hashes[@]}; i++ )); do
                    [[ "$firstElement" = "${hashes[$i]}" ]] \
                    && accumulator+=( $firstElement )
                done

                hashes=(${hashes[@]:1})  

                   
            done
            
            echo ${accumulator[@]} 
        }
  
checkForMatchRecur() { # rescursive is way too slow by 8X
    local -a y
      
    checkForMatch_irt() {
        local headx=$1
        shift
        local -a tailx=$@
          
        doesItMatch() {
            local headxz=$headx;
            
            [[ $headxz != $1 ]] && echo "nope" || echo $1 ;
              }
        y+=( "$(list ${tailx[@]} | map lambda a . 'doesItMatch $a ')" )
        
        [[ -z ${tailx[@]} ]] && list "${y[@]}" || checkForMatch_irt ${tailx[@]}
    }
          
    checkForMatch_irt $(list "$@" | map lambda a . 'tupl "$a" ')
}
    
# Look up the hashes that are duplcates in the original tupled array to get the file names
# with DIRs and make them a little prettier
lookupFileNameFromHash() {
    local hashes=$@
    local -a filenameWithHashes
    local -a leftSideOfDIR=( $(list ${DIR[@]} | map lambda a . 'tupl $a ' ) )
    
    for i in ${hashes[@]}; do
        local accu=0
     for j in ${DIR[@]}; do
         [[ "${leftSideOfDIR[$accu]}" = "$i" ]] && filenameWithHashes+=( "$j" )
         accu=$(($accu + 1))
         done
    done
 echo $(list ${filenameWithHashes[@]} | cut -c -42,$((${#workingDir} + 45))- )
}   



# Start of program
# TODO add optional search for hidden files
# TODO add option for compairing two directories
# TODO remove using underscores with proper use of quotes

declare -a DIR=("$(tupify "${hashesFromShasum[@]}")")

list $(sortAnArray $(lookupFileNameFromHash $(checkForMatch "${DIR[@]}")))


