../../software/spasm-ng-master/spasm -A generic_player.asm
python3 animator.py "$1"
x="${1%/}"
cat generic_player.bin "${x}.bin" > "${x}_player.bin"
rm generic_player.bin
rm "${x}.bin"
