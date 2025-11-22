cp $1 ./data.txt

# generate 2^$2 times file $1
for ((n=0;n<$2;n++))
do
cat ./data.txt ./data.txt > ./temp
mv ./temp ./data.txt
done

