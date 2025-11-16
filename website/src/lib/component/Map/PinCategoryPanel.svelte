<script>
    import { createEventDispatcher } from 'svelte';
    import {
        AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
        CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare
    } from 'lucide-svelte';

    export let selectedCategory = null;
    const dispatch = createEventDispatcher(); 
 
    const categoryStyles = {
        'accident': { Icon: AlertTriangle, bg: 'bg-red-100', text: 'text-red-600' },
        'blocked': { Icon: TrafficCone, bg: 'bg-orange-100', text: 'text-orange-600' },
        'beware': { Icon: HelpCircle, bg: 'bg-gray-200', text: 'text-gray-700' },
        'flood': { Icon: Droplet, bg: 'bg-blue-100', text: 'text-blue-600' },
        'send_help': { Icon: LifeBuoy, bg: 'bg-red-100', text: 'text-red-600' },
        'traffic_general': { Icon: CarFront, bg: 'bg-red-100', text: 'text-red-600' },
        'parking': { Icon: ParkingSquare, bg: 'bg-blue-100', text: 'text-blue-600' },
        'events': { Icon: PartyPopper, bg: 'bg-purple-100', text: 'text-purple-600' },
        // 'map_chat': { Icon: MessageSquare, bg: 'bg-green-100', text: 'text-green-600' },
        'lost_found': { Icon: Briefcase, bg: 'bg-orange-200', text: 'text-orange-600' }
    };

    function selectPinCategory(category) {
        if (category === 'blocked') {
            dispatch('showOptions', category); 
        } else if (category === 'traffic_general') {
            dispatch('showOptions', category);
        } else {
            selectedCategory = category;
        }
        console.log('Selected Category:', selectedCategory);
    }
</script>

<div
    class="pointer-events-auto absolute top-20 left-4 z-40 flex w-72 flex-col gap-5 rounded-2xl border border-gray-200 bg-white p-5 shadow-lg"
>
    <h2 class="text-lg font-bold text-gray-900 -mb-2 text-center">What's happening here?</h2>

    <!-- Incident Report Section -->
    <div class="flex flex-col gap-3">
        <h3 class="font-semibold text-base text-gray-700">Incident Report</h3>
        <div class="grid grid-cols-3 gap-3">
            
            {#each Object.entries(categoryStyles).slice(0, 5) as [key, style]}
            <button
                class="flex flex-col items-center gap-1 p-2 rounded-lg text-center 
                        {selectedCategory === key ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory(key)}
            >
                <div class="flex h-12 w-12 items-center justify-center rounded-full {style.bg}">
                    <svelte:component this={style.Icon} class="h-6 w-6 {style.text}" />
                </div>
                <span class="text-xs font-medium mt-1">
                    {#if key === 'accident'}Accident <br> /Hazard
                    {:else if key === 'blocked'}Blocked
                    {:else if key === 'beware'}Beware
                    {:else if key === 'flood'}Flood
                    {:else if key === 'send_help'}Send Help
                    {/if}
                </span>
            </button>
            {/each}
        </div>
    </div>

    <!-- General Report Section -->
    <div class="flex flex-col gap-3">
        <h3 class="font-semibold text-base text-gray-700">General Report</h3>
        <div class="grid grid-cols-3 gap-3">
            
            {#each Object.entries(categoryStyles).slice(5) as [key, style]}
            <button
                class="flex flex-col items-center gap-1 p-2 rounded-lg text-center 
                        {selectedCategory === key ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}"
                on:click={() => selectPinCategory(key)}
            >
                <div class="flex h-12 w-12 items-center justify-center rounded-full {style.bg}">
                    <svelte:component this={style.Icon} class="h-6 w-6 {style.text}" />
                </div>
                <span class="text-xs font-medium mt-1">
                    {#if key === 'traffic_general'}Traffic
                    {:else if key === 'parking'}Parking
                    {:else if key === 'events'}Events
                    {:else if key === 'map_chat'}Map Chat
                    {:else if key === 'lost_found'}Lost & Found
                    {/if}
                </span>
            </button>
            {/each}
        </div>
    </div>
</div>