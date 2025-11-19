<script>
    import { createEventDispatcher } from 'svelte';
    import { CATEGORY_STYLES } from '$lib/constant/map-config.js';
    export let selectedCategory = null;
    const dispatch = createEventDispatcher();

    // เรียงลำดับหมวดหมู่
    const incidentKeys = ['accident', 'blocked', 'beware', 'flood', 'send_help'];
    const generalKeys = ['traffic_general', 'parking', 'events', 'map_chat', 'lost_found'];
</script>

<div class="pointer-events-auto absolute top-20 left-4 z-30 flex w-72 flex-col gap-4 rounded-2xl border border-gray-200 bg-white p-4 shadow-lg">
    <h2 class="text-lg font-bold text-gray-900 text-center">What's happening?</h2>
    
    <div>
        <h3 class="font-semibold text-sm text-gray-500 mb-2">Incident Report</h3>
        <div class="grid grid-cols-3 gap-2">
            {#each incidentKeys as key}
                <button class="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-gray-50 {selectedCategory === key ? 'bg-blue-50 ring-2 ring-blue-200' : ''}"
                    on:click={() => key === 'send_help' ? dispatch('sendHelp') : (key === 'blocked' ? dispatch('showOptions', key) : dispatch('select', key))}>
                    <div class="flex h-10 w-10 items-center justify-center rounded-full {CATEGORY_STYLES[key].bg}">
                        <svelte:component this={CATEGORY_STYLES[key].Icon} class="h-5 w-5 {CATEGORY_STYLES[key].text}" />
                    </div>
                    <span class="text-[10px] font-medium text-center leading-tight">{key.replace('_', ' ')}</span>
                </button>
            {/each}
        </div>
    </div>

    <div>
        <h3 class="font-semibold text-sm text-gray-500 mb-2">General</h3>
        <div class="grid grid-cols-3 gap-2">
            {#each generalKeys as key}
                 <button class="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-gray-50 {selectedCategory === key ? 'bg-blue-50 ring-2 ring-blue-200' : ''}"
                    on:click={() => key === 'traffic_general' ? dispatch('showOptions', key) : dispatch('select', key)}>
                    <div class="flex h-10 w-10 items-center justify-center rounded-full {CATEGORY_STYLES[key].bg}">
                        <svelte:component this={CATEGORY_STYLES[key].Icon} class="h-5 w-5 {CATEGORY_STYLES[key].text}" />
                    </div>
                    <span class="text-[10px] font-medium text-center leading-tight">{key.replace('_', ' ')}</span>
                </button>
            {/each}
        </div>
    </div>
</div>