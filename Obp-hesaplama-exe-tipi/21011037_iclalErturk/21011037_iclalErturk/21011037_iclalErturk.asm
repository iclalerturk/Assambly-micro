myds SEGMENT PARA 'veri'
n DW 4
vize DB 77, 85, 64, 96
final DB 56, 63, 86, 74
obp DB 4 DUP(?)
myds ENDS

myss SEGMENT PARA STACK 'STACK'
    DW 12 DUP(?)
myss ENDS

mycs SEGMENT PARA 'CODE'
    ASSUME CS:mycs, DS:myds, SS:myss
MAIN PROC FAR
    PUSH DS
    XOR AX, AX
    PUSH AX
    MOV AX, myds
    MOV DS, AX
    XOR SI, SI
DONGU:
    ;vize puanı hesapla
    MOV AL, vize[SI]
    MOV BL, 4   
    MUL BL
    MOV BL, 10
    DIV BL
    ;ah i tut
    MOV BH, AH
    MOV obp[SI], AL
    ;final puanı hesapla
    MOV AL, final[SI]
    MOV BL, 6
    MUL BL
    MOV BL, 10
    DIV BL
    ADD AH, BH
    ADD obp[SI], AL
    ;round icin cozumum: tuttugun ahle burdaki ahi topla 5e buyuk esitse 1 ekle 15e buyuk esitse 1 daha ekle
    CMP AH, 15
    JAE ekle
    CMP AH, 5
    JAE ekle2 
    JMP son 
ekle:
    ADD obp[SI],2
    JMP son
ekle2:
    INC obp[SI]
son:
    INC SI
    CMP SI, n
    JNE DONGU
    XOR DI, DI

;bubblesort
siralaDis:   
    XOR SI, SI
siralaIc:
    MOV BX, n
    MOV AL, obp[SI]
    CMP AL, obp[SI+1]
    JAE artir
    XCHG AL, obp[SI]
    XCHG AL, obp[SI+1]
    XCHG AL, obp[SI]
artir:
    INC SI
    SUB BX, DI
    CMP SI, BX
    JB siralaIc
    INC DI
    CMP n, DI
    JNE siralaDis


    RETF
MAIN ENDP
mycs ENDS
    END MAIN