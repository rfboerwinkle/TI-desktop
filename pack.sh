cd custom-software
python3 build_8xu.py \
00:0000:../src/00/base.bin \
7C:0000:../src/7C/base.bin \
02:0000:../src/programs/spawner.bin \
03:0000:../src/programs/xkcd_twitter.bin \
04:0000:../src/programs/filler.bin \
05:0000:../src/programs/notepad.bin \
06:0000:animations/nautilus_player.bin \
07:0000:animations/early_bird_player.bin
mv trial.8xu ../
