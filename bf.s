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

;BF Bájtkód értelmezése:
;   1 bájt = 2 utasítás, alsó és felsõ 4-4 bit alapján
;   Végrehajtás sorrendje: felsõ 4, alsó 4, felsõ 4, alsó 4 ...
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

LOOPSTACK:                                                          ;Elágazások elejét tároló verem, max 8-as mélységig
    DB  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF              
PRINT:                                                              ;Kiírt karakterek, max 8 db
    DB  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF              
DATAS:                                                              ;Adatszalag, 16 B
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00         
BF:                                                                 ;Brainfuck kód
    ;DB  0x33, 0x33, 0x57, 0x46, 0x00
    db  "++++[.-]", 0

;REGISZTER SZEREPEK:
;   r0: Programkód pointer
;   r1: Aktuális programutasítást tároló regiszter
;   r2: Adat pointer
;   r3: Elágazás veremmutató, az utolsó tárolt adat UTÁNRA mutat
;   r4: Bájtmaszk, 
;   r5: temporáris tároló
;   r15: A "Print" memóriaterület mutatója


CODE
    MOV r0, #BF         ;Program pointer init
    MOV r2, #DATAS      ;Adat pointer init
    MOV r3, #LOOPSTACK  ;Elágazás verem pointer init
    MOV r4, #0x0F       ;Bájtmaszk
    MOV r15, #PRINT     ;Print mutató init
    
main_loop:              ;A kódon végiglépkedõ loop eleje
    MOV r1, (r0)        ;Aktuális programutasítás beolvasása
get_instruction:
    ;SWP r4              ;Maszk megforgatása
    ;AND r1, r4          ;Aktuális utasítás bájtkódjának maszkolása
    ;CMP r4, #0xF0       ;Ha a felsõ 4 bitet tartjuk meg
    ;JZ swap_instr       ;Felcseréljük az alsó-felsõ biteket
    ;                    ;Különben az alsó 4 bitet tartottuk meg, nincs további teendõ
    CMP r1, #0          ;Ha '0', akkor vége a kódnak
    JZ endcode          ;Ugrás a végére
code_interpret:
    CMP r1, #0x3E       ;Ha '>' karaktert talál
    JZ inc_data_pointer ;Növeli az adatmutatót
    CMP r1, #0x3C       ;Ha '<' karaktert talál
    JZ dec_data_pointer ;Csökkenti az adatmutatót
    CMP r1, #0x2B       ;Ha '+' karaktert talál
    JZ inc_data         ;Növeli a mutatott adatot
    CMP r1, #0x2D       ;Ha '-' karaktert talál
    JZ dec_data         ;Csökkenti a mutatott adatot   
    CMP r1, #0x5B       ;Ha '[' karaktert talál
    JZ loop_start       ;Eldönti, mi a teendõ
    CMP r1, #0x5D       ;Ha ']' karaktert talál
    JZ loop_end         ;A verem tetején lévõ pozícióba ugrik       
    CMP r1, #0x2E       ;Ha '.' karaktert talál
    JZ print_data       ;Az r15 regiszterbe írja az aktuális adatot
main_loop_end:
    CMP r4, #0x0F       ;Ha az alsó 4 bit volt megtartva, csak akkor kell növelni az utasításmutatót
    JNZ main_loop
    ADD r0, #1          ;Programmutató inkrement
    JMP main_loop       ;Vissza a beolvasáshoz

swap_instr:
    SWP r1              ;alsó-felsõ 4 bit cseréje
    JMP code_interpret  ;ugrás a kódértelmezéshez

inc_data_pointer:       
    ADD r2, #1          ;Adatmutató növelése
    JMP main_loop_end   ;Ugrás a fõciklus végére    
dec_data_pointer:
    SUB r2, #1          ;Adatmutató csökkentése
    JMP main_loop_end   ;Ugrás a fõciklus végére
    
inc_data:
    MOV r5, (r2)        ;Aktuális adatérték kiolvasása
    ADD r5, #1          ;Növelés   
    MOV (r2), r5        ;Visszaírás
    JMP main_loop_end   ;Ugrás a fõciklus végére    
dec_data:
    MOV r5, (r2)        ;Aktuális adatérték kiolvasása
    SUB r5, #1          ;Csökkentés
    MOV (r2), r5        ;Visszaírás
    JMP main_loop_end   ;Ugrás a fõciklus végére

loop_end:
    SUB r3, #1          ;"Kivesszük" a verembõl az értéket
    MOV r0, (r3)        ;A programmutatót a verem tetején lévõ elem értékére állítjuk, azaz a végrehajtás a ciklus elejére kerül
    SUB r0, #1          ;Csökkentjük eggyel a programmutatót, mert a fõciklus végén ismételten növelésre kerül
    JMP main_loop_end   ;Ugrás a fõciklus végére

loop_start:
    MOV r5, (r2)        ;Aktuális adatérték kiolvasása
    CMP r5, #0          ;Ha az nulla, átugorjuk a ciklust
    JZ seek_end         ;Ha nulla, megkeressük a hozzá tartozó ']' elemet
    MOV (r3), r0        ;Ha nem nulla, betesszük a helyét a verembe, és megyünk a következõ utasításra
    ADD r3, #1          ;A veremmutatót növeljük
    JMP main_loop_end   ;Ugrás a fõciklus végére

seek_end:
    MOV r5, #1          ;Mélységet 1-re inicializáljuk
seek_loop:
    CMP r5, #0          ;Ha a mélység 0
    JZ main_loop_end    ;Ugrás a fõciklus végére
    ADD r0, #1          ;Léptetjük a program pointert
    MOV r1, (r0)        ;Beolvassuk az aktuális utasítást
    CMP r1, #0x5B       ;Ha '[' karaktert talál, a mélységet egyel növeljük
    JZ inc_depth
    CMP r1, #0x5D       ;Ha ']' karaktert talál, a mélységet egyel csökkentjük
    JZ dec_depth
    JMP seek_loop       ;Egyéb esetben a keresõciklus elejére lépünk

inc_depth:
    ADD r5, #1          ;Mélység növelése eggyel
    JMP seek_loop
dec_depth:
    SUB r5, #1          ;Mélység csökkentése eggyel
    JMP seek_loop

print_data:
    MOV r5, (r2)       ;Az r5-ös regiszterbe teszi az aktuális adatot
    MOV (r15), r5      ;A regiszter értékét "kiírja"
    ADD r15, #1
    jmp main_loop_end

endcode:
    MOV r1, #0xFF   