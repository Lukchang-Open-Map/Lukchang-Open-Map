<script>
	import { onMount, mount } from 'svelte';
	import { fade } from 'svelte/transition';
	import { userStore } from '$lib/stores/userStore.js';
	import { goto } from '$app/navigation';

	import BaseMap from '$lib/component/map/BaseMap.svelte';
	import Navbar from '$lib/component/layout/Navbar.svelte';
	import CustomMarker from '$lib/component/map/CustomMarker.svelte';
	import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
	import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
	import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
	import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
	import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
	import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';

	import { Crosshair } from 'lucide-svelte';
	import { CATEGORY_DISPLAY_NAMES, BLOCKED_MODAL_CONFIG } from '$lib/constant/map-config.js';
	import { generateUUID } from '$lib/utils/generators.js';
	import { timeAgo } from '$lib/utils/formatting.js'; 

	let mapInstance;
	let maplibreglInstance;
	let isMobile = false;
	let showSplash = true;

	// UI State
	let selectedCategory = null;
	let showDetailForm = false;
	let pinCoordinates = null;
	let isMobileCategorySheetOpen = false;
	let showSendHelpModal = false;
	let isFilterSidebarOpen = false;
	let isPointOrLineModalOpen = false;
	let modalConfig = {};

	// Line Drawing State
	let isDrawingLine = false;
	let drawingLineCategory = '';
	let currentLinePoints = [];
	let lineVertexMarkers = [];

	onMount(async () => {
		isMobile = window.innerWidth < 768;
		if (!$userStore) goto('/login');
		setTimeout(() => (showSplash = false), 2000);
	});

	function handleMapLoad({ detail }) {
		mapInstance = detail.map;
		maplibreglInstance = detail.maplibregl;

		// Setup Line Drawing Sources
		mapInstance.addSource('temp-line-source', {
			type: 'geojson',
			data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } }
		});
		mapInstance.addLayer({
			id: 'temp-line-layer',
			type: 'line',
			source: 'temp-line-source',
			paint: { 'line-color': '#F97316', 'line-width': 5, 'line-dasharray': [2, 2] }
		});
	}

	function handleMapClick({ detail: e }) {
		if (isDrawingLine) {
			const coords = e.lngLat.toArray();
			currentLinePoints.push(coords);
			updateTempLine();

			const el = document.createElement('div');
			el.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
			const marker = new maplibreglInstance.Marker({ element: el })
				.setLngLat(coords)
				.addTo(mapInstance);
			lineVertexMarkers.push(marker);
		} else if (selectedCategory && !showDetailForm) {
			pinCoordinates = e.lngLat;
			showDetailForm = true;
		}
	}

	function updateTempLine() {
		mapInstance
			.getSource('temp-line-source')
			.setData({
				type: 'Feature',
				geometry: { type: 'LineString', coordinates: currentLinePoints }
			});
	}

	function addPinToMap(data) {
		const el = document.createElement('div');
		mount(CustomMarker, { target: el, props: { category: data.category } });

		const popupHTML = `<div class="p-2 font-kanit"><h3 class="font-bold">${data.title}</h3><p class="text-sm">${data.description}</p></div>`;
		const popup = new maplibreglInstance.Popup({ offset: 25, className: 'cmu-popup' }).setHTML(
			popupHTML
		);

		new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
			.setLngLat([data.coordinates.lng, data.coordinates.lat])
			.setPopup(popup)
			.addTo(mapInstance);
	}

	function handlePinSubmit(e) {
		addPinToMap(e.detail);
		showDetailForm = false;
		selectedCategory = null;
	}

	function handleCategorySelect(e) {
		const category = e.detail;
		if (category === 'blocked' || category === 'traffic_general') {
			modalConfig = BLOCKED_MODAL_CONFIG; // ใช้ค่าคงที่ที่แยกไว้
			isPointOrLineModalOpen = true;
		} else {
			selectedCategory = category;
		}
	}

	function startLineDrawing() {
		isPointOrLineModalOpen = false;
		isDrawingLine = true;
		drawingLineCategory = 'blocked-line';
		currentLinePoints = [];
		mapInstance.getCanvas().style.cursor = 'crosshair';
	}

	function cancelAll() {
		selectedCategory = null;
		showDetailForm = false;
		isDrawingLine = false;
		currentLinePoints = [];
		lineVertexMarkers.forEach((m) => m.remove());
		lineVertexMarkers = [];
		if (mapInstance) {
			mapInstance.getCanvas().style.cursor = '';
			updateTempLine();
		}
	}

	function finishLineDrawing() {
		// Logic จบการวาดเส้น (Mock)
		addPinToMap({
			category: 'blocked',
			coordinates: { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] },
			title: 'Road Closed',
			description: 'Line report'
		});
		cancelAll();
	}
</script>

<div class="font-kanit relative h-screen w-full overflow-hidden bg-white">
	{#if showSplash}
		<div class="fixed inset-0 z-[100] flex items-center justify-center bg-white" out:fade>
			<h1 class="text-4xl font-bold text-[#8F66FF]">ลูกช้าง Maps</h1>
		</div>
	{/if}

	<BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

	{#if !selectedCategory && !isDrawingLine}
		<Navbar on:toggleSidebar={() => (isFilterSidebarOpen = true)} />
	{/if}

	{#if !selectedCategory && !isDrawingLine}
		{#if isMobile}
			<button
				class="absolute right-4 bottom-8 z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-3xl text-white shadow-xl"
				on:click={() => (isMobileCategorySheetOpen = true)}>+</button
			>
		{:else}
			<PinCategoryPanel
				on:select={(e) => (selectedCategory = e.detail)}
				on:sendHelp={() => (showSendHelpModal = true)}
				on:showOptions={handleCategorySelect}
			/>
		{/if}
	{/if}

	{#if selectedCategory || isDrawingLine}
		<div class="absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
			<button class="btn rounded-full bg-white px-8 text-black shadow-lg" on:click={cancelAll}
				>Cancel</button
			>
			{#if isDrawingLine}
				<button
					class="btn rounded-full bg-[#8F66FF] px-8 text-white shadow-lg"
					on:click={finishLineDrawing}>Finish</button
				>
			{:else if !showDetailForm}
				<button
					class="btn rounded-full bg-[#8F66FF] px-8 text-white shadow-lg"
					on:click={() => (showDetailForm = true)}>Next</button
				>
			{/if}
		</div>
		<div
			class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-1/2"
		>
			<Crosshair class="h-8 w-8 text-red-500" />
		</div>
	{/if}

	{#if showDetailForm}
		<PinDetailForm
			{isMobile}
			category={selectedCategory}
			coordinates={pinCoordinates}
			on:close={() => (showDetailForm = false)}
			on:submit={handlePinSubmit}
		/>
	{/if}
	{#if isMobileCategorySheetOpen}
		<MobileCategorySheet
			on:close={() => (isMobileCategorySheetOpen = false)}
			on:select={(e) => {
				isMobileCategorySheetOpen = false;
				selectedCategory = e.detail;
			}}
			on:showOptions={handleCategorySelect}
		/>
	{/if}
	{#if showSendHelpModal}
		<SendHelpConfirmModal
			on:close={() => (showSendHelpModal = false)}
			on:confirm={() => {
				showSendHelpModal = false;
				alert('Alert Sent!');
			}}
		/>
	{/if}
	{#if isFilterSidebarOpen}
		<FilterSidebar filters={{}} on:close={() => (isFilterSidebarOpen = false)} />
	{/if}
	{#if isPointOrLineModalOpen}
		<PointOrLineModal
			on:close={() => (isPointOrLineModalOpen = false)}
			on:selectPoint={() => {
				isPointOrLineModalOpen = false;
				selectedCategory = 'blocked';
			}}
			on:selectLine={startLineDrawing}
		/>
	{/if}
</div>
