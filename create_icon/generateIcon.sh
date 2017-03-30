#!/bin/bash

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

convert 'srcicon.png' '-resize' '28x28' 'othericon/icon-28.png'
convert 'srcicon.png' '-resize' '108x108' 'othericon/icon-108.png'

convert 'srcicon.png' '-resize' '48x48' 'iosicon/Icon-24@2x.png'
convert 'srcicon.png' '-resize' '55x55' 'iosicon/Icon-27.5@2x.png'
convert 'srcicon.png' '-resize' '29x29' 'iosicon/Icon-29.png'
convert 'srcicon.png' '-resize' '58x58' 'iosicon/Icon-29@2x.png'
convert 'srcicon.png' '-resize' '88x88' 'iosicon/Icon-29@3x.png'
convert 'srcicon.png' '-resize' '30x30' 'iosicon/Icon-30.png'
convert 'srcicon.png' '-resize' '40x40' 'iosicon/Icon-40.png'
convert 'srcicon.png' '-resize' '80x80' 'iosicon/Icon-40@2x.png'
convert 'srcicon.png' '-resize' '120x120' 'iosicon/Icon-40@3x.png'
convert 'srcicon.png' '-resize' '88x88' 'iosicon/Icon-44@2x.png'
convert 'srcicon.png' '-resize' '50x50' 'iosicon/Icon-50.png'
convert 'srcicon.png' '-resize' '100x100' 'iosicon/Icon-50@2x.png'
convert 'srcicon.png' '-resize' '120x120' 'iosicon/Icon-60@2x.png'
convert 'srcicon.png' '-resize' '180x180' 'iosicon/Icon-60@3x.png'
convert 'srcicon.png' '-resize' '72x72' 'iosicon/Icon-72.png'
convert 'srcicon.png' '-resize' '144x144' 'iosicon/Icon-72@2x.png'
convert 'srcicon.png' '-resize' '76x76' 'iosicon/Icon-76.png'
convert 'srcicon.png' '-resize' '152x152' 'iosicon/Icon-76@2x.png'
convert 'srcicon.png' '-resize' '167x167' 'iosicon/Icon-83.5@2x.png'
convert 'srcicon.png' '-resize' '172x172' 'iosicon/Icon-86@2x.png'
convert 'srcicon.png' '-resize' '196x196' 'iosicon/Icon-98@2x.png'
convert 'srcicon.png' '-resize' '57x57' 'iosicon/Icon.png'
convert 'srcicon.png' '-resize' '120x120' 'iosicon/Icon@2x.png'

echo 'ios is finish!'

convert 'srcicon.png' '-resize' '72x72' 'androidicon/drawable-hdpi/icon.png'
convert 'srcicon.png' '-resize' '32x32' 'androidicon/drawable-ldpi/icon.png'
convert 'srcicon.png' '-resize' '48x48' 'androidicon/drawable-mdpi/icon.png'
convert 'srcicon.png' '-resize' '96x96' 'androidicon/drawable-xhdpi/icon.png'
convert 'srcicon.png' '-resize' '144x144' 'androidicon/drawable-xxhdpi/icon.png'
convert 'srcicon.png' '-resize' '192x192' 'androidicon/drawable-xxxhdpi/icon.png'

echo 'android is finish!'


