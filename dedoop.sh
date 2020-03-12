#!/usr/local/bin/bash
. fun.sh    # Using super nerdy functional library as dependency

shopt -s globstar # dotglob
echo "Bash Version" $BASH_VERSION

# Recursively get directories by using ls -R and removing everything but the full paths of the directories. Also replacing
# white space in files names with "@" to work around white space delimitor usage in Bash
    declare -a directoriesToSearch=( "$(ls -R "$*" | grep -e '^/' | grep -v 'shasum' | sed -e 's/://') ")
                                    #  -e 's/[[:space:]]/::/g' \
                                    
    declare -a workingDir=$(list "$@" | sed -e 's/[[:space:]]/_/g')

#list $directoriesToSearch # debug list files

# maps shasum over all the directories and calls all the files inside. Also using sed to put white spaces back in   
# files names
    #declare -a hashesFromShasum=("$(shasum -a 1 "$*"/**/* 2> /dev/null | sed -e 's/[[:space:]]/_/g')") # 
    declare -a hashesFromShasum=( "$(list "${directoriesToSearch[@]}" | map lambda x . 'shasum -a 1 "$x"/* 2> /dev/null | sed -e 's/[[:space:]]/_/g' ')" )  #        # | sed -e 's/::/[[:space:]]/g'  \
                                                                                     
    #echo ${allFiles[@]}
                # get all files recursively
                # iterate over all files and hash them
                                

#list "${hashesFromShasum[@]}"

 #   turns hashesFromShasum and file names into tuples
    tupify() {
        local -a r
        local -a x=("$@")
        local -a number of elements
            #for ((i = 0; i < "${#x[@]}"; i++)) ; do 
                r+=( "$(list "${x[@]}" | map lambda a . 'tup $(echo "$a" | cut -c 1-40 ) $(echo "$a" | cut -c 41- )')" ) 
                echo "${r[@]}"  
            #done
            
    }

# Tupify recursively but runs too sloww

    tupifyRecur() {
        local a
            tupify_itr() {
                local w=$@
                shift
                local x=$@

                if [[ -z $x ]]; then
                    echo "${a[@]}"
                else
     # echo "hello" ${tupped[@]}
                    a+=( $(tup $(list $x \
                        | take 1 \
                        | cut -c 1-40 ) \
                        $(list $x \
                        | take 1 \
                        | cut -c 41-)) )
     # echo ${a[@]}
                    tupify_itr $x 
                fi
            }

        tupify_itr $@
    }



sortAnArray() {
    local -a listOfItems=("$*")
    local swapCounter=1 # <- Starts at one to initiate loop
 #echo ${listOfItems[2]}
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
    # if it's > move it one before
    # check next item in list
    # repeat on entire list until no more swaps are needed
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
                        [[ "$firstElement" = "${hashes[$i]}" ]] && accumulator+=( $firstElement )
                        #echo "$firstElement"  "${hashes[$i]}"
                    done

                  hashes=(${hashes[@]:1})  

                   
            done
            
            echo ${accumulator[@]} # $(list ${accu[@]} | uniq)
        }
  
    checkForMatchRecur() { # rescursive is way too slow by 8X
        local -a y
        
            checkForMatch_irt() {
                local headx=$1
                shift
                local -a tailx=$@
            
                    doesItMatch() { local headxz=$headx; [[ $headxz != $1 ]] && echo "nope" || echo $1 ; }

                   y+=( "$(list ${tailx[@]} | map lambda a . 'doesItMatch $a ')" )

                [[ -z ${tailx[@]} ]] && list "${y[@]}" || checkForMatch_irt ${tailx[@]}
            }
            
        checkForMatch_irt $(list "$@" | map lambda a . 'tupl "$a" ')
    }

    lookupFileNameFromHash() {
        local hashes=$@
        local -a filenameWithHashes
        local -a leftSideOfTupifiedHashes+=( $(list ${tupifiedHashes[@]} | map lambda a . 'tupl $a ' ) )
        
        for i in ${hashes[@]}; do
        local accu=0

            for j in ${tupifiedHashes[@]}; do

                [[ "${leftSideOfTupifiedHashes[$accu]}" = "$i" ]] && filenameWithHashes+=( "$j" )
                
                accu=$(($accu + 1))
       # echo "left" ${leftSideOfTupifiedHashes[$accu]} "i" $i
             done
        done

        echo $(list ${filenameWithHashes[@]} | cut -c -42,$((${#workingDir} + 45))- )
    }   

# Start of program
    declare -a tupifiedHashes=("$(tupify "${hashesFromShasum[@]}")")
    #checkForMatch ${tupifiedHashes[@]}
   list $( sortAnArray $(lookupFileNameFromHash $(checkForMatch "${tupifiedHashes[@]}")) )
    #echo "tupifyRecur"
    #list $(tupify "${hashesFromShasum[@]}")
    #declare -a randomNumbers=(1 6 5 4 5 6 7 8899 4 5 6 7 7 77 56 45 5  5 46 6 7 46 7 347867 78543 55 5456 457 8 7 677465 34545 4534 54 6 57 57)
    #list $(sortAnArray $(list ${tupifiedHashes[@]} | map lambda a . 'tupl $a'))
    #list $(list $(tupify $hashesFromShasum) | map lambda x . 'tupl $x') | uniq -c | grep -v '^   1'        # uses uniq from Bash to match hashesFromShasum





