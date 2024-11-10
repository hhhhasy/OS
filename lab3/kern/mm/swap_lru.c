#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

static list_entry_t pra_list_head;

static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation

    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
     assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}

static void update_or_ignore(unsigned int addr) {
    list_entry_t *head = &pra_list_head, *le = head;
    
    while ((le = list_prev(le)) != head) {
        struct Page *curr = le2page(le, pra_page_link);
        if (curr->pra_vaddr == addr) {
            list_del(le);         // 删除找到的页
            list_add(head, le);   // 将页移到链表头部
            return;               // 直接返回，不必继续查找
        }
    }
}

static void
printlist() {
    cprintf("--------head----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: %x\n", page->pra_vaddr);
    }
    cprintf("--------tail----------\n");
}

static void write_and_check(unsigned int addr, unsigned char value, int expected_faults) {
    cprintf("write Virt Page %x in lru_check_swap\n", addr);
    update_or_ignore(addr);
    *(unsigned char *)addr = value;
    //assert(pgfault_num == expected_faults);
}

static int _lru_check_swap(void) {
    write_and_check(0x3000, 0x0c, 4);
    printlist();
    write_and_check(0x1000, 0x0a, 4);
    printlist();
    write_and_check(0x4000, 0x0d, 4);
    printlist();
    write_and_check(0x2000, 0x0b, 4);
    printlist();
    write_and_check(0x5000, 0x0e, 5);
    printlist();
    write_and_check(0x2000, 0x0b, 5);
    printlist();
    write_and_check(0x1000, 0x0a, 6);
    printlist();
    write_and_check(0x2000, 0x0b, 7);
    printlist();
    write_and_check(0x3000, 0x0c, 8);
    printlist();
    write_and_check(0x4000, 0x0d, 9);
    printlist();
    write_and_check(0x5000, 0x0e, 10);
    printlist();
    write_and_check(0x1000, 0x0a, 11);
    printlist();

    return 0;
}


static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_lru =
{
     .name            = "fifo swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};