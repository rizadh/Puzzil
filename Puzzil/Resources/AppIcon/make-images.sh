for size in 20 29 40 58 76 80 87 120 152 167 180 1024
do
    convert -density $size -resize $size"x"$size AppIcon.svg Output/AppIcon-$size.png
done
