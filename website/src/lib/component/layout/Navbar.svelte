<script>
    import { userStore } from '$lib/stores/userStore.js';
    import { clickOutside } from '$lib/utils/actions.js';
    import { Menu, User, ChevronDown } from 'lucide-svelte';
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

<nav class="absolute top-0 right-0 left-0 z-40 flex items-center justify-between p-4 pt-safe">
    {#if showMenuButton}
        <button
            class="flex items-center justify-center rounded-xl bg-white p-3 shadow-md hover:bg-gray-100"
            on:click={() => dispatch('toggleSidebar')}
        >
            <Menu class="h-6 w-6" />
        </button>
    {:else}
        <div></div> {/if}

    <div class="relative">
        {#if $userStore}
            <button
                on:click={() => (isProfileOpen = !isProfileOpen)}
                class="flex items-center gap-2 rounded-xl bg-white p-3 pr-2 shadow-md hover:bg-gray-100"
            >
                <div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-200">
                    <User class="h-4 w-4" />
                </div>
                <span class="hidden font-medium sm:block">{$userStore?.name ?? 'User'}</span>
                <ChevronDown
                    class="h-4 w-4 transition-transform duration-300"
                    style="transform: rotate({isProfileOpen ? 180 : 0}deg)"
                />
            </button>
            
            {#if isProfileOpen}
                <div class="absolute right-0 z-50 mt-2 w-60 rounded-xl border border-gray-200 bg-white p-2 shadow-lg">
                    <div class="p-2">
                        <div class="font-bold">{$userStore?.name}</div>
                        <div class="text-sm text-gray-500">{$userStore?.email}</div>
                        <div class="text-xs text-[#8F66FF] font-bold mt-1 uppercase">{$userStore?.role}</div>
                    </div>
                    <div class="mt-1 border-t pt-1">
                        <button
                            on:click={handleLogout}
                            class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left hover:bg-gray-100 text-red-600"
                        >
                            Sign Out
                        </button>
                    </div>
                </div>
            {/if}
        {:else}
            <a href="/login" class="flex items-center justify-center rounded-xl bg-white p-3 shadow-md hover:bg-gray-100 text-[#8F66FF] font-bold">
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