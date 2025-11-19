<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte';
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { Shield, CheckCircle, ChevronLeft, HelpCircle } from 'lucide-svelte';

    // ✅ Import Logic Interaction
    import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

    let mapInstance;
    let maplibreglInstance;
    let incidents = [];
    let isSidebarOpen = true;
    let selectedIncident = null;
    let showNotification = false;
    let notificationMessage = '';

    // ✅ เพิ่มตัวแปรเก็บ Marker เพื่อให้ลบออกได้ภายหลัง
    let markers = {}; 
    
    // Filter State
    let activeFilter = 'All'; 
    const filters = ['All', 'Accident/Hazard', 'Blocked', 'Flood'];
    
    $: filteredIncidents = activeFilter === 'All' 
        ? incidents 
        : incidents.filter(inc => (CATEGORY_DISPLAY_NAMES[inc.category] || inc.category) === activeFilter);

    onMount(() => {
        initializeMapInteractions();

        // Mock Data
        incidents = [
            { 
                id: 'inc_001', 
                category: 'accident', 
                title: 'รถเครื่องชนกันแยกทางฝ่ายคืบจ้าว', 
                description: 'มีผู้บาดเจ็บ ต้องการความช่วยเหลือด่วน', 
                coordinates: { lng: 98.9545, lat: 18.807 }, 
                timestamp: new Date(Date.now() - 60000).toISOString(), 
                reporter: 'Anonymous',
                likes: 5, dislikes: 0
            },
            { 
                id: 'inc_002', 
                category: 'send_help', 
                title: 'ต้องการความช่วยเหลือ', 
                description: 'เจอคนบาดเจ็บที่ลานจอดรถ', 
                coordinates: { lng: 98.9478, lat: 18.8018 }, 
                timestamp: new Date(Date.now() - 120000).toISOString(),
                reporter: 'Somchai L.',
                likes: 2, dislikes: 1
            },
            { 
                id: 'inc_003', 
                category: 'blocked', 
                title: 'ต้นไม้ล้ม', 
                description: 'ต้นไม้ล้มขวางทาง หน้าคณะวิศวกรรมศาสตร์', 
                coordinates: { lng: 98.9490, lat: 18.8015 }, 
                timestamp: new Date(Date.now() - 300000).toISOString(),
                reporter: 'Staff User',
                likes: 10, dislikes: 0
            }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        updateMarkers();
    }

    function updateMarkers() {
        if (!mapInstance || !maplibreglInstance) return;
        incidents.forEach(inc => addMarker(inc));
    }

    function addMarker(incident) {
        // ถ้ามี marker นี้อยู่แล้วไม่ต้องสร้างใหม่
        if (markers[incident.id]) return;

        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: incident.category } });

        const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 220px; padding: 4px;">
                <div style="margin-bottom: 8px;">
                    <span style="background-color: #F3E8FF; color: #8F66FF; font-size: 10px; padding: 2px 8px; border-radius: 10px; font-weight: bold; text-transform: uppercase;">
                        ${CATEGORY_DISPLAY_NAMES[incident.category] || incident.category}
                    </span>
                </div>
                <h3 style="font-size: 16px; font-weight: 700; color: #000; margin: 0 0 4px 0;">${incident.title}</h3>
                <p style="font-size: 13px; color: #6B7280; margin: 0 0 8px 0;">${incident.description}</p>
                <div style="font-size: 11px; color: #9CA3AF; border-top: 1px solid #F3F4F6; padding-top: 8px;">
                    Reported by <span style="color: #374151; font-weight: 600;">${incident.reporter}</span><br>
                    ${timeAgo(incident.timestamp)}
                </div>
            </div>
        `;

        const popup = new maplibreglInstance.Popup({ 
            offset: 35, 
            className: 'cmu-popup', 
            closeButton: false 
        }).setHTML(popupHTML);

        const marker = new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
            .setLngLat([incident.coordinates.lng, incident.coordinates.lat])
            .setPopup(popup)
            .addTo(mapInstance);

        el.addEventListener('click', () => {
             selectedIncident = incident;
             isSidebarOpen = true;
             mapInstance.flyTo({ center: [incident.coordinates.lng, incident.coordinates.lat], zoom: 17 });
        });

        markers[incident.id] = marker;
    }

    function flyToIncident(inc) {
        if(mapInstance) {
            mapInstance.flyTo({ center: [inc.coordinates.lng, inc.coordinates.lat], zoom: 18 });
        }
        selectedIncident = inc;
    }

    function handleAction(action, id) {
        if (markers[id]) {
            markers[id].remove(); // สั่งลบจากแผนที่
            delete markers[id];   // ลบออกจาก memory
        }

        incidents = incidents.filter(i => i.id !== id);
        selectedIncident = null;
        
        notificationMessage = action === 'Approved' ? 'Incident Approved' : 'Incident Rejected';
        showNotification = true;
        setTimeout(() => showNotification = false, 3000);
    }

    function getCategoryColor(cat) {
        if (cat === 'accident') return 'text-red-500';
        if (cat === 'blocked') return 'text-orange-500';
        if (cat === 'flood') return 'text-blue-500';
        return 'text-red-500'; 
    }
    
    function getCategoryBg(cat) {
        if (cat === 'accident') return 'bg-red-100';
        if (cat === 'blocked') return 'bg-orange-100';
        if (cat === 'flood') return 'bg-blue-100';
        return 'bg-red-100';
    }
</script>

<div class="relative h-screen w-full font-kanit overflow-hidden bg-white">
    <div class="absolute inset-0 z-0">
        <BaseMap on:load={handleMapLoad} />
    </div>
    
    <Navbar showMenuButton={true} on:toggleSidebar={() => isSidebarOpen = !isSidebarOpen} />

    <!-- Sidebar -->
    <div class="absolute left-0 top-0 bottom-0 z-30 w-full md:w-[400px] bg-white shadow-2xl transition-transform transform duration-300 ease-in-out {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} pt-20 flex flex-col">
        
        <!-- Header -->
        <div class="px-6 pt-4 pb-2 flex justify-between items-center">
            <h2 class="text-xl font-bold text-gray-900 flex items-center gap-2">
                Incoming Alerts 
                <span class="flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">{incidents.length}</span>
            </h2>
            <button on:click={() => isSidebarOpen = false} class="p-1 hover:bg-gray-100 rounded-full md:hidden">
                <ChevronLeft class="text-gray-400 w-6 h-6" />
            </button>
        </div>

        <!-- Filter Tabs -->
        <div class="px-6 pb-4 border-b border-gray-100 overflow-x-auto no-scrollbar">
            <div class="flex gap-2">
                {#each filters as filter}
                    <button 
                        class="px-4 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap border transition-all
                               {activeFilter === filter 
                               ? 'bg-[#8F66FF] text-white border-[#8F66FF]' 
                               : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300'}"
                        on:click={() => activeFilter = filter}
                    >
                        {#if filter === 'All'}
                            All ({incidents.length})
                        {:else}
                             {filter}
                        {/if}
                    </button>
                {/each}
            </div>
        </div>

        <!-- Alert List -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50 custom-scrollbar">
            {#if filteredIncidents.length === 0}
                <div class="flex flex-col items-center justify-center h-64 text-gray-400">
                    <CheckCircle class="w-12 h-12 mb-2 text-green-400 opacity-50" />
                    <p>All clear! No pending incidents.</p>
                </div>
            {:else}
                {#each filteredIncidents as incident (incident.id)}
                    <!-- Card -->
                    <div 
                        class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm hover:shadow-md transition-all cursor-pointer relative overflow-hidden
                               {selectedIncident?.id === incident.id ? 'ring-2 ring-[#8F66FF] border-transparent' : ''}"
                        on:click={() => flyToIncident(incident)}
                    >
                        <div class="absolute left-0 top-0 bottom-0 w-1 {getCategoryBg(incident.category).replace('100', '500')}"></div>

                        <div class="flex justify-between items-start mb-2 pl-2">
                            <div class="flex items-center gap-2">
                                <div class="p-1.5 rounded-full {getCategoryBg(incident.category)}">
                                     <svelte:component this={CATEGORY_STYLES[incident.category]?.Icon || HelpCircle} class="w-4 h-4 {getCategoryColor(incident.category)}" />
                                </div>
                                <span class="text-[10px] font-bold uppercase tracking-wider {getCategoryColor(incident.category)}">
                                    {CATEGORY_DISPLAY_NAMES[incident.category] || incident.category.toUpperCase()}
                                </span>
                                <span class="text-[10px] text-gray-400 ml-1">
                                    {new Date(incident.timestamp).toLocaleDateString('th-TH', {day: '2-digit', month: '2-digit', year: 'numeric'})} 
                                    {new Date(incident.timestamp).toLocaleTimeString('th-TH', {hour: '2-digit', minute: '2-digit'})}
                                </span>
                            </div>
                        </div>

                        <div class="pl-2 mb-4">
                            <h3 class="font-bold text-gray-900 text-base leading-tight mb-1">{incident.title}</h3>
                            <p class="text-sm text-gray-500 line-clamp-2 font-light">{incident.description}</p>
                        </div>

                        <div class="pl-2 flex justify-between items-center mb-4 text-xs text-gray-400">
                            <span>Reported by {incident.reporter}</span>
                            <span>{timeAgo(incident.timestamp)}</span>
                        </div>

                        <!-- Action Buttons -->
                        <div class="flex gap-3 pl-2">
                            <button 
                                class="flex-1 py-2.5 bg-white border border-red-200 text-red-500 rounded-xl font-bold text-sm hover:bg-red-50 transition-colors uppercase tracking-wide"
                                on:click|stopPropagation={() => handleAction('Rejected', incident.id)}
                            >
                                reject
                            </button>
                            <button 
                                class="flex-1 py-2.5 bg-[#8F66FF] text-white rounded-xl font-bold text-sm hover:bg-[#7a52e0] shadow-md shadow-purple-100 transition-colors uppercase tracking-wide"
                                on:click|stopPropagation={() => handleAction('Approved', incident.id)}
                            >
                                approve
                            </button>
                        </div>
                    </div>
                {/each}
            {/if}
        </div>
    </div>

    {#if showNotification}
        <div class="fixed top-24 left-1/2 -translate-x-1/2 z-50 bg-[#10B981] text-white px-6 py-3 rounded-full shadow-xl flex items-center gap-3 animate-bounce">
            <CheckCircle class="w-5 h-5" /> <span class="font-bold">{notificationMessage}</span>
        </div>
    {/if}
</div>

<style>
    :global(.cmu-popup .maplibregl-popup-content) {
        border-radius: 16px !important;
        padding: 12px !important;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1) !important;
        border: none !important;
    }
    :global(.cmu-popup .maplibregl-popup-tip) {
        display: none !important;
    }
    :global(.cmu-popup .maplibregl-popup-close-button) {
        display: none !important;
    }
    
    /* Scrollbar */
    .custom-scrollbar::-webkit-scrollbar { width: 4px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background-color: #e5e7eb; border-radius: 20px; }
    
    .no-scrollbar::-webkit-scrollbar { display: none; }
    .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
    .font-kanit { font-family: 'Kanit', sans-serif; }
</style>