#!/bin/bash
mapfile -d $'' feature_files < <(find "features/regression" -name "*.feature" -print0 )


shuffle() {
   local i tmp size max rand
   size=${#feature_files[*]}
   max=$(( 32768 / size * size ))
   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${feature_files[i]} feature_files[i]=${feature_files[rand]} feature_files[rand]=$tmp
   done
}

shuffle
echo ${feature_files[@]}
echo ${feature_files[@]} > feature_files_0.txt

split=$((${#feature_files[@]}/5))

echo ${feature_files[@]:0:$((split + 1))} > feature_files_1.txt
echo ${feature_files[@]:$((split + 1)):((split + 1))}  > feature_files_2.txt
echo ${feature_files[@]:$((split + split + 2)):((split + 1))}  > feature_files_3.txt
echo ${feature_files[@]:$((split + split + split + 3)):((split + 1))}  > feature_files_4.txt
echo ${feature_files[@]:$((split + split + split + split + 4)):((split + 10))}  > feature_files_5.txt
