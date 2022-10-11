# First build ARM64 version...
echo "Building arm64 binary..."
dub build --build=release --config=osx-full --arch=arm64-apple-macos
mv "out/Inochi Session.app/Contents/MacOS/inochi-session" "out/Inochi Session.app/Contents/MacOS/inochi-session-arm64"

# Then the X86_64 version...
echo "Building x86_64 binary..."
dub build --build=release --config=osx-full --arch=x86_64-apple-macos
mv "out/Inochi Session.app/Contents/MacOS/inochi-session" "out/Inochi Session.app/Contents/MacOS/inochi-session-x86_64"

# Glue them together with lipo
echo "Gluing them together..."
lipo "out/Inochi Session.app/Contents/MacOS/inochi-session-x86_64" "out/Inochi Session.app/Contents/MacOS/inochi-session-arm64" -output "out/Inochi Session.app/Contents/MacOS/inochi-session" -create

# Print some nice info
echo "Done!"
lipo -info "out/Inochi Session.app/Contents/MacOS/inochi-session"

# Cleanup and bundle
echo "Cleaning up..."
rm "out/Inochi Session.app/Contents/MacOS/inochi-session-x86_64" "out/Inochi Session.app/Contents/MacOS/inochi-session-arm64"
./osxbundle.sh