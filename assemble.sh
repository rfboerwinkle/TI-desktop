# spasm looks for things to include from directory where it is run, hence "cd".
cd src/00/
../../software/spasm-ng-master/spasm "$@" base.asm
cd ../7c/
../../software/spasm-ng-master/spasm "$@" base.asm
