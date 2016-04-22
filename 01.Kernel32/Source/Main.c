#include "Types.h"

void kPrintString(int iX, int iY, const char* pcString);
BOOL kInitializeKernel64Area(void);

void Main(void)
{
	DWORD i;

	kPrintString(0, 3, "C Language Kernel Started~!!");

	// IA-32e ����� Ŀ�� ������ �ʱ�ȭ
	kInitializeKernel64Area();
	kPrintString(0, 4, "IA-32e Kernel Area Initialization Complete");

	while(1);
}

void kPrintString(int iX, int iY, const char* pcString)
{
	CHARACTER* pstScreen = (CHARACTER*) 0xB8000;
	int i;

	pstScreen += (iY * 80) + iX;
	for(i = 0; pcString[i] != 0; i++)
	{
		pstScreen[i].bCharactor = pcString[i];
	}
}

BOOL kInitializeKernel64Area(void)
{
	DWORD* pdwCurrentAddress;

	// �ʱ�ȭ�� ������ ��巹���� 0x100000(1MB)�� ����
	pdwCurrentAddress = (DWORD*)0x100000;

	// ������ ��巹���� 0x600000(6MB)���� ������ ���鼭 4����Ʈ�� 0���� ä��
	while((DWORD)pdwCurrentAddress<0x600000)
	{
		*pdwCurrentAddress = 0x00;

		// 0���� ������ �� �ٽ� �о��� �� 0�� ������ ������ �ش� ��巹����
		// ����ϴµ� ������ ���� ���̹Ƿ� ���̻� �������� �ʰ� ����
		if(*pdwCurrentAddress != 0)
		{
			return FALSE;
		}

		// ���� ��巹���� �̵�
		pdwCurrentAddress++;
	}

	return TRUE;
}
