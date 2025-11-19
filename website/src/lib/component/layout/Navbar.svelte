<script>
    import { userStore } from '$lib/stores/userStore.js';
    import { clickOutside } from '$lib/utils/actions.js'; 
    import { Menu, User, ChevronDown, ChevronUp } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';
    import { goto } from '$app/navigation';

    export let showMenuButton = true;
    
    const dispatch = createEventDispatcher();
    let isProfileOpen = false;

    function handleLogout() {
        userStore.set(null);
        goto('/login');
    }
</script>

<nav class="absolute top-0 right-0 left-0 z-40 flex items-center justify-between px-4 pt-safe pointer-events-none">
    {#if showMenuButton}
        <button
            class="pointer-events-auto flex items-center justify-center rounded-2xl bg-white p-3 shadow-sm border border-gray-100 hover:bg-gray-50 active:scale-95 transition-all"
            on:click={() => dispatch('toggleSidebar')}
        >
            <Menu class="h-6 w-6 text-gray-700" />
        </button>
    {:else}
        <div></div>
    {/if}

    <div class="relative pointer-events-auto" use:clickOutside on:clickoutside={() => (isProfileOpen = false)}>
        {#if $userStore}
            <button
                on:click={() => (isProfileOpen = !isProfileOpen)}
                class="flex items-center gap-3 rounded-2xl bg-white p-2 pr-4 shadow-sm border border-gray-100 hover:bg-gray-50 transition-all"
            >
                <div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100">
                    <User class="h-5 w-5 text-gray-600" />
                </div>
                <div class="flex items-center gap-2">
                    <span class="font-bold text-gray-800 text-lg">{$userStore?.name ?? 'User'}</span>
                    {#if $userStore?.role}
                        <span class="rounded-full bg-[#EBE0F3] px-2 py-0.5 text-xs font-bold text-[#8F66FF] uppercase tracking-wide">
                            {$userStore.role}
                        </span>
                    {/if}
                </div>
                {#if isProfileOpen}
                    <ChevronUp class="h-4 w-4 text-gray-400" />
                {:else}
                    <ChevronDown class="h-4 w-4 text-gray-400" />
                {/if}
            </button>
            
            {#if isProfileOpen}
                <div class="absolute right-0 mt-2 w-64 rounded-2xl bg-white p-4 shadow-xl border border-gray-100 z-50 animate-in fade-in slide-in-from-top-2">
                    <div class="pb-3 border-b border-gray-100">
                        <div class="font-bold text-xl text-gray-900">{$userStore?.name}</div>
                        <div class="text-sm text-gray-500 mt-1">{$userStore?.email}</div>
                    </div>
                    <div class="pt-2">
                        <button
                            on:click={handleLogout}
                            class="w-full text-left px-2 py-2 text-base font-semibold text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
                        >
                            Sign Out
                        </button>
                    </div>
                </div>
            {/if}
        {:else}
            <a href="/login" class="pointer-events-auto flex items-center justify-center rounded-2xl bg-white px-6 py-3 shadow-md hover:bg-gray-50 text-[#8F66FF] font-bold">
                Login
            </a>
        {/if}
    </div>
</nav>

<style>
    .pt-safe {
        padding-top: max(1rem, env(safe-area-inset-top));
    }
</style>