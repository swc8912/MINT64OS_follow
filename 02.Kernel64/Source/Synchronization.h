#ifndef __SYNCHRONIZATION_H__
#define __SYNCHRONIZATION_H__

#include "Types.h"

#pragma pack(push, 1)

// 뮤텍스 자료구조 volatile로 메모리에 놔두게 함
typedef struct kMutexStruct
{
    // 태스크 ID와 잠금을 수행한 횟수
    volatile QWORD qwTaskID;
    volatile DWORD dwLockCount;

    // 잠금 플래그
    volatile BOOL bLockFlag;

    // 자료구조의 크기를 8바이트 단위로 맞추려고 추가한 필드
    BYTE vbPadding[3];
} MUTEX;

#pragma pack(pop)

BOOL kLockForSystemData(void);
void kUnlockForSystemData(BOOL bInterruptFlag);

void kInitializeMutex(MUTEX* pstMutex);
void kLock(MUTEX* pstMutex);
void kUnlock(MUTEX* pstMutex);

#endif
