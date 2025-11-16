<script>
    import { createEventDispatcher } from 'svelte';
    import { MapPin, Spline, X } from 'lucide-svelte';

    export let title = 'Report Issue';
    export let pointOption = { 
        Icon: MapPin, 
        title: 'Issue', 
        description: 'Pin a point' 
    };
    export let lineOption = { 
        Icon: Spline, 
        title: 'Area', 
        description: 'Draw a line' 
    };

    const dispatch = createEventDispatcher();
</script>


<div 
    class="absolute inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    on:click={() => dispatch('close')}
>
    <div 
        on:click|stopPropagation
        class="bg-white rounded-2xl w-full max-w-sm p-6 flex flex-col gap-4 shadow-lg"
    >
        <div class="flex justify-between items-center">
            <h2 class="text-lg font-bold">{title}</h2>
            <button 
                on:click={() => dispatch('close')}
                class="p-1 rounded-full text-gray-500 hover:bg-gray-100"
            >
                <X class="w-5 h-5" />
            </button>
        </div>
        
        <p class="text-gray-600 -mt-2">What kind of report is it?</p>

        <button
            on:click={() => dispatch('selectPoint')}
            class="flex items-center gap-4 p-4 rounded-lg border hover:bg-gray-50 text-left"
        >
            <svelte:component this={pointOption.Icon} class="w-10 h-10 text-orange-600" />
            <div>
                <span class="font-semibold">{pointOption.title}</span>
                <p class="text-sm text-gray-500">{pointOption.description}</p>
            </div>
        </button>

        <button
            on:click={() => dispatch('selectLine')}
            class="flex items-center gap-4 p-4 rounded-lg border hover:bg-gray-50 text-left"
        >
            <svelte:component this={lineOption.Icon} class="w-10 h-10 text-orange-600" />
            <div>
                <span class="font-semibold">{lineOption.title}</span>
                <p class="text-sm text-gray-500">{lineOption.description}</p>
            </div>
        </button>
    </div>
</div>