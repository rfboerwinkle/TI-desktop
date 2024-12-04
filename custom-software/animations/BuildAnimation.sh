../../software/spasm-ng-master/spasm -A GenericPlayer.asm
python3 Animator.py "$1"
x="${1%/}"
cat GenericPlayer.bin "${x}.bin" > "${x}Player.bin"
rm GenericPlayer.bin
rm "${x}.bin"
