/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class scurses_RawCurses */

#ifndef _Included_scurses_RawCurses
#define _Included_scurses_RawCurses
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     scurses_RawCurses
 * Method:    init
 * Signature: ()Z
 */
JNIEXPORT jboolean JNICALL Java_scurses_RawCurses_init
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    endwin
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_scurses_RawCurses_endwin
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    refresh
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_refresh
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getmaxx
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getmaxx
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getmaxy
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getmaxy
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    clearok
 * Signature: (Z)V
 */
JNIEXPORT void JNICALL Java_scurses_RawCurses_clearok
  (JNIEnv *, jclass, jboolean);

/*
 * Class:     scurses_RawCurses
 * Method:    clear
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_clear
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    addch
 * Signature: (C)I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_addch
  (JNIEnv *, jclass, jchar);

/*
 * Class:     scurses_RawCurses
 * Method:    getch
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getch
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    move
 * Signature: (II)V
 */
JNIEXPORT void JNICALL Java_scurses_RawCurses_move
  (JNIEnv *, jclass, jint, jint);

/*
 * Class:     scurses_RawCurses
 * Method:    reverse
 * Signature: (Z)V
 */
JNIEXPORT void JNICALL Java_scurses_RawCurses_reverse
  (JNIEnv *, jclass, jboolean);

/*
 * Class:     scurses_RawCurses
 * Method:    beep
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_scurses_RawCurses_beep
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyDown
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyDown
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyUp
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyUp
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyLeft
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyLeft
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyRight
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyRight
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyHome
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyHome
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyBackspace
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyBackspace
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyDC
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyDC
  (JNIEnv *, jclass);

/*
 * Class:     scurses_RawCurses
 * Method:    getKeyIC
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_scurses_RawCurses_getKeyIC
  (JNIEnv *, jclass);

#ifdef __cplusplus
}
#endif
#endif
