<script>
    import { createEventDispatcher } from 'svelte';
    // ✅ Import RouteOff เข้ามาใช้แทน Spline
    import { MapPin, RouteOff, X } from 'lucide-svelte'; 

    // ✅ แก้ Default Values ตรงนี้เลยครับ
    export let title = 'Report Obstacle / Traffic'; 
    
    export let pointOption = { 
        Icon: MapPin, 
        title: 'Obstacle', 
        description: 'e.g. Fallen tree, Car breakdown' 
    };
    
    export let lineOption = { 
        // ✅ เปลี่ยน Icon เป็น RouteOff
        Icon: RouteOff, 
        // ✅ เปลี่ยน Title เป็น Road Off
        title: 'Road Off', 
        description: 'e.g. Construction, Flooding' 
    };

    const dispatch = createEventDispatcher();
</script>

<div 
    class="fixed inset-0 z-[90] flex items-center justify-center bg-black/40 backdrop-blur-[2px] p-4 font-kanit"
    on:click={() => dispatch('close')}
>
    <div 
        on:click|stopPropagation
        class="bg-white rounded-[32px] w-full max-w-sm p-6 flex flex-col gap-4 shadow-2xl animate-scale-up"
    >
        <div class="flex justify-between items-center pl-2">
            <h2 class="text-xl font-bold text-gray-900">{title}</h2>
            <button 
                on:click={() => dispatch('close')}
                class="p-2 rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
            >
                <X class="w-6 h-6" />
            </button>
        </div>
        
        <p class="text-gray-500 pl-2 -mt-2 text-sm">What kind of report is it?</p>

        <div class="flex flex-col gap-3 mt-2">
            
            <button
                on:click={() => dispatch('selectPoint')}
                class="flex items-center gap-4 p-4 rounded-2xl border border-gray-200 hover:border-orange-200 hover:bg-orange-50 transition-all group text-left"
            >
                <div class="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 group-hover:bg-orange-200 transition-colors shrink-0">
                    <svelte:component this={pointOption.Icon} class="w-6 h-6" />
                </div>
                <div>
                    <span class="font-bold text-gray-800 text-lg block">{pointOption.title}</span>
                    <span class="text-sm text-gray-500">{pointOption.description}</span>
                </div>
            </button>

            <button
                on:click={() => dispatch('selectLine')}
                class="flex items-center gap-4 p-4 rounded-2xl border border-gray-200 hover:border-orange-200 hover:bg-orange-50 transition-all group text-left"
            >
                <div class="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 group-hover:bg-orange-200 transition-colors shrink-0">
                    <svelte:component this={lineOption.Icon} class="w-6 h-6" />
                </div>
                <div>
                    <span class="font-bold text-gray-800 text-lg block">{lineOption.title}</span>
                    <span class="text-sm text-gray-500">{lineOption.description}</span>
                </div>
            </button>

        </div>
    </div>
</div>

<style>
    @keyframes scale-up {
        from { transform: scale(0.95); opacity: 0; }
        to { transform: scale(1); opacity: 1; }
    }
    .animate-scale-up {
        animation: scale-up 0.2s ease-out forwards;
    }
</style>