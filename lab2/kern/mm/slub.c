#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define PAGE_SIZE 4096 // 假设页大小为4096字节
#define MAX_ORDER 10   // 最大的页顺序，用于分配不同大小的内存块

// 内存块结构
typedef struct kmem_cache {
    void* free_list; // 空闲列表头
    size_t object_size; // 对象大小
    struct kmem_cache* next; // 下一个缓存
} kmem_cache_t;

// 页结构，用于第一层内存分配
typedef struct page {
    struct page* next; // 下一个页
} page_t;

// 页链表头
static page_t* page_list = NULL;
// 内存缓存链表头
static kmem_cache_t* cache_list = NULL;

// 初始化页链表
void init_pages() {
    for (int i = 0; i < MAX_ORDER; i++) {
        page_t* page = (page_t*)malloc(PAGE_SIZE);
        if (page) {
            page->next = page_list;
            page_list = page;
        }
    }
}

// 第一层内存分配：基于页大小
void* alloc_pages(size_t pages) {
    page_t* current = page_list;
    page_t* prev = NULL;

    while (current && pages--) {
        prev = current;
        current = current->next;
    }

    if (prev) {
        prev->next = current;
    }
    else {
        page_list = current;
    }

    return (current) ? current : NULL; // 添加检查
}

// 第二层内存分配：基于任意大小
void* kmem_cache_alloc(size_t size) {
    kmem_cache_t* cache = cache_list;
    while (cache) {
        if (cache->object_size == size && cache->free_list) {
            void* obj = cache->free_list;
            cache->free_list = *(void**)obj; // 更新空闲列表头
            return obj; // 返回已分配对象
        }
        cache = cache->next; // 检查下一个缓存
    }

    // 创建新的缓存
    cache = (kmem_cache_t*)malloc(sizeof(kmem_cache_t));
    if (!cache) return NULL; // 添加检查

    cache->object_size = size; // 设置对象大小
    cache->next = cache_list; // 将新缓存插入到链表头
    cache_list = cache;

    // 分配一页内存，并初始化空闲列表
    void* page = alloc_pages(1);
    if (!page) return NULL; // 添加检查

    size_t num_objects = PAGE_SIZE / size; // 计算可以存放多少个对象
    void* obj = page; // 初始化对象指针
    void** next_obj = (void**)page; // 初始化下一个对象指针

    for (size_t i = 0; i < num_objects - 1; i++) {
        *next_obj = (void*)((char*)obj + size); // 链接下一个对象
        obj = *next_obj; // 移动到下一个对象
        next_obj = (void**)obj; // 更新下一个对象指针
    }
    *next_obj = NULL; // 最后一个对象指向NULL

    cache->free_list = page; // 将新分配的页设置为空闲列表

    return kmem_cache_alloc(size); // 递归调用以获取第一个对象
}

// 释放内存
void kmem_cache_free(void* obj, size_t size) {
    if (!obj) return; // 添加空指针检查

    kmem_cache_t* cache = cache_list;
    while (cache) {
        if (cache->object_size == size) {
            // 将对象添加回空闲列表
            *(void**)obj = cache->free_list;
            cache->free_list = obj; // 更新空闲列表头
            return;
        }
        cache = cache->next;
    }
}

int main() {
    init_pages();

    void* obj1 = kmem_cache_alloc(128);
    void* obj2 = kmem_cache_alloc(256);
    void* obj3 = kmem_cache_alloc(128);

    printf("Allocated objects: %p, %p, %p\n", obj1, obj2, obj3);

    kmem_cache_free(obj1, 128);
    kmem_cache_free(obj3, 128);

    // 重新分配并检查地址
    void* obj4 = kmem_cache_alloc(128);
    printf("Reallocated object: %p\n", obj4);
    system("pause");
    return 0;
}
