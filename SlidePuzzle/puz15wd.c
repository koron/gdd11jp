/**************************************************/
/*   １５パズル/WD用テーブル作成        puz15wd.c */
/*           Computer & Puzzle 2001/04 by takaken */
/**************************************************/
#include <stdio.h>
#include <stdlib.h>

#define  FALSE           0
#define  TRUE            1
#define  BOARD_WIDTH     4

#define  WDTBL_SIZE  24964 /* WalkingDistance TableSize */

typedef  unsigned __int64  u64;

int   TABLE[BOARD_WIDTH][BOARD_WIDTH];
int   WDTOP, WDEND;
u64   WDPTN[WDTBL_SIZE];                 /* 局面パターン */
char  WDTBL[WDTBL_SIZE];                 /* 最短手数(WD) */
short WDLNK[WDTBL_SIZE][2][BOARD_WIDTH]; /* 双方向リンク */

/*********************************************/
/* 探索結果のテーブルをディスクに保存する    */
/*********************************************/
void WriteDisk(void)
{
    int  i, j, k, work[8];
    u64 table;
    char *filename = "puz15wd.db";
    FILE *fp;

    fp = fopen(filename, "wb");
    for (i=0; i<WDTBL_SIZE; i++) {
        /* WDPTN */
        table = WDPTN[i];
        for (j=7; j>=0; j--,table>>=8)
            work[j] = (int)(table & 0xff);
        for (j=0; j<8; j++)
            fputc(work[j], fp);
        /* WDTBL */
        fputc(WDTBL[i], fp);
        /* WDLNK */
        for (j=0; j<2; j++)
        for (k=0; k<4; k++) {
            fputc(WDLNK[i][j][k]  >> 8 , fp);
            fputc(WDLNK[i][j][k] & 0xff, fp);
        }
    }
    fclose(fp);
}
/*********************************************/
/* パターンの登録と双方向リンクの形成        */
/*********************************************/
void WriteTable(char count, int vect, int group)
{
    int  i, j, k;
    u64  table;

    /* 同一パターンを探す */
    table =0;
    for (i=0; i<4; i++)
    for (j=0; j<4; j++)
        table = (table << 3) | TABLE[i][j];
    for (i=0; i<WDEND; i++)
        if (WDPTN[i] == table) break;

    /* 新規パターン登録 */
    if (i == WDEND) {
        WDPTN[WDEND] = table;
        WDTBL[WDEND] = count;
        WDEND++;
        for (j=0; j<2; j++)
        for (k=0; k<4; k++)
            WDLNK[i][j][k] = WDTBL_SIZE;
    }

    /* 双方向リンクを形成させる */
    j = WDTOP - 1;
    WDLNK[j][vect    ][group] = (short)i;
    WDLNK[i][vect ^ 1][group] = (short)j;
}
/*********************************************/
/* 幅優先探索でWalkingDistanceを求める       */
/*********************************************/
void Simuration(void)
{
    int  i, j, k, space=0, piece;
    char count;
    u64  table;

    /* 初期面を作る */
    for (i=0; i<4; i++)
    for (j=0; j<4; j++)
        TABLE[i][j] = 0;
    TABLE[0][0] = TABLE[1][1] = TABLE[2][2] = 4;
    TABLE[3][3] = 3;
    table =0;
    for (i=0; i<4; i++)
    for (j=0; j<4; j++)
        table = (table << 3) | TABLE[i][j];

    /* 初期面を登録 */
    WDPTN[0] = table;
    WDTBL[0] = 0;
    for (j=0; j<2; j++)
    for (k=0; k<4; k++)
        WDLNK[0][j][k] = WDTBL_SIZE;

    /* 幅優先探索 */
    WDTOP=0; WDEND=1;
    while (WDTOP < WDEND) {
        /* TABLE[][]呼び出し */
        table = WDPTN[WDTOP];
        count = WDTBL[WDTOP];
        WDTOP++;
        count++;

        /* TABLE[][]再現 */
        for (i=3; i>=0; i--) {
            piece = 0;
            for (j=3; j>=0; j--) {
                TABLE[i][j] = (int)(table & 7);
                table >>= 3;
                piece += TABLE[i][j];
            }
            if (piece == 3) space = i;
        }

        /* 0:駒を上に移動 */
        if ((piece = space + 1) < 4) {
            for (i=0; i<4; i++) {
                if (TABLE[piece][i]) {
                    TABLE[piece][i]--;
                    TABLE[space][i]++;
                    WriteTable(count, 0, i);
                    TABLE[piece][i]++;
                    TABLE[space][i]--;
                }
            }
        }

        /* 1:駒を下に移動 */
        if ((piece = space - 1) >= 0) {
            for (i=0; i<4; i++) {
                if (TABLE[piece][i]) {
                    TABLE[piece][i]--;
                    TABLE[space][i]++;
                    WriteTable(count, 1, i);
                    TABLE[piece][i]++;
                    TABLE[space][i]--;
                }
            }
        }
    }
}
int main(void)
{
    printf("making......\n");
    Simuration();
    printf("saving......\n");
    WriteDisk();
    printf("finish!\n");

    return 0;
}
