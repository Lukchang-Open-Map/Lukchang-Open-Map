<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { MessageSquare, Shield, Trash2, Search, ChevronLeft } from 'lucide-svelte';

    let mapInstance;
    let maplibreglInstance;
    let posts = [];
    let activeTab = 'posts';
    let isSidebarOpen = true;

    onMount(() => {
        // Mock Data
        posts = [
            { id: '1', category: 'accident', title: 'Accident Report', description: 'Crash near gate', coordinates: { lng: 98.9545, lat: 18.807 }, timestamp: new Date().toISOString(), likes: 5, dislikes: 0 },
            { id: '2', category: 'flood', title: 'Flood', description: 'High water level', coordinates: { lng: 98.9504, lat: 18.8052 }, timestamp: new Date().toISOString(), likes: 2, dislikes: 0 }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        
        posts.forEach(post => {
            addMarker(post);
        });
    }

    function addMarker(post) {
        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: post.category } });
        
        const popup = new maplibreglInstance.Popup({ offset: 25, className: 'cmu-popup' })
            .setHTML(`<div class="p-2 font-kanit font-bold">${post.title}</div>`);

        new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
            .setLngLat([post.coordinates.lng, post.coordinates.lat])
            .setPopup(popup)
            .addTo(mapInstance);
    }

    function flyToPost(post) {
        mapInstance.flyTo({ center: [post.coordinates.lng, post.coordinates.lat], zoom: 17 });
    }
</script>

<div class="relative h-screen w-full flex font-kanit overflow-hidden">
    <div class="w-[400px] bg-white h-full shadow-xl z-20 flex flex-col transition-transform absolute md:relative {isSidebarOpen ? 'translate-x-0' : '-translate-x-full md:-ml-[400px]'}">
        <div class="p-4 border-b flex justify-between items-center">
            <h2 class="text-xl font-bold">Admin Dashboard</h2>
            <button on:click={() => isSidebarOpen = false} class="md:hidden"><ChevronLeft /></button>
        </div>
        
        <div class="flex border-b">
            <button class="flex-1 p-3 font-bold {activeTab==='posts' ? 'text-[#8F66FF] border-b-2 border-[#8F66FF]' : 'text-gray-500'}" on:click={()=>activeTab='posts'}>Posts</button>
            <button class="flex-1 p-3 font-bold {activeTab==='security' ? 'text-[#8F66FF] border-b-2 border-[#8F66FF]' : 'text-gray-500'}" on:click={()=>activeTab='security'}>Security</button>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50">
            {#if activeTab === 'posts'}
                {#each posts as post}
                    <div class="bg-white p-4 rounded-xl shadow-sm border hover:border-[#8F66FF] cursor-pointer transition-all" on:click={() => flyToPost(post)}>
                        <div class="flex items-center gap-2 mb-2">
                             <span class="px-2 py-1 rounded-full text-xs font-bold uppercase {CATEGORY_STYLES[post.category].bg} {CATEGORY_STYLES[post.category].text}">
                                {CATEGORY_DISPLAY_NAMES[post.category]}
                            </span>
                            <span class="text-xs text-gray-400 ml-auto">{timeAgo(post.timestamp)}</span>
                        </div>
                        <h3 class="font-bold text-gray-800">{post.title}</h3>
                        <p class="text-sm text-gray-600 line-clamp-2">{post.description}</p>
                        <div class="flex justify-end mt-3 pt-3 border-t">
                             <button class="text-red-500 text-xs font-bold flex items-center gap-1 hover:bg-red-50 p-1 rounded">
                                <Trash2 class="w-3 h-3" /> Delete
                            </button>
                        </div>
                    </div>
                {/each}
            {:else}
                <div class="text-center text-gray-500 mt-10">Security Locations List (Mock)</div>
            {/if}
        </div>
    </div>

    <div class="flex-1 relative">
        {#if !isSidebarOpen}
             <button class="absolute top-4 left-4 z-30 bg-white p-3 rounded-xl shadow-lg" on:click={() => isSidebarOpen = true}>
                <MessageSquare class="w-6 h-6" />
            </button>
        {/if}
        <BaseMap on:load={handleMapLoad} />
    </div>
</div>