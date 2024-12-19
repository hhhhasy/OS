#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
        }
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}

void
schedule(void) {
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    // 保存中断状态，并禁用中断
    local_intr_save(intr_flag);
    {
        // 清除当前进程的重调度标志
        current->need_resched = 0;
        // 如果当前是空闲进程，从进程列表头开始搜索；否则从当前进程开始搜索
        last = (current == idleproc) ? &proc_list : &(current->list_link);
        le = last;
        // 循环搜索可运行的进程
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                // 找到一个处于就绪态的进程
                if (next->state == PROC_RUNNABLE) {
                    break;
                }
            }
        } while (le != last);
        // 如果没有找到可运行进程，则运行空闲进程
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc;
        }
        // 更新进程运行次数
        next->runs ++;
        // 如果下一个运行的进程不是当前进程，则进行进程切换
        if (next != current) {
            proc_run(next);
        }
    }
    // 恢复中断状态
    local_intr_restore(intr_flag);
}

