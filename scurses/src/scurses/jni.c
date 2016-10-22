

#include <stdio.h>
#include <stdlib.h>
#include <curses.h>
#include "scurses_RawCurses.h"

JNIEXPORT jboolean JNICALL 
Java_scurses_RawCurses_init(JNIEnv *env, jclass obj) 
{
#ifndef __WIN32__
    /* Catch the case where we're on Unix and the terminal is unknown.
     * initscr(), unfortunately, calls exit() on error, rather than
     * returning null!
     */
    if (!getenv("TERM")) {
	return FALSE;
    }
#endif
    if (!initscr()) {
	return FALSE;
    }
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(1);
    leaveok(stdscr, FALSE);
    return TRUE;
}

JNIEXPORT void JNICALL 
Java_scurses_RawCurses_endwin(JNIEnv *env, jclass obj)
{
    endwin();
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getmaxx(JNIEnv *env, jclass obj) 
{
    return getmaxx(stdscr);
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getmaxy(JNIEnv *env, jclass obj) 
{
    return getmaxy(stdscr);
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_refresh(JNIEnv *env, jclass obj) 
{
    return refresh();
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_clear(JNIEnv *env, jclass obj) 
{
    return clear();
}

JNIEXPORT void JNICALL 
Java_scurses_RawCurses_clearok(JNIEnv *env, jclass obj, jboolean ok)
{
    clearok(curscr, ok);
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_addch(JNIEnv *env, jclass obj, jchar ch) 
{
    return addch(ch);
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getch(JNIEnv *env, jclass obj)
{
    return getch();
}

JNIEXPORT void JNICALL 
Java_scurses_RawCurses_move(JNIEnv *env, jclass obj, jint y, jint x)
{
    move(y, x);
}

JNIEXPORT void JNICALL 
Java_scurses_RawCurses_reverse(JNIEnv *env, jclass obj, jboolean on)
{
    if (on) {
	attrset(A_REVERSE);
    } else {
	attroff(A_REVERSE);
    }
}

JNIEXPORT void JNICALL 
Java_scurses_RawCurses_beep(JNIEnv *env, jclass obj)
{
    beep();
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyDown(JNIEnv *env, jclass obj)
{
    return KEY_DOWN;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyUp(JNIEnv *env, jclass obj)
{
    return KEY_UP;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyLeft(JNIEnv *env, jclass obj)
{
    return KEY_LEFT;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyRight(JNIEnv *env, jclass obj)
{
    return KEY_RIGHT;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyHome(JNIEnv *env, jclass obj)
{
    return KEY_HOME;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyBackspace(JNIEnv *env, jclass obj)
{
    return KEY_BACKSPACE;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyDC(JNIEnv *env, jclass obj)
{
    return KEY_DC;
}

JNIEXPORT jint JNICALL 
Java_scurses_RawCurses_getKeyIC(JNIEnv *env, jclass obj)
{
    return KEY_IC;
}



