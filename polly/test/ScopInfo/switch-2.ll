; RUN: opt %loadPolly -polly-scops -analyze < %s | FileCheck %s
; RUN: opt %loadPolly -polly-ast -analyze < %s | FileCheck %s --check-prefix=AST
;
;    void f(int *A, int N) {
;      for (int i = 0; i < N; i++)
;        switch (i % 4) {
;        case 0:
;          A[i] += 1;
;          break;
;        case 1:
;          break;
;        case 2:
;          A[i] += 2;
;          break;
;        case 3:
;          break;
;        }
;    }
;
; CHECK:    Statements {
; CHECK-NOT:  Stmt_sw_bb1
; CHECK:      Stmt_sw_bb
; CHECK:            Domain :=
; CHECK:                [N] -> { Stmt_sw_bb[i0] : exists (e0 = floor((i0)/4): 4e0 = i0 and i0 >= 0 and i0 <= -1 + N) };
; CHECK:            Schedule :=
; CHECK:                [N] -> { Stmt_sw_bb[i0] -> [i0, 1] };
; CHECK-NOT:  Stmt_sw_bb1
; CHECK:      Stmt_sw_bb_2
; CHECK:            Domain :=
; CHECK:                [N] -> { Stmt_sw_bb_2[i0] : exists (e0 = floor((-2 + i0)/4): 4e0 = -2 + i0 and i0 >= 2 and i0 <= -1 + N) };
; CHECK:            Schedule :=
; CHECK:                [N] -> { Stmt_sw_bb_2[i0] -> [i0, 0] };
; CHECK-NOT:  Stmt_sw_bb1
; CHECK:    }
;
; AST:  if (1)
;
; AST:      for (int c0 = 0; c0 < N; c0 += 4) {
; AST:        Stmt_sw_bb(c0);
; AST:        if (N >= c0 + 3)
; AST:          Stmt_sw_bb_2(c0 + 2);
; AST:      }
;
; AST:  else
; AST:      {  /* original code */ }
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @f(i32* %A, i32 %N) {
entry:
  %tmp = sext i32 %N to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, %tmp
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %tmp1 = trunc i64 %indvars.iv to i32
  %rem = srem i32 %tmp1, 4
  switch i32 %rem, label %sw.epilog [
    i32 0, label %sw.bb
    i32 1, label %sw.bb.1
    i32 2, label %sw.bb.2
    i32 3, label %sw.bb.6
  ]

sw.bb:                                            ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx, align 4
  %add = add nsw i32 %tmp2, 1
  store i32 %add, i32* %arrayidx, align 4
  br label %sw.epilog

sw.bb.1:                                          ; preds = %for.body
  br label %sw.epilog

sw.bb.2:                                          ; preds = %for.body
  %arrayidx4 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp3 = load i32, i32* %arrayidx4, align 4
  %add5 = add nsw i32 %tmp3, 2
  store i32 %add5, i32* %arrayidx4, align 4
  br label %sw.epilog

sw.bb.6:                                          ; preds = %for.body
  br label %sw.epilog

sw.epilog:                                        ; preds = %sw.bb.6, %sw.bb.2, %sw.bb.1, %sw.bb, %for.body
  br label %for.inc

for.inc:                                          ; preds = %sw.epilog
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
