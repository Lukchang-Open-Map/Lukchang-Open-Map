<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte'; // ใส่ Navbar ให้ด้วยเผื่อ logout
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { Shield, CheckCircle, ChevronLeft, HelpCircle } from 'lucide-svelte';

    let mapInstance;
    let maplibreglInstance;
    let incidents = [];
    let isSidebarOpen = true;
    let selectedIncident = null;
    let showNotification = false;
    let notificationMessage = '';

    onMount(() => {
        incidents = [
            { id: 'inc_001', category: 'accident', title: 'อุบัติเหตุหน้ามอ', description: 'รถล้มบาดเจ็บเล็กน้อย', coordinates: { lng: 98.9545, lat: 18.807 }, timestamp: new Date().toISOString(), reporter: 'Anonymous' }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        incidents.forEach(inc => {
            const el = document.createElement('div');
            mount(CustomMarker, { target: el, props: { category: inc.category } });
            new maplibreglInstance.Marker({ element: el, anchor: 'bottom' }).setLngLat([inc.coordinates.lng, inc.coordinates.lat]).addTo(mapInstance);
        });
    }

    function flyToIncident(inc) {
        mapInstance.flyTo({ center: [inc.coordinates.lng, inc.coordinates.lat], zoom: 18 });
        selectedIncident = inc;
    }

    function handleAction(action, id) {
        incidents = incidents.filter(i => i.id !== id);
        selectedIncident = null;
        notificationMessage = action;
        showNotification = true;
        setTimeout(() => showNotification = false, 3000);
    }
</script>

<div class="relative h-screen w-full font-kanit overflow-hidden bg-white">
    <div class="absolute inset-0 z-0"><BaseMap on:load={handleMapLoad} /></div>
    <Navbar showMenuButton={true} on:toggleSidebar={() => isSidebarOpen = !isSidebarOpen} />

    <div class="absolute left-0 top-0 bottom-0 z-30 w-full md:w-[400px] bg-white shadow-2xl transition-transform transform {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} pt-20">
        <div class="p-4 border-b bg-white flex justify-between items-center">
            <h2 class="text-xl font-bold text-gray-800 flex items-center gap-2"><Shield class="w-6 h-6" /> Incoming Alerts ({incidents.length})</h2>
            <button on:click={() => isSidebarOpen = false} class="p-2 hover:bg-gray-100 rounded-lg"><ChevronLeft /></button>
        </div>

        <div class="p-4 space-y-4 overflow-y-auto h-full pb-24">
            {#each incidents as incident}
                <div class="border-2 border-gray-200 bg-white p-4 rounded-xl shadow-sm cursor-pointer hover:border-blue-300 {selectedIncident?.id === incident.id ? 'border-blue-500 bg-blue-50' : ''}" on:click={() => flyToIncident(incident)}>
                    <div class="flex gap-3 mb-3">
                         <div class="h-10 w-10 rounded-full flex items-center justify-center flex-shrink-0 {CATEGORY_STYLES[incident.category]?.bg}">
                             <svelte:component this={CATEGORY_STYLES[incident.category]?.Icon || HelpCircle} class="w-5 h-5 {CATEGORY_STYLES[incident.category]?.text}" />
                         </div>
                         <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <span class="px-2 py-0.5 text-xs font-bold rounded-full bg-gray-100 text-gray-700 uppercase">{CATEGORY_DISPLAY_NAMES[incident.category]}</span>
                                <span class="text-xs text-gray-500">{timeAgo(incident.timestamp)}</span>
                            </div>
                             <h3 class="font-bold text-gray-800">{incident.title}</h3>
                             <p class="text-sm text-gray-600 mt-1">{incident.description}</p>
                         </div>
                    </div>
                    <div class="flex gap-2 pt-2 border-t border-gray-100">
                        <button class="flex-1 py-2 bg-white border border-red-200 text-red-600 rounded-lg font-bold text-sm hover:bg-red-50" on:click|stopPropagation={() => handleAction('Rejected', incident.id)}>Reject</button>
                        <button class="flex-1 py-2 bg-[#8F66FF] text-white rounded-lg font-bold text-sm hover:bg-[#7a52e0]" on:click|stopPropagation={() => handleAction('Approved', incident.id)}>Approve</button>
                    </div>
                </div>
            {/each}
        </div>
    </div>

    {#if showNotification}
        <div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-green-600 text-white px-6 py-3 rounded-full shadow-2xl flex items-center gap-3 animate-bounce">
            <CheckCircle class="w-5 h-5" /> <span class="font-medium">{notificationMessage}</span>
        </div>
    {/if}
</div>