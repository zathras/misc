set JDK=c:/Program Files/Java/jdk1.8.0_60
rm -rf ../lib
mkdir ..\lib
cd ../src
javah scurses.RawCurses
rm -f scurses/scurses_RawCurses.h
mv scurses_RawCurses.h scurses
cd scurses
gcc "-I%JDK%/include" "-I%JDK%/include/win32" -I../../win32/pdcurses_3_4 -Wl,--add-stdcall-alias -shared -o scurses.dll ../../win32/pdcurses_3_4/win32/*.o *.c
copy scurses.dll c:\lib\scurses.dll
cd ../../win32
