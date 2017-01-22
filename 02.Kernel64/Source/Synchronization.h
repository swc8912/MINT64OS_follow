#ifndef __SYNCHRONIZATION_H__
#define __SYNCHRONIZATION_H__

#include "Types.h"

#pragma pack(push, 1)

// ���ؽ� �ڷᱸ�� volatile�� �޸𸮿� ���ΰ� ��
typedef struct kMutexStruct
{
    // �½�ũ ID�� ����� ������ Ƚ��
    volatile QWORD qwTaskID;
    volatile DWORD dwLockCount;

    // ��� �÷���
    volatile BOOL bLockFlag;

    // �ڷᱸ���� ũ�⸦ 8����Ʈ ������ ���߷��� �߰��� �ʵ�
    BYTE vbPadding[3];
} MUTEX;

#pragma pack(pop)

BOOL kLockForSystemData(void);
void kUnlockForSystemData(BOOL bInterruptFlag);

void kInitializeMutex(MUTEX* pstMutex);
void kLock(MUTEX* pstMutex);
void kUnlock(MUTEX* pstMutex);

#endif
