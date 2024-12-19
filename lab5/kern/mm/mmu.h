#ifndef __KERN_MM_MMU_H__
#define __KERN_MM_MMU_H__

#ifndef __ASSEMBLER__
#include <defs.h>
#endif

// 线性地址 'la' 具有如下三部分结构：
//
// +--------10------+-------10-------+---------12----------+
// | 页目录索引     |   页表索引     | 页内偏移            |
// +----------------+----------------+---------------------+
//  \--- PDX(la) --/ \--- PTX(la) --/ \---- PGOFF(la) ----/
//  \----------- PPN(la) -----------/
//
// PDX, PTX, PGOFF 和 PPN 宏按上述方式分解线性地址。
// 要从 PDX(la), PTX(la) 和 PGOFF(la) 构造线性地址 la，
// 使用 PGADDR(PDX(la), PTX(la), PGOFF(la))。

// RISC-V 使用 32 位虚拟地址访问 34 位物理地址！
// Sv32 页表条目：
// +---------12----------+--------10-------+---2----+-------8-------+
// |       PPN[1]        |      PPN[0]     |保留   |D|A|G|U|X|W|R|V|
// +---------12----------+-----------------+--------+---------------+

/*
 * RV32Sv32 页表条目：
 * | 31 10 | 9             7 | 6 | 5 | 4  1 | 0
 *    PFN    保留给软件使用   D   R   类型   V
 *
 * RV64Sv39 / RV64Sv48 页表条目：
 * | 63           48 | 47 10 | 9             7 | 6 | 5 | 4  1 | 0
 *   保留给硬件使用    PFN    保留给软件使用   D   R   类型   V
 */

// 页目录索引
#define PDX1(la) ((((uintptr_t)(la)) >> PDX1SHIFT) & 0x1FF)
#define PDX0(la) ((((uintptr_t)(la)) >> PDX0SHIFT) & 0x1FF)

// 页表索引
#define PTX(la) ((((uintptr_t)(la)) >> PTXSHIFT) & 0x1FF)

// 地址的页号字段
#define PPN(la) (((uintptr_t)(la)) >> PTXSHIFT)

// 页内偏移
#define PGOFF(la) (((uintptr_t)(la)) & 0xFFF)

// 从索引和偏移构造线性地址
#define PGADDR(d1, d0, t, o) ((uintptr_t)((d1) << PDX1SHIFT | (d0) << PDX0SHIFT | (t) << PTXSHIFT | (o)))

// 页表或页目录条目中的地址
#define PTE_ADDR(pte)   (((uintptr_t)(pte) & ~0x3FF) << (PTXSHIFT - PTE_PPN_SHIFT))
#define PDE_ADDR(pde)   PTE_ADDR(pde)

/* 页目录和页表常量 */
#define NPDEENTRY       512                    // 每个页目录的页目录条目数
#define NPTEENTRY       512                    // 每个页表的页表条目数

#define PGSIZE          4096                    // 每页映射的字节数
#define PGSHIFT         12                      // log2(PGSIZE)
#define PTSIZE          (PGSIZE * NPTEENTRY)    // 每个页目录条目映射的字节数
#define PTSHIFT         21                      // log2(PTSIZE)
#define PDSIZE          (PTSIZE * NPDEENTRY)    // 每个页目录映射的字节数

#define PTXSHIFT        12                      // 线性地址中 PTX 的偏移量
#define PDX0SHIFT       21                      // 线性地址中 PDX 的偏移量
#define PDX1SHIFT		30
#define PTE_PPN_SHIFT   10                      // 物理地址中 PPN 的偏移量

// 页表条目 (PTE) 字段
#define PTE_V     0x001 // 有效
#define PTE_R     0x002 // 读
#define PTE_W     0x004 // 写
#define PTE_X     0x008 // 执行
#define PTE_U     0x010 // 用户
#define PTE_G     0x020 // 全局
#define PTE_A     0x040 // 已访问
#define PTE_D     0x080 // 脏
#define PTE_SOFT  0x300 // 保留给软件使用

#define PAGE_TABLE_DIR (PTE_V)
#define READ_ONLY (PTE_R | PTE_V)
#define READ_WRITE (PTE_R | PTE_W | PTE_V)
#define EXEC_ONLY (PTE_X | PTE_V)
#define READ_EXEC (PTE_R | PTE_X | PTE_V)
#define READ_WRITE_EXEC (PTE_R | PTE_W | PTE_X | PTE_V)

#define PTE_USER (PTE_R | PTE_W | PTE_X | PTE_U | PTE_V)

#endif /* !__KERN_MM_MMU_H__ */
