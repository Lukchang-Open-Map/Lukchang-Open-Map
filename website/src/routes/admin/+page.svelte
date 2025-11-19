<script>
    import { onMount, mount } from 'svelte';
    import BaseMap from '$lib/component/map/BaseMap.svelte';
    import CustomMarker from '$lib/component/map/CustomMarker.svelte';
    import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
    import { timeAgo } from '$lib/utils/formatting.js';
    import { MessageSquare, Shield, Trash2, Search, ChevronLeft, CheckCircle } from 'lucide-svelte';

    let mapInstance;
    let maplibreglInstance;
    let posts = []; 
    let activeTab = 'posts';
    let isSidebarOpen = true;
    let selectedPost = null;
    let showNotification = false;
    let notificationMessage = '';

    // Mock Data from original
    onMount(() => {
        posts = [
            { id: 'post_001', category: 'accident', title: 'รถเครื่องชนกัน', description: 'เกิดอุบัติเหตุที่หน้ามอ', coordinates: { lng: 98.9545, lat: 18.807 }, reporter: { name: 'Somchai' }, timestamp: new Date().toISOString(), likes: 12, dislikes: 2 },
            { id: 'post_002', category: 'flood', title: 'น้ำท่วมถนน', description: 'น้ำท่วมสูงที่อ่างแก้ว', coordinates: { lng: 98.9504, lat: 18.8052 }, reporter: { name: 'Nittaya' }, timestamp: new Date().toISOString(), likes: 8, dislikes: 0 }
        ];
    });

    function handleMapLoad({ detail }) {
        mapInstance = detail.map;
        maplibreglInstance = detail.maplibregl;
        posts.forEach(post => addMarker(post));
    }

    function addMarker(post) {
        const el = document.createElement('div');
        mount(CustomMarker, { target: el, props: { category: post.category } });
        const popup = new maplibreglInstance.Popup({ offset: 25, className: 'cmu-popup' }).setHTML(`<div class="p-2 font-kanit"><b>${post.title}</b></div>`);
        new maplibreglInstance.Marker({ element: el, anchor: 'bottom' }).setLngLat([post.coordinates.lng, post.coordinates.lat]).setPopup(popup).addTo(mapInstance);
    }

    function flyToPost(post) {
        mapInstance.flyTo({ center: [post.coordinates.lng, post.coordinates.lat], zoom: 17 });
        selectedPost = post;
    }

    function showSuccess(msg) {
        notificationMessage = msg; showNotification = true;
        setTimeout(() => showNotification = false, 3000);
    }
</script>

<div class="relative h-screen w-full flex font-kanit overflow-hidden">
    <div class="absolute top-0 bottom-0 left-0 z-[60] w-full bg-white shadow-2xl transition-transform duration-300 md:w-[445px] {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}">
        <div class="flex items-center justify-between border-b border-gray-200 bg-white p-4">
            <div class="flex items-center gap-2">
                <h2 class="text-xl font-bold text-gray-900">Admin Management</h2>
                <span class="flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">{posts.length}</span>
            </div>
            <button on:click={() => (isSidebarOpen = false)} class="rounded-lg p-1.5 hover:bg-gray-100"><ChevronLeft class="h-5 w-5 text-gray-600" /></button>
        </div>

        <div class="border-b border-gray-200 bg-gray-50 p-4">
            <div class="relative mb-3">
                <Search class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input type="text" placeholder="Search..." class="w-full rounded-lg border border-gray-300 py-2 pr-4 pl-10 focus:ring-2 focus:ring-[#8F66FF]" />
            </div>
        </div>

        <div class="flex border-b border-gray-200 bg-white">
            <button on:click={() => activeTab = 'posts'} class="flex-1 px-4 py-3 text-sm font-semibold transition {activeTab === 'posts' ? 'border-b-2 border-[#8F66FF] text-[#8F66FF]' : 'text-gray-600'}">Posts</button>
            <button on:click={() => activeTab = 'security'} class="flex-1 px-4 py-3 text-sm font-semibold transition {activeTab === 'security' ? 'border-b-2 border-[#8F66FF] text-[#8F66FF]' : 'text-gray-600'}">Security</button>
        </div>

        <div class="overflow-y-auto p-4 space-y-4" style="height: calc(100vh - 200px);">
            {#if activeTab === 'posts'}
                {#each posts as post}
                    <div class="cursor-pointer rounded-2xl border-2 bg-white p-4 transition-all hover:shadow-lg {selectedPost?.id === post.id ? 'border-[#8F66FF] shadow-lg' : 'border-gray-200'}" on:click={() => flyToPost(post)}>
                        <div class="mb-3 flex items-center gap-2">
                            <div class="flex h-10 w-10 items-center justify-center rounded-full {CATEGORY_STYLES[post.category].bg}">
                                <svelte:component this={CATEGORY_STYLES[post.category].Icon} class="h-5 w-5 {CATEGORY_STYLES[post.category].text}" />
                            </div>
                            <div>
                                <span class="text-xs font-bold {CATEGORY_STYLES[post.category].text} uppercase">{CATEGORY_DISPLAY_NAMES[post.category]}</span>
                                <div class="text-xs text-gray-500">{timeAgo(post.timestamp)}</div>
                            </div>
                        </div>
                        <h3 class="mb-1 text-base font-bold text-gray-900">{post.title}</h3>
                        <p class="mb-3 text-sm text-gray-600">{post.description}</p>
                        <div class="flex gap-2">
                            <button class="flex-1 rounded-lg border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50">Delete</button>
                            <button class="flex-1 rounded-lg bg-[#8F66FF] px-4 py-2 text-sm font-semibold text-white hover:bg-[#7a52e0]">View</button>
                        </div>
                    </div>
                {/each}
            {/if}
        </div>
    </div>

    <div class="flex-1 relative">
        {#if !isSidebarOpen}
            <button class="absolute top-4 left-4 z-30 bg-white p-3 rounded-xl shadow-md" on:click={() => isSidebarOpen = true}><MessageSquare /></button>
        {/if}
        <BaseMap on:load={handleMapLoad} />
    </div>
    
    {#if showNotification}
        <div class="fixed top-20 left-1/2 z-50 flex -translate-x-1/2 items-center gap-3 rounded-full bg-green-600 px-6 py-3 text-white shadow-2xl">
            <CheckCircle class="h-5 w-5" /> <span class="font-medium">{notificationMessage}</span>
        </div>
    {/if}
</div>