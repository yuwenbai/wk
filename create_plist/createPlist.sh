#! /bin/bash

# input paths
IMAGE_DIR=/Users/ding/Department_Client/tools/create_plist/images

# path that game proj use
GAME_IMAGE_PATH=/Users/ding/client/client/mahjong_currency/res/ui_plist
CCS_IMAGE_PATH=/Users/ding/client/art/cocostudio/mahjong_currency/cocosstudio/ui_plist

# temporary path to place the sprite sheets
OUTPUT_PATH=$IMAGE_DIR/../plist
OUTPUT_PATH_PVR=$OUTPUT_PATH/packagedPVR
OUTPUT_PATH_PNG=$OUTPUT_PATH/packagedPNG

# path of the texture packer command line tool
TP=/usr/local/bin/TexturePacker

# $1: Source Directory where the assets are located
# $2: Output File Name without extension
# $3: RGB Quality factor
# $4: Scale factor
# $5: Max-Size factor
# $6: Texture Type (PNG, PVR.CCZ)
# $7: Texture format
pack_texturesPVR() {

    ${TP} --smart-update \
        --texture-format $7 \
        --format cocos2d \
        --data "$2".plist \
        --sheet "$2".$6 \
        --maxrects-heuristics best \
        --enable-rotation \
        --scale $4 \
        --shape-padding 1 \
        --max-size $5 \
        --opt "$3" \
        --trim \
        --size-constraints AnySize \
        --premultiply-alpha \
        $1/*.png
}

pack_texturesPNG() {

    ${TP} --smart-update \
        --texture-format $7 \
        --format cocos2d \
        --data "$2".plist \
        --sheet "$2".$6 \
        --maxrects-heuristics best \
        --enable-rotation \
        --scale $4 \
        --shape-padding 1 \
        --max-size $5 \
        --opt "$3" \
        --trim \
        --size-constraints AnySize \
        $1/*.png
}

# check the output path

if [ -d $OUTPUT_PATH ];then
    :
else
    mkdir $OUTPUT_PATH
fi

if [ -d $OUTPUT_PATH_PVR ]
then
    :
else
    mkdir $OUTPUT_PATH_PVR
fi

if [ -d $OUTPUT_PATH_PNG ]
then
    :
else
    mkdir $OUTPUT_PATH_PNG
fi

# do the job
for i in $IMAGE_DIR/*
do
    if [ -d $i ]
    then
        region=`basename $i`
        if [ -d $OUTPUT_PATH_PNG/$region ]
        then
            mkdir $OUTPUT_PATH_PNG/$region
        fi

        if [ -d $OUTPUT_PATH_PVR/$region ]
        then
            mkdir $OUTPUT_PATH_PVR/$region
        fi

        for k in $i/*
        do
            if [ -d $k ]
            then
                plistName=`basename $k`
                pack_texturesPNG $k $OUTPUT_PATH_PNG/$region/$plistName 'RGBA8888' 1 2048 'png' "png"
                pack_texturesPVR $k $OUTPUT_PATH_PVR/$region/$plistName 'RGBA8888' 1 2048 'pvr.ccz' "pvr2ccz"
            fi
        done
        # spriteSheetName=`basename $i`
        # pack_textures $i $OUTPUT_PATH_PNG/$spriteSheetName 'RGBA8888' 1 2048 'png' "png"
        # pack_textures $i $OUTPUT_PATH_PVR/$spriteSheetName 'RGBA8888' 1 2048 'pvr.ccz' "pvr2ccz"
    fi
done

# cp them to the game proj image path

# cp -f $OUTPUT_PATH_PVR/* $GAME_IMAGE_PATH