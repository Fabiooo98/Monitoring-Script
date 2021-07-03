x=1
while [ $x -le 10 ] ; do
    if (( x % 2 == 0 )) ; then
        echo $x" seconds have passed"
    fi
    x=$(( $x + 1 ))
    sleep 1
done