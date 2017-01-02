;   |	00	01	02	03	04	05	06	07	|	08	09	0A	0B	0C	0D	0E	0F
;---------------------------------------------------------------------------	
;00	|	S	S	S	S	S	S	S	S	|	P	P	P	P	P	P	P	P
;10	|	D	D	D	D	D	D	D	D	|	D	D	D	D	D	D	D	D
;20	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C
;30	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C
;40	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C
;50	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C
;60	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C
;70	|	C	C	C	C	C	C	C	C	|	C	C	C	C	C	C	C	C

;0x00 - 0x07 (8 B): Stack
;0x08 - 0x0F (8 B): Print
;0x10 - 0x11 (16 B): Data
;0x20 - 0x7F (96 B): Code

;BF B�jtk�d �rtelmez�se:
;   1 b�jt = 2 utas�t�s, als� �s fels� 4-4 bit alapj�n
;   V�grehajt�s sorrendje: fels� 4, als� 4, fels� 4, als� 4 ...
;   0000 - 0xX0 = NOOP
;   0001 - 0xX1 = >
;   0010 - 0xX2 = <
;   0011 - 0xX3 = +
;   0100 - 0xX4 = -
;   0101 - 0xX5 = [
;   0110 - 0xX5 = ]
;   0111 - 0xX6 = .
;   1000 - 0xX7 = ,

DATA

LOOPSTACK:                                                          ;El�gaz�sok elej�t t�rol� verem, max 8-as m�lys�gig
    DB  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF              
PRINT:                                                              ;Ki�rt karakterek, max 8 db
    DB  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF              
DATAS:                                                              ;Adatszalag, 16 B
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00         
BF:                                                                 ;Brainfuck k�d
    ;DB  0x33, 0x33, 0x57, 0x46, 0x00
    db  "++++[.-]", 0

;REGISZTER SZEREPEK:
;   r0: Programk�d pointer
;   r1: Aktu�lis programutas�t�st t�rol� regiszter
;   r2: Adat pointer
;   r3: El�gaz�s veremmutat�, az utols� t�rolt adat UT�NRA mutat
;   r4: B�jtmaszk, 
;   r5: tempor�ris t�rol�
;   r15: A "Print" mem�riater�let mutat�ja


CODE
    MOV r0, #BF         ;Program pointer init
    MOV r2, #DATAS      ;Adat pointer init
    MOV r3, #LOOPSTACK  ;El�gaz�s verem pointer init
    MOV r4, #0x0F       ;B�jtmaszk
    MOV r15, #PRINT     ;Print mutat� init
    
main_loop:              ;A k�don v�gigl�pked� loop eleje
    MOV r1, (r0)        ;Aktu�lis programutas�t�s beolvas�sa
get_instruction:
    ;SWP r4              ;Maszk megforgat�sa
    ;AND r1, r4          ;Aktu�lis utas�t�s b�jtk�dj�nak maszkol�sa
    ;CMP r4, #0xF0       ;Ha a fels� 4 bitet tartjuk meg
    ;JZ swap_instr       ;Felcser�lj�k az als�-fels� biteket
    ;                    ;K�l�nben az als� 4 bitet tartottuk meg, nincs tov�bbi teend�
    CMP r1, #0          ;Ha '0', akkor v�ge a k�dnak
    JZ endcode          ;Ugr�s a v�g�re
code_interpret:
    CMP r1, #0x3E       ;Ha '>' karaktert tal�l
    JZ inc_data_pointer ;N�veli az adatmutat�t
    CMP r1, #0x3C       ;Ha '<' karaktert tal�l
    JZ dec_data_pointer ;Cs�kkenti az adatmutat�t
    CMP r1, #0x2B       ;Ha '+' karaktert tal�l
    JZ inc_data         ;N�veli a mutatott adatot
    CMP r1, #0x2D       ;Ha '-' karaktert tal�l
    JZ dec_data         ;Cs�kkenti a mutatott adatot   
    CMP r1, #0x5B       ;Ha '[' karaktert tal�l
    JZ loop_start       ;Eld�nti, mi a teend�
    CMP r1, #0x5D       ;Ha ']' karaktert tal�l
    JZ loop_end         ;A verem tetej�n l�v� poz�ci�ba ugrik       
    CMP r1, #0x2E       ;Ha '.' karaktert tal�l
    JZ print_data       ;Az r15 regiszterbe �rja az aktu�lis adatot
main_loop_end:
    CMP r4, #0x0F       ;Ha az als� 4 bit volt megtartva, csak akkor kell n�velni az utas�t�smutat�t
    JNZ main_loop
    ADD r0, #1          ;Programmutat� inkrement
    JMP main_loop       ;Vissza a beolvas�shoz

swap_instr:
    SWP r1              ;als�-fels� 4 bit cser�je
    JMP code_interpret  ;ugr�s a k�d�rtelmez�shez

inc_data_pointer:       
    ADD r2, #1          ;Adatmutat� n�vel�se
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re    
dec_data_pointer:
    SUB r2, #1          ;Adatmutat� cs�kkent�se
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re
    
inc_data:
    MOV r5, (r2)        ;Aktu�lis adat�rt�k kiolvas�sa
    ADD r5, #1          ;N�vel�s   
    MOV (r2), r5        ;Vissza�r�s
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re    
dec_data:
    MOV r5, (r2)        ;Aktu�lis adat�rt�k kiolvas�sa
    SUB r5, #1          ;Cs�kkent�s
    MOV (r2), r5        ;Vissza�r�s
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re

loop_end:
    SUB r3, #1          ;"Kivessz�k" a veremb�l az �rt�ket
    MOV r0, (r3)        ;A programmutat�t a verem tetej�n l�v� elem �rt�k�re �ll�tjuk, azaz a v�grehajt�s a ciklus elej�re ker�l
    SUB r0, #1          ;Cs�kkentj�k eggyel a programmutat�t, mert a f�ciklus v�g�n ism�telten n�vel�sre ker�l
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re

loop_start:
    MOV r5, (r2)        ;Aktu�lis adat�rt�k kiolvas�sa
    CMP r5, #0          ;Ha az nulla, �tugorjuk a ciklust
    JZ seek_end         ;Ha nulla, megkeress�k a hozz� tartoz� ']' elemet
    MOV (r3), r0        ;Ha nem nulla, betessz�k a hely�t a verembe, �s megy�nk a k�vetkez� utas�t�sra
    ADD r3, #1          ;A veremmutat�t n�velj�k
    JMP main_loop_end   ;Ugr�s a f�ciklus v�g�re

seek_end:
    MOV r5, #1          ;M�lys�get 1-re inicializ�ljuk
seek_loop:
    CMP r5, #0          ;Ha a m�lys�g 0
    JZ main_loop_end    ;Ugr�s a f�ciklus v�g�re
    ADD r0, #1          ;L�ptetj�k a program pointert
    MOV r1, (r0)        ;Beolvassuk az aktu�lis utas�t�st
    CMP r1, #0x5B       ;Ha '[' karaktert tal�l, a m�lys�get egyel n�velj�k
    JZ inc_depth
    CMP r1, #0x5D       ;Ha ']' karaktert tal�l, a m�lys�get egyel cs�kkentj�k
    JZ dec_depth
    JMP seek_loop       ;Egy�b esetben a keres�ciklus elej�re l�p�nk

inc_depth:
    ADD r5, #1          ;M�lys�g n�vel�se eggyel
    JMP seek_loop
dec_depth:
    SUB r5, #1          ;M�lys�g cs�kkent�se eggyel
    JMP seek_loop

print_data:
    MOV r5, (r2)       ;Az r5-�s regiszterbe teszi az aktu�lis adatot
    MOV (r15), r5      ;A regiszter �rt�k�t "ki�rja"
    ADD r15, #1
    jmp main_loop_end

endcode:
    MOV r1, #0xFF   