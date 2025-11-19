<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import Navbar from '$lib/component/layout/Navbar.svelte';
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { Shield, CheckCircle, ChevronLeft, HelpCircle } from 'lucide-svelte';
    
    // ✅ Import ตัวช่วยที่เราเพิ่งสร้าง
    import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

    let mapInstance;
    let maplibreglInstance;
    let incidents = [];
    let isSidebarOpen = true;
    let selectedIncident = null;
    let showNotification = false;
    let notificationMessage = '';

    onMount(() => {
        initializeMapInteractions();

        // Mock Data
        incidents = [
            { 
                id: 'inc_001', 
                category: 'accident', 
                title: 'Accident at Main Gate', 
                description: 'Motorcycle crash, minor injuries.', 
                coordinates: { lng: 98.9545, lat: 18.807 }, 
                timestamp: new Date().toISOString(), 
                reporter: 'Anonymous',
                likes: 5,
                dislikes: 0
            },
            { 
                id: 'inc_002', 
                category: 'flood', 
                title: 'Flooding near Ang Kaew', 
                description: 'Water level rising, blocking pathway.', 
                coordinates: { lng: 98.9504, lat: 18.8052 }, 
                timestamp: new Date(Date.now() - 3600000).toISOString(), 
                reporter: 'Staff A',
                likes: 12,
                dislikes: 1
            }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        
        incidents.forEach(inc => {
            addMarker(inc);
        });
    }

    function addMarker(incident) {
        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: incident.category } });

        // ใช้ HTML Structure แบบเดิมเพื่อให้ Class ID ตรงกับใน map-interactions.js
        const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 220px; padding: 4px;">
                <div style="margin-bottom: 8px;">
                    <span style="background-color: #F3E8FF; color: #8F66FF; font-size: 10px; padding: 2px 8px; border-radius: 10px; font-weight: bold; text-transform: uppercase;">
                        ${CATEGORY_DISPLAY_NAMES[incident.category] || incident.category}
                    </span>
                </div>
                <h3 style="font-size: 16px; font-weight: 700; color: #000; margin: 0 0 4px 0;">${incident.title}</h3>
                <p style="font-size: 13px; color: #6B7280; margin: 0 0 8px 0;">${incident.description}</p>
                
                <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #F3F4F6; padding-top: 8px;">
                    <div style="font-size: 11px; color: #9CA3AF;">
                        Reported by <span style="color: #374151; font-weight: 600;">${incident.reporter}</span><br>
                        ${timeAgo(incident.timestamp)}
                    </div>

                    <!-- ปุ่ม Like/Dislike -->
                    <div style="display: flex; gap: 8px;">
                        <!-- Like -->
                        <div style="display: flex; align-items: center; gap: 2px;">
                            <button id="like-button-${incident.id}" onclick="window.handleLike('${incident.id}')" style="background: none; border: 1px solid #E5E7EB; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6B7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="like-count-${incident.id}" style="font-size: 12px; font-weight: 600; color: #374151;">${incident.likes || 0}</span>
                        </div>
                        <!-- Dislike -->
                        <div style="display: flex; align-items: center; gap: 2px;">
                            <button id="dislike-button-${incident.id}" onclick="window.handleDislike('${incident.id}')" style="background: none; border: 1px solid #E5E7EB; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6B7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: scaleY(-1);"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg>
                            </button>
                            <span id="dislike-count-${incident.id}" style="font-size: 12px; font-weight: 600; color: #374151;">${incident.dislikes || 0}</span>
                        </div>
                    </div>
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
    <div class="absolute inset-0 z-0">
        <BaseMap on:load={handleMapLoad} />
    </div>
    
    <Navbar showMenuButton={true} on:toggleSidebar={() => isSidebarOpen = !isSidebarOpen} />

    <!-- Sidebar -->
    <div class="absolute left-0 top-0 bottom-0 z-30 w-full md:w-[400px] bg-white shadow-2xl transition-transform transform {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} pt-20">
        <div class="p-4 border-b bg-white flex justify-between items-center sticky top-0 z-10">
            <h2 class="text-xl font-bold text-gray-800 flex items-center gap-2">
                <Shield class="w-6 h-6 text-[#8F66FF]" /> Incoming Alerts ({incidents.length})
            </h2>
            <button on:click={() => isSidebarOpen = false} class="p-2 hover:bg-gray-100 rounded-lg transition-colors md:hidden">
                <ChevronLeft />
            </button>
        </div>

        <div class="p-4 space-y-4 overflow-y-auto h-full pb-24">
            {#if incidents.length === 0}
                <div class="flex flex-col items-center justify-center h-64 text-gray-400">
                    <CheckCircle class="w-12 h-12 mb-2 text-green-400" />
                    <p>All clear! No pending incidents.</p>
                </div>
            {:else}
                {#each incidents as incident}
                    <div 
                        class="border-2 bg-white p-4 rounded-2xl shadow-sm cursor-pointer transition-all
                               {selectedIncident?.id === incident.id ? 'border-[#8F66FF] ring-2 ring-purple-50' : 'border-gray-100 hover:border-gray-300'}" 
                        on:click={() => flyToIncident(incident)}
                    >
                        <div class="flex gap-3 mb-3">
                             <div class="h-12 w-12 rounded-full flex items-center justify-center flex-shrink-0 {CATEGORY_STYLES[incident.category]?.bg || 'bg-gray-100'}">
                                 <svelte:component this={CATEGORY_STYLES[incident.category]?.Icon || HelpCircle} class="w-6 h-6 {CATEGORY_STYLES[incident.category]?.text || 'text-gray-500'}" />
                             </div>
                             <div class="flex-1 min-w-0">
                                <div class="flex items-center justify-between mb-1">
                                    <span class="px-2 py-0.5 text-[10px] font-bold rounded-full bg-gray-100 text-gray-600 uppercase tracking-wider">
                                        {CATEGORY_DISPLAY_NAMES[incident.category]}
                                    </span>
                                    <span class="text-xs text-gray-400 whitespace-nowrap">{timeAgo(incident.timestamp)}</span>
                                </div>
                                 <h3 class="font-bold text-gray-900 truncate">{incident.title}</h3>
                                 <p class="text-sm text-gray-600 mt-1 line-clamp-2">{incident.description}</p>
                                 <div class="text-xs text-gray-400 mt-2 flex items-center gap-1">
                                    <div class="w-2 h-2 rounded-full bg-gray-300"></div>
                                    Reported by: <span class="text-gray-600 font-medium">{incident.reporter}</span>
                                 </div>
                             </div>
                        </div>
                        <div class="flex gap-3 pt-3 border-t border-gray-50">
                            <button 
                                class="flex-1 py-2 bg-white border border-gray-200 text-gray-600 rounded-xl font-bold text-sm hover:bg-gray-50 hover:text-red-500 hover:border-red-200 transition-colors" 
                                on:click|stopPropagation={() => handleAction('Rejected', incident.id)}
                            >
                                Reject
                            </button>
                            <button 
                                class="flex-1 py-2 bg-[#8F66FF] text-white rounded-xl font-bold text-sm hover:bg-[#7a52e0] shadow-sm shadow-purple-200 transition-colors" 
                                on:click|stopPropagation={() => handleAction('Approved', incident.id)}
                            >
                                Approve
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
</style>