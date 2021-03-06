/* 
TEST_HEADER
 id = $HopeName: MMQA_test_function!73.c(trunk.4) $
 summary = AWL pool should get collected (request.dylan.170322)
 language = c
 link = testlib.o rankfmt.o
END_HEADER
*/

#include "testlib.h"
#include "mpscawl.h"
#include "rankfmt.h"
#include "mpsavm.h"


void *stackpointer;

mps_arena_t arena;


static void test(void) {
 mps_pool_t poolawl;
 mps_thr_t thread;
 mps_root_t root0, root1;

 mps_fmt_t format;
 mps_ap_t apawl;

 mycell *a;

 long int j;

 cdie(mps_arena_create(&arena, mps_arena_class_vm(), (size_t)1024*1024*30),
      "create arena");

 cdie(mps_thread_reg(&thread, arena), "register thread");

 cdie(mps_root_create_reg(&root0, arena, MPS_RANK_AMBIG, 0, thread,
                          mps_stack_scan_ambig, stackpointer, 0),
      "create root");
 
 cdie(mps_root_create_table(&root1, arena, MPS_RANK_AMBIG, 0,
                            (mps_addr_t *)&exfmt_root, 1),
      "create table root");

 cdie(mps_fmt_create_A(&format, arena, &fmtA),
      "create format");

 cdie(mps_pool_create(&poolawl, arena, mps_class_awl(), format),
      "create pool");

 cdie(mps_ap_create(&apawl, poolawl, MPS_RANK_EXACT),
      "create ap");

 /* alloc lots in an AWL pool; it should be collected away */

 for(j=0; j<1000; j++) {
  a = allocdumb(apawl, 1024ul*1024, MPS_RANK_EXACT);
 }

 /* (total allocated is 1000 M) */

 mps_root_destroy(root0);
 mps_root_destroy(root1);
 comment("Destroyed roots.");

 mps_ap_destroy(apawl);
 comment("Destroyed ap.");

 mps_pool_destroy(poolawl);
 comment("Destroyed pool.");

 mps_fmt_destroy(format);
 comment("Destroyed format.");

 mps_thread_dereg(thread);
 comment("Deregistered thread.");

 mps_arena_destroy(arena);
 comment("Destroyed arena.");

 pass();
}


int main(void) {
 void *m;
 stackpointer=&m; /* hack to get stack pointer */

 easy_tramp(test);
 pass();
 return 0;
}
