DMGTITLE="Install Inochi Session"
DMGFILENAME="Install_Inochi_Session.dmg"

if [ -d "out/Inochi Session.app" ]; then
    if [ -f "out/$DMGFILENAME" ]; then
        echo "Removing prior install dmg..."
        rm "out/$DMGFILENAME"
    fi

    PREVPWD=$PWD
    cd out/
    echo "Building $DMGFILENAME..."

    # Create Install Volume directory

    if [ -d "InstallVolume" ]; then
        echo "Cleaning up old install volume..."
        rm -r InstallVolume
    fi

    mkdir -p InstallVolume
    cp ../LICENSE LICENSE
    cp -r "Inochi Session.app" "InstallVolume/Inochi Session.app"
    
    create-dmg \
        --volname "$DMGTITLE" \
        --volicon "InochiSession.icns" \
        --background "../build-aux/osx/dmgbg.png" \
        --window-size 800 600 \
        --icon "Inochi Session.app" 200 250 \
        --hide-extension "Inochi Session.app" \
        --eula "LICENSE" \
        --app-drop-link 600 250 \
        "$DMGFILENAME" InstallVolume/

    echo "Done! Cleaning up temporaries..."
    rm LICENSE

    echo "DMG generated as $PWD/$DMGFILENAME"
    cd $PREVPWD
else
    echo "Could not find Inochi Session for packaging..."
fi