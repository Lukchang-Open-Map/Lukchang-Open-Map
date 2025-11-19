<script>
    import { createEventDispatcher } from 'svelte';
    import {
        AlertTriangle, TrafficCone, HelpCircle, Droplet, LifeBuoy,
        CarFront, ParkingSquare, Briefcase, PartyPopper, MessageSquare, X
    } from 'lucide-svelte';
    import { fly } from 'svelte/transition'; 

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

    const incidentCategories = Object.entries(categoryStyles).slice(0, 5);
    const generalCategories = Object.entries(categoryStyles).slice(5); 

    function selectPinCategory(category) {
        if (category === 'blocked') {
            dispatch('showOptions', category); 
        } else if (category === 'traffic_general') {
            dispatch('showOptions', category);
        } else {
            dispatch('select', category); 
        }
        console.log('Selected Category:', category);
    }
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div 
    class="absolute inset-0 z-50 bg-black/50"
    transition:fly={{ duration: 300, y: 0, opacity: 0.5 }}
    on:click={() => dispatch('close')}
></div>

<div 
    class="absolute bottom-0 left-0 right-0 z-50 flex max-h-[80vh] flex-col gap-5 rounded-t-2xl bg-white p-5 shadow-lg"
    transition:fly={{ y: 300, duration: 300 }}
>
    <div class="flex items-center justify-between -mt-1 mb-1">
        <h2 class="text-lg font-bold text-gray-900">What's happening here?</h2>
        <button 
            on:click={() => dispatch('close')}
            class="p-1 rounded-full text-gray-500 hover:bg-gray-100"
        >
            <X class="w-6 h-6" />
        </button>
    </div>

    <div class="flex flex-col gap-5 overflow-y-auto">

        <div class="flex flex-col gap-3">
            <h3 class="font-semibold text-base text-gray-700">Incident Report</h3>
            <div class="grid grid-cols-4 gap-3">
                
                {#each incidentCategories as [key, style]}
                <button
                    class="flex flex-col items-center gap-1 p-2 rounded-lg text-center hover:bg-gray-50"
                    on:click={() => selectPinCategory(key)}
                >
                    <div class="flex h-12 w-12 items-center justify-center rounded-full {style.bg}">
                        <svelte:component this={style.Icon} class="h-6 w-6 {style.text}" />
                    </div>
                    <span class="text-xs font-medium mt-1">
                        {#if key === 'accident'}Accident <br>/Hazard
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

        <div class="flex flex-col gap-3">
            <h3 class="font-semibold text-base text-gray-700">General Report</h3>
            <div class="grid grid-cols-4 gap-3">
                
                {#each generalCategories as [key, style]}
                <button
                    class="flex flex-col items-center gap-1 p-2 rounded-lg text-center hover:bg-gray-50"
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

    </div> </div>