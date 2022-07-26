mkdir -p out/

if [ -n `$(find tl/ -name "*.po" 2>/dev/null)` ]
then
    echo "No translations, skipping..."
else
    for f in tl/*.po; do
        msgfmt -o "out/$(basename -- "$f" .po).mo" -- "$f" 
    done
fi