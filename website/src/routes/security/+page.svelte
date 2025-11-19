<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte';
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { Shield, CheckCircle, XCircle } from 'lucide-svelte';

    let mapInstance;
    let maplibreglInstance;
    let incidents = [];
    let isSidebarOpen = true;
    let selectedIncident = null;

    onMount(() => {
        incidents = [
            { id: '101', category: 'send_help', title: 'SOS Request', description: 'Injured person at canteen', coordinates: { lng: 98.9485, lat: 18.8025 }, timestamp: new Date().toISOString(), reporter: 'Student A' }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        
        incidents.forEach(inc => {
            const el = document.createElement('div');
            mount(CustomMarker, { target: el, props: { category: inc.category } });
            
            new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
                .setLngLat([inc.coordinates.lng, inc.coordinates.lat])
                .addTo(mapInstance);
        });
    }

    function flyToIncident(inc) {
        mapInstance.flyTo({ center: [inc.coordinates.lng, inc.coordinates.lat], zoom: 18 });
        selectedIncident = inc;
    }

    function resolveIncident(id) {
        incidents = incidents.filter(i => i.id !== id);
        selectedIncident = null;
    }
</script>

<div class="relative h-screen w-full font-kanit overflow-hidden bg-white">
    <div class="absolute inset-0 z-0">
         <BaseMap on:load={handleMapLoad} />
    </div>
    
    <Navbar showMenuButton={true} on:toggleSidebar={() => isSidebarOpen = !isSidebarOpen} />

    <div class="absolute left-0 top-0 bottom-0 z-30 w-full md:w-[400px] bg-white shadow-2xl transition-transform transform {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} pt-20">
        <div class="p-4 border-b bg-red-50">
            <h2 class="text-xl font-bold text-red-700 flex items-center gap-2">
                <Shield class="w-6 h-6" /> Incoming Alerts ({incidents.length})
            </h2>
        </div>

        <div class="p-4 space-y-4 overflow-y-auto h-full pb-24">
            {#each incidents as incident}
                <div class="border-2 border-red-100 bg-white p-4 rounded-xl shadow-sm cursor-pointer hover:border-red-300" 
                     on:click={() => flyToIncident(incident)}>
                    <div class="flex gap-3">
                         <div class="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                             <svelte:component this={CATEGORY_STYLES[incident.category].Icon} class="w-6 h-6 text-red-600" />
                         </div>
                         <div class="flex-1">
                             <div class="flex justify-between items-start">
                                 <span class="font-bold text-gray-800">{incident.title}</span>
                                 <span class="text-xs text-gray-400">{timeAgo(incident.timestamp)}</span>
                             </div>
                             <p class="text-sm text-gray-600 mt-1">{incident.description}</p>
                             <div class="text-xs text-gray-400 mt-2">Reported by: {incident.reporter}</div>
                         </div>
                    </div>
                    
                    <div class="flex gap-2 mt-4 pt-3 border-t">
                        <button class="flex-1 py-2 bg-gray-100 rounded-lg text-gray-600 font-bold text-sm hover:bg-gray-200" on:click|stopPropagation={() => resolveIncident(incident.id)}>Reject</button>
                        <button class="flex-1 py-2 bg-green-500 rounded-lg text-white font-bold text-sm hover:bg-green-600" on:click|stopPropagation={() => resolveIncident(incident.id)}>Acknowledge</button>
                    </div>
                </div>
            {/each}
            
            {#if incidents.length === 0}
                <div class="text-center text-gray-400 mt-10">No active incidents.</div>
            {/if}
        </div>
    </div>
</div>