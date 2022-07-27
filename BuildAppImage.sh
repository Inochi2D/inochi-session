mkdir build
cd build

mkdir inochi-session.AppDir
cd inochi-session.AppDir
mkdir -p usr/bin
mkdir -p usr/lib
mkdir -p usr/share/metainfo
cp ../../out/*.so usr/lib/
cp ../../out/inochi-session usr/bin/inochi-session
cp ../../out/*.mo ./
cp ../../res/icon_x256.png icon_x256.png
cp ../../res/inochi-session.desktop inochi-session.desktop
cp ../../res/inochi-session.appdata.xml usr/share/metainfo/inochi-session.appdata.xml
cp ../../res/AppRun AppRun
cp ../../res/*-LICENSE usr/bin/
cp ../../LICENSE usr/bin/LICENSE


# Make sure to chmod stuff
chmod a+x AppRun
chmod a+x usr/bin/inochi-session

cd ..

ARCH=x86_64 appimagetool.AppImage inochi-session.AppDir