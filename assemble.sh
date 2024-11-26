# spasm looks for things to include from directory where it is run, hence "cd".
cd src/00/
../../software/spasm-ng-master/spasm -A "$@" base.asm
cd ../7c/
../../software/spasm-ng-master/spasm -A "$@" base.asm
cd ../programs/
../../software/spasm-ng-master/spasm -A "$@" filler.asm
../../software/spasm-ng-master/spasm -A "$@" clearer.asm
../../software/spasm-ng-master/spasm -A "$@" spawner.asm
