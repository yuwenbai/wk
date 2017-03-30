#!/bin/bash
function convert()
{
	cp -f $1 $3
	sips -z $2 $2 $3
}

rm -fr './iosicon'
rm -fr './androidicon'
rm -fr './othericon'

mkdir './iosicon'
mkdir './androidicon'
mkdir './othericon'

mkdir './androidicon/drawable-hdpi'
mkdir './androidicon/drawable-ldpi'
mkdir './androidicon/drawable-mdpi'
mkdir './androidicon/drawable-xhdpi'
mkdir './androidicon/drawable-xxhdpi'
mkdir './androidicon/drawable-xxxhdpi'

convert 'srcicon.png'  28 'othericon/icon-28.png'
convert 'srcicon.png'  108 'othericon/icon-108.png'

convert 'srcicon.png'  48 'iosicon/Icon-24@2x.png'
convert 'srcicon.png'  55 'iosicon/Icon-27.5@2x.png'
convert 'srcicon.png'  29 'iosicon/Icon-29.png'
convert 'srcicon.png'  58 'iosicon/Icon-29@2x.png'
convert 'srcicon.png'  88 'iosicon/Icon-29@3x.png'
convert 'srcicon.png'  30 'iosicon/Icon-30.png'
convert 'srcicon.png'  40 'iosicon/Icon-40.png'
convert 'srcicon.png'  80 'iosicon/Icon-40@2x.png'
convert 'srcicon.png'  120 'iosicon/Icon-40@3x.png'
convert 'srcicon.png'  88 'iosicon/Icon-44@2x.png'
convert 'srcicon.png'  50 'iosicon/Icon-50.png'
convert 'srcicon.png'  100 'iosicon/Icon-50@2x.png'
convert 'srcicon.png'  120 'iosicon/Icon-60@2x.png'
convert 'srcicon.png'  180 'iosicon/Icon-60@3x.png'
convert 'srcicon.png'  72 'iosicon/Icon-72.png'
convert 'srcicon.png'  144 'iosicon/Icon-72@2x.png'
convert 'srcicon.png'  76 'iosicon/Icon-76.png'
convert 'srcicon.png'  152 'iosicon/Icon-76@2x.png'
convert 'srcicon.png'  167 'iosicon/Icon-83.5@2x.png'
convert 'srcicon.png'  172 'iosicon/Icon-86@2x.png'
convert 'srcicon.png'  196 'iosicon/Icon-98@2x.png'
convert 'srcicon.png'  57 'iosicon/Icon.png'
convert 'srcicon.png'  120 'iosicon/Icon@2x.png'

echo 'ios is finish!'

convert 'srcicon.png'  72 'androidicon/drawable-hdpi/icon.png'
convert 'srcicon.png'  32 'androidicon/drawable-ldpi/icon.png'
convert 'srcicon.png'  48 'androidicon/drawable-mdpi/icon.png'
convert 'srcicon.png'  96 'androidicon/drawable-xhdpi/icon.png'
convert 'srcicon.png'  144 'androidicon/drawable-xxhdpi/icon.png'
convert 'srcicon.png'  192 'androidicon/drawable-xxxhdpi/icon.png'

echo 'android is finish!'


