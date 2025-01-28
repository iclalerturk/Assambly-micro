        ; -----------------------------------------------------------------------
        ; Okunan işaretli iki sayının toplamını hesaplayıp ekrana yazdırır.
        ; ANA 		: Ana yordam 
        ; PUT_STR 	: Ekrana sonu 0 ile belirlenmiş dizgeyi yazdırır. 
        ; PUTC 	: AL deki karakteri ekrana yazdırır. 
        ; GETC 	: Klavyeden basılan karakteri AL’ye alır.
        ; PUTN 	: AX’deki sayeyi ekrana yazdırır. 
        ; GETN 	: Klavyeden okunan sayeyi AX’e koyar
        ; -----------------------------------------------------------------------
SSEG 	SEGMENT PARA STACK 'STACK'
	DW 80 DUP (?)
SSEG 	ENDS

DSEG	SEGMENT PARA 'DATA'
SAYILAR    DB 10 DUP (?)
N   DW ?
MOD_DEG   DW ?
KOPYASAYILAR DW 10 DUP (?)
CR	EQU 13
LF	EQU 10
MSG1	DB 'n degerini giriniz (0-10arasi olsun): ',0
MSG2	DB CR, LF, 'elemanlari girin(0-10arasinda olsun): ', 0
HATA	DB CR, LF, 'Dikkat !!! Sayi vermediniz yeniden giris yapiniz.!!!  ', 0
SONUC	DB CR, LF, 'Toplam ', 0
SAYI1	DW ?
SAYI2	DW ?
DSEG 	ENDS 

CSEG 	SEGMENT PARA 'CODE'
	ASSUME CS:CSEG, DS:DSEG, SS:SSEG

GIRIS_DIZI MACRO SAYILAR, N
        LOCAL DONGU
        MOV AX, OFFSET MSG1
        CALL PUT_STR ; MSG1’i göster 
        CALL GETN ; N’i oku 
        MOV N, AX
        MOV AX, OFFSET MSG2
        CALL PUT_STR ; MSG2’i göster 
        XOR SI, SI
DONGU:  CALL GETN ; SAYILAR’i oku 
        PUSH AX  ;BURDA PROBLEM OLABİLİYO
        MOV SAYILAR[SI], AL   ;DIZIYE AT    
        INC SI
        CMP SI, N
        JB DONGU
        PUSH N
        ENDM

MY_MOD PROC NEAR
        MOV BP, SP ;STACK POINTER I TUT
        MOV CX,[BP+2] ;N I TUT
        XOR SI, SI
        ADD BP,2
KOPYALA:ADD BP,2 ; SAYILAR DIZISINDEKI ELEMANLARI KOPYALAMAK ICIN
        MOV BX, [BP]
        MOV KOPYASAYILAR[SI], BX
        ADD SI,2
        LOOP KOPYALA
        ;MOD BULMA KISIMI
        MOV BP,SP
        MOV CX, [BP+2] ;N I TUT
        SHL CX, 1 ;N*2 WORD OLDUGU ICIN
        MOV AH, 0 ;MAXCOUNT        
        XOR SI, SI
        MOV BX, KOPYASAYILAR[SI]
        MOV MOD_DEG, BX
DIS:    MOV AL, 0 ;COUNT
        XOR DI, DI
        MOV BX, KOPYASAYILAR[SI]
IC:     CMP BX, KOPYASAYILAR[DI]
        JNE ICDEVAM
        INC AL
ICDEVAM:ADD DI,2
        CMP DI, CX
        JNE IC
        ADD SI,2
        CMP AL,AH  ;COUNT MAXCOUNTTAN BUYUKMU    
        JBE DISICIN
        MOV AH, AL
        MOV MOD_DEG, BX
DISICIN:CMP SI, CX
        JNE DIS       
        RET
MY_MOD ENDP


ANA 	PROC FAR
        PUSH DS
        XOR AX,AX
        PUSH AX
        MOV AX, DSEG 
        MOV DS, AX
	
        GIRIS_DIZI SAYILAR, N
        CALL MY_MOD

        MOV CX, [BP+2]
        POP AX
BOSALT: POP AX
        LOOP BOSALT
        
        RETF 
ANA 	ENDP

GETC	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan karakteri AL yazmacına alır ve ekranda gösterir. 
        ; işlem sonucunda sadece AL etkilenir. 
        ;------------------------------------------------------------------------
        MOV AH, 1h
        INT 21H
        RET 
GETC	ENDP 

PUTC	PROC NEAR
        ;------------------------------------------------------------------------
        ; AL yazmacındaki değeri ekranda gösterir. DL ve AH değişiyor. AX ve DX 
        ; yazmaçlarının değerleri korumak için PUSH/POP yapılır. 
        ;------------------------------------------------------------------------
        PUSH AX
        PUSH DX
        MOV DL, AL
        MOV AH,2
        INT 21H
        POP DX
        POP AX
        RET 
PUTC 	ENDP 

GETN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan sayiyi okur, sonucu AX yazmacı üzerinden dondurur. 
        ; DX: sayının işaretli olup/olmadığını belirler. 1 (+), -1 (-) demek 
        ; BL: hane bilgisini tutar 
        ; CX: okunan sayının islenmesi sırasındaki ara değeri tutar. 
        ; AL: klavyeden okunan karakteri tutar (ASCII)
        ; AX zaten dönüş değeri olarak değişmek durumundadır. Ancak diğer 
        ; yazmaçların önceki değerleri korunmalıdır. 
        ;------------------------------------------------------------------------
        PUSH BX
        PUSH CX
        PUSH DX
GETN_START:
        MOV DX, 1	                        ; sayının şimdilik + olduğunu varsayalım 
        XOR BX, BX 	                        ; okuma yapmadı Hane 0 olur. 
        XOR CX,CX	                        ; ara toplam değeri de 0’dır. 
NEW:
        CALL GETC	                        ; klavyeden ilk değeri AL’ye oku. 
        CMP AL,CR 
        JE FIN_READ	                        ; Enter tuşuna basilmiş ise okuma biter
        CMP  AL, '-'	                        ; AL ,'-' mi geldi ? 
        JNE  CTRL_NUM	                        ; gelen 0-9 arasında bir sayı mı?
NEGATIVE:
        MOV DX, -1	                        ; - basıldı ise sayı negatif, DX=-1 olur
        JMP NEW		                        ; yeni haneyi al
CTRL_NUM:
        CMP AL, '0'	                        ; sayının 0-9 arasında olduğunu kontrol et.
        JB error 
        CMP AL, '9'
        JA error		                ; değil ise HATA mesajı verilecek
        SUB AL,'0'	                        ; rakam alındı, haneyi toplama dâhil et 
        MOV BL, AL	                        ; BL’ye okunan haneyi koy 
        MOV AX, 10 	                        ; Haneyi eklerken *10 yapılacak 
        PUSH DX		                        ; MUL komutu DX’i bozar işaret için saklanmalı
        MUL CX		                        ; DX:AX = AX * CX
        POP DX		                        ; işareti geri al 
        MOV CX, AX	                        ; CX deki ara değer *10 yapıldı 
        ADD CX, BX 	                        ; okunan haneyi ara değere ekle 
        JMP NEW 		                ; klavyeden yeni basılan değeri al 
ERROR:
        MOV AX, OFFSET HATA 
        CALL PUT_STR	                        ; HATA mesajını göster 
        JMP GETN_START                          ; o ana kadar okunanları unut yeniden sayı almaya başla 
FIN_READ:
        MOV AX, CX	                        ; sonuç AX üzerinden dönecek 
        CMP DX, 1	                        ; İşarete göre sayıyı ayarlamak lazım 
        JE FIN_GETN
        NEG AX		                        ; AX = -AX
FIN_GETN:
        POP DX
        POP CX
        POP DX
        RET 
GETN 	ENDP 

PUTN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de bulunan sayiyi onluk tabanda hane hane yazdırır. 
        ; CX: haneleri 10’a bölerek bulacağız, CX=10 olacak
        ; DX: 32 bölmede işleme dâhil olacak. Soncu etkilemesin diye 0 olmalı 
        ;------------------------------------------------------------------------
        PUSH CX
        PUSH DX 	
        XOR DX,	DX 	                        ; DX 32 bit bölmede soncu etkilemesin diye 0 olmalı 
        PUSH DX		                        ; haneleri ASCII karakter olarak yığında saklayacağız.
                                                ; Kaç haneyi alacağımızı bilmediğimiz için yığına 0 
                                                ; değeri koyup onu alana kadar devam edelim.
        MOV CX, 10	                        ; CX = 10
        CMP AX, 0
        JGE CALC_DIGITS	
        NEG AX 		                        ; sayı negatif ise AX pozitif yapılır. 
        PUSH AX		                        ; AX sakla 
        MOV AL, '-'	                        ; işareti ekrana yazdır. 
        CALL PUTC
        POP AX		                        ; AX’i geri al 
        
CALC_DIGITS:
        DIV CX  		                ; DX:AX = AX/CX  AX = bölüm DX = kalan 
        ADD DX, '0'	                        ; kalan değerini ASCII olarak bul 
        PUSH DX		                        ; yığına sakla 
        XOR DX,DX	                        ; DX = 0
        CMP AX, 0	                        ; bölen 0 kaldı ise sayının işlenmesi bitti demek
        JNE CALC_DIGITS	                        ; işlemi tekrarla 
        
DISP_LOOP:
                                                ; yazılacak tüm haneler yığında. En anlamlı hane üstte 
                                                ; en az anlamlı hane en alta ve onu altında da 
                                                ; sona vardığımızı anlamak için konan 0 değeri var. 
        POP AX		                        ; sırayla değerleri yığından alalım
        CMP AX, 0 	                        ; AX=0 olursa sona geldik demek 
        JE END_DISP_LOOP 
        CALL PUTC 	                        ; AL deki ASCII değeri yaz
        JMP DISP_LOOP                           ; işleme devam
        
END_DISP_LOOP:
        POP DX 
        POP CX
        RET
PUTN 	ENDP 

PUT_STR	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de adresi verilen sonunda 0 olan dizgeyi karakter karakter yazdırır.
        ; BX dizgeye indis olarak kullanılır. Önceki değeri saklanmalıdır. 
        ;------------------------------------------------------------------------
	PUSH BX 
        MOV BX,	AX			        ; Adresi BX’e al 
        MOV AL, BYTE PTR [BX]	                ; AL’de ilk karakter var 
PUT_LOOP:   
        CMP AL,0		
        JE  PUT_FIN 			        ; 0 geldi ise dizge sona erdi demek
        CALL PUTC 			        ; AL’deki karakteri ekrana yazar
        INC BX 				        ; bir sonraki karaktere geç
        MOV AL, BYTE PTR [BX]
        JMP PUT_LOOP			        ; yazdırmaya devam 
PUT_FIN:
	POP BX
	RET 
PUT_STR	ENDP

CSEG 	ENDS 
	END ANA
