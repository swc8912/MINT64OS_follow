[ORG 0x00]		; 코드의 시작 어드레스를 0x00으로 설정
[BITS 16]		; 이하의 코드는 16비트 코드로 설정

SECTION .text	; text 섹션(세그먼트)을 정의

jmp 0x07C0:START	; CS세그먼트 레지스터에 0x07C0을 복사하면서 START 레이블로 이동

; OS 관련된 환경 설정 값
TOTALSECTORCOUNT:	dw 0x02		; 부트 로더를 제외한 OS 이미지의 크기, 최대 1152 섹터(0x90000byte)까지 가능

; 코드 영역
START:
	mov ax, 0x07C0	; 부트 로더의 시작 어드레스(0x07C0)를 세그먼트 레지스터 값으로 변환
	mov ds, ax		; DS 세그먼트 레지스터에 설정
	mov ax, 0xB800	; 비디오 메모리의 시작 어드레스(0xB800)를 세그먼트 레지스터 값으로 변환
	mov es, ax		; ES 세그먼트 레지스터에 설정

	; 스택을 0x0000:0000~0x0000:FFFF 영역에 64kb 크기로 설정
	mov ax, 0x0000	; 스택 세그먼트의 시작 어드레스(0x0000)를 세그먼트 레지스터 값으로 변환
	mov ss, ax		; SS 세그먼트 레지스터에 설정
	mov sp, 0xFFFE	; SP 레지스터의 어드레스를 0xFFFe로 설정
	mov bp, 0xFFFE	; BP 레지스터의 어드레스를 0xFFFe로 설정

	; 화면을 모두 지우고 속성값을 녹색으로 설정
	mov si, 0	; SI 레지스터(문자열 원본 인덱스 레지스터)를 초기화

.SCREENCLEARLOOP:	; 화면을 지우는 루프
	mov byte[es:si], 0	; 비디오 메모리의 문자가 위치하는 어드레스에 0을 복사하여 문자를 삭제
	mov byte[es:si+1], 0x0A	; 비디오 메모리의 속성이 위치하는 어드레스에 0x0A(검은 바탕에 밝은 녹색)을 복사

	add si, 2	; 문자와 속성을 설정했으므로 다음 위치로 이동

	cmp si, 80*25*2	; 화면의 전체 크기는 80문자 * 25 라인임, 출력한 문자의 수를 의미하는 SI레지스터와 비교

	jl .SCREENCLEARLOOP ; SI 레지스터가 80*25*2보다 작다면 아직 지우지 못한 영역이 있으므로 .SCREENCLEARLOOP로 이동

	; 화면 상단에 시작 메세지 출력
	push MESSAGE1	; 출력할 메세지의 어드레스를 스택에 삽입
	push 0	; 화면 Y좌표(0)를 스택에 삽입
	push 0	; 화면 X좌표(0)를 스택에 삽입
	call PRINTMESSAGE	; PRINTMESSAGE 함수 호출
	add sp, 6	; 삽입한 파라미터 제거

	; OS 이미지를 로딩한다는 메시지 출력
	push IMAGELOADINGMESSAGE	; 출력할 메세지의 어드레스를 스택에 삽입
	push 1	; 화면 Y좌표(1)를 스택에 삽입
	push 0	; 화면 X좌표(0)를 스택에 삽입
	call PRINTMESSAGE	; PRINTMESSAGE 함수 호출
	add sp, 6	; 삽입한 파라미터 제거

	; 디스크에서 OS 이미지를 로딩
	; 디스크를 읽기 전에 먼저 리셋
RESETDISK:	; 디스크를 리셋하는 코드의 시작
	; BIOS Reset Function 호출
	; 서비스 번호 0, 드라이브 번호(0=Floppy)
	mov ax, 0
	mov dl, 0
	int 0x13
	; 에러가 발생하면 에러 처리로 이동
	jc HANDLEDISKERROR

	; 디스크에서 섹터를 읽음
	; 디스크의 내용을 메모리로 복사할 어드레스(ES:BX)를 0x10000으로 설정
	mov si, 0x1000	; OS 이미지를 복사할 어드레스(0x10000)를 세그먼트 레지스터 값으로 변환
	mov es, si	; ES 세그먼트 레지스터에 값 설정
	mov bx, 0x0000	; BX 레지스터에 0x0000을 설정하여 복사할 어드레스를 0x1000:0000(0x10000)으로 최종 설정

	mov di, word[TOTALSECTORCOUNT]	; 복사할 OS 이미지의 섹터 수를 DI 레지스터에 설정

READDATA:
	; 모든 섹터를 다 읽었는지 확인
	cmp di, 0	; 복사할 OS 이미지의 섹터 수를 0과 비교
	je READEND	; 복사할 섹터 수가 0이라면 다 복사 했으므로 READEND로 이동
	sub di, 0x1	; 복사할 섹터 수를 1감소

	; BIOS Read Function 호출
	mov ah, 0x02	; BIOS 서비스 번호 2(Read Sector)
	mov al, 0x1		; 읽을 섹터 수는 1
	mov ch, byte[TRACKNUMBER]	; 읽을 트랙 번호 설정
	mov cl, byte[SECTORNUMBER]	; 읽을 섹터 번호 설정
	mov dh, byte[HEADNUMBER]	; 읽을 헤드 번호 설정
	mov dl, 0x00	; 읽을 드라이브 번호(0=Floppy) 설정
	int 0x13		; 인터럽트 서비스 수행
	jc HANDLEDISKERROR	; 에러가 발생했다면 HANDLEDISKERROR로 이동

	; 복사할 어드레스와 트랙, 헤드, 섹터 어드레스 계산
	add si, 0x0020	; 512(0x200)바이트 만큼 읽었으므로, 이를 세그먼트 레지스터 값으로 변환
	mov es, si		; ES 세그먼트 레지스터에 더해서 어드레스를 한 섹터 만큼 증가

	; 한 섹터를 읽었으므로 섹터 번호를 증가시키고 마지막 섹터(18)까지 읽었는지 판단
	; 마지막 섹터가 아니면 섹터 읽기로 진행해서 다시 섹터 읽기 수행
	mov al, byte[SECTORNUMBER]	; 섹터 번호를 AL 레지스터에 설정
	add al, 0x01				; 섹터 번호를 1 증가
	mov byte[SECTORNUMBER], al	; 증가시킨 섹터 번호를 SECTORNUMBER에 다시 설정
	cmp al, 19	; 19와 섹터 번호 비교
	jl READDATA	; 섹터 번호가 19 미만이면 READDATA로 이동

	; 마지막 섹터까지 읽었으면(섹터 번호가 19이면) 헤드를 토글(0->1, 1->0)하고 섹터 번호를 1로 설정
	xor byte[HEADNUMBER], 0x01	; 헤드번호를 0x01과 xor하여 토글
	mov byte[SECTORNUMBER], 0x01	; 섹터번호를 1로 설정

	; 만약 헤드가 1->0으로 바뀌었으면 양쪽 헤드를 모두 읽은 것이므로 아래로 이동하여 트랙 번호를 1증가
	cmp byte[HEADNUMBER], 0x00
	jne READDATA	; 헤드 번호가 0이 아니면 READDATA로 이동

	; 트랙을 1 증가시킨 후 다시 섹터 읽기로 이동
	add byte[TRACKNUMBER], 0x01	; 트랙 번호를 1증가
	jmp READDATA

READEND:
	; OS 이미지가 완료되었다는 메세지 출력
	push LOADINGCOMPLETEMESSAGE	; 출력할 메세지의 어드레스를 스택에 삽입
	push 1	; 화면의 Y좌표(1)를 스택에 삽입
	push 20	; 화면의 X좌표(20)를 스택에 삽입
	call PRINTMESSAGE
	add sp, 6 ; 삽입한 파라미터 제거 3*2

	; 로딩한 가상 OS이미지 실행
	jmp 0x1000:0x0000

; 함수 코드 영역

; 디스크 에러 처리함수
HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1	; 화면의 Y좌표(1)를 스택에 삽입
	push 20	; 화면의 X좌표(20)를 스택에 삽입
	call PRINTMESSAGE

	jmp $	; 현재 위치에서 무한 루프

; 메세지 출력 함수 PARAM: x좌표, y좌표, 문자열
PRINTMESSAGE:
	push bp	; 베이스 포인트 레지스터 스택에 삽입
	mov bp, sp	; 베이스 포인트 레지스터에 스태 포인트 레지스터 삽입, bp로 파라미터에 접근 목적

	push es	; ES 세그먼트 레지스터부터 DX 레지스터까지 스택에 삽입
	push si	; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서 스택에 삽입된 값을 꺼내 원래 값으로 복원
	push di
	push ax
	push cx
	push dx

	; ES 세그먼트 레지스터에 비디오 모드 어드레스 설정
	mov ax, 0xB800	; 비디오 메모리 시작 어드레스(0x0B8000)를 세그먼트 레지스터 값으로 변환
	mov es, ax	; ES 세그먼트 레지스터에 설정

	; X, Y의 좌표로 비디오 메모리의 어드레스를 계산함
	; Y좌표를 이용해서 먼저 라인 어드레스를 구함
	mov ax, word[bp+6]	; 파라미터 2(화면 좌표 Y)를 AX 레지스터에 설정
	mov si, 160	; 한 라인의 바이트 수(2*80 컬럼)를 SI 레지스터에 설정
	mul si	; AX 레지스터와 SI 레지스터를 곱하여 화면 Y어드레스 계산
	mov di, ax

	; X좌표를 이용해서 2를 곱한 후 최종 어드레스를 구함
	mov ax, word[bp+4]	; 파라미터 1(화면 좌표 X)를 AX 레지스터에 설정
	mov si, 2	; 한 문자를 나타내는 바이트 수(2)를 SI 레지스터에 설정
	mul si	; AX 레지스터와 SI 레지스터를 곱하여 화면 X어드레스 계산
	add di, ax	; 화면 Y어드레스와 계산된 X어드레스를 더해서 실제 비디오 메모리 어드레스를 계산

	; 출력할 문자열의 어드레스
	mov si, word[bp+8]	; 파라미터 3(출력할 문자열의 어드레스)

.MESSAGELOOP:	; 메세지 출력하는 루프
	mov cl, byte[si]	; SI 레지스터가 가리키는 문자열 위치에서 한 문자를 CL 레지스터에 복사
						; CL 레지스터는 CX 레지스터의 하위 1바이트를 의미 16비트에선 레지스터 크기가 2바이트
						; 문자열은 1바이트면 충분하므로 CX 레지스터의 하위 1바이트만 사용

	cmp cl, 0	; 복사된 문자와 0을 비교
	je .MESSAGEEND	; 복사한 문자의 값이 0이면 문자열이 종료됨을 의미하므로 .MESSAGEEND로 이동하여 문자 출력 종료

	mov byte[es:di], cl	; 0이 아니라면 비디오 메모리 어드레스 0xB800:di에 문자를 출력

	add si, 1	; SI 레지스터에 1을 더해서 다음 문자열로 이동
	add di, 2	; DI 레지스터에 2를 더해서 비디오 메모리의 다음 문자 위치로 이동, 비디오 메모리는(문자, 속성)의 쌍으로 구성되서
				; 문자만 출력하려면 2를 더해야함

	jmp .MESSAGELOOP	; 메세지 출력 루프로 이동하여 다음 문자를 출력

.MESSAGEEND:
	pop dx	; 함수에서 사용이 끝난 DX 레지스터부터 ES 레지스터를 스택에 삽입된 값을 이용해서 복원
	pop cx	; 스택은 가장 마지막에 들어간 데이터가 가장 먼저 나오는 자료구조로 삽입의 역순으로 제거해야함
	pop ax
	pop di
	pop si
	pop es
	pop bp	; 베이스 포인터 레지스터 복원
	ret	; 함수를 호출한 다음 코드의 위치로 복귀

; 데이터 영역

; 부트 로더 시작 메세지
MESSAGE1:	db 'MINT64 OS Boot Loader Start!', 0	; 출력할 메세지 정의, 마지막은 0으로 설정하여
													; MESSAGELOOP에서 문자열 종료를 알 수 있게 함

DISKERRORMESSAGE:	db 'DISK error!!', 0
IMAGELOADINGMESSAGE:	db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db 'Complete!', 0

; 디스크 읽기에 관련된 변수들
SECTORNUMBER:	db 0x02	; OS 이미지가 시작하는 섹터 번호 저장
HEADNUMBER:	db 0x00 ; OS 이미지가 시작하는 헤드 번호 저장
TRACKNUMBER:	db 0x00 ; OS 이미지가 시작하는 트랙 번호 저장

times 510 - ( $ - $$ )	db	0x00	; $: 현재 라인의 어드레스
									; $$: 현재 섹션(.text)의 시작 어드레스
									; $-$$: 현재 섹션을 기준으로 하는 오프셋
									; 510 - ( $ - $$ ): 현재부터 어드레스 510까지
									; db 0x00; 1바이트를 선언하고 값은 0x00
									; times: 반복 수행
									; 현재 위치부터 어드레스 510까지 0x00으로 채움

db 0x55	; 1바이트를 선언하고 값 0x55
db 0xAA ; 1바이트를 선언하고 값 0xAA
		; 어드레스 511, 512에 0x55, 0xAA를 써서 부트 섹터로 인식하게 함
