<script>
	import { onMount, mount } from 'svelte';
	import { fade, fly } from 'svelte/transition';
	import { userStore } from '$lib/stores/userStore.js';
	import { goto } from '$app/navigation';

	// Components
	import BaseMap from '$lib/component/map/BaseMap.svelte';
	import Navbar from '$lib/component/layout/Navbar.svelte';
	import CustomMarker from '$lib/component/map/CustomMarker.svelte';
	import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
	import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
	import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
	import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
	import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
	import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';

	// Icons & Config
	import { Crosshair } from 'lucide-svelte';
	import { CATEGORY_DISPLAY_NAMES, BLOCKED_MODAL_CONFIG } from '$lib/constant/map-config.js';
	import { generateUUID } from '$lib/utils/generators.js';
	import { timeAgo } from '$lib/utils/formatting.js';
	import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

	// Map State
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

	// Filter State
	let filterState = {
		accident: true,
		blocked: true,
		beware: true,
		flood: true,
		send_help: true,
		traffic_general: true,
		parking: true,
		events: true,
		map_chat: true,
		lost_found: true
	};

	// Line Drawing State
	let isDrawingLine = false;
	let drawingLineCategory = '';
	let currentLinePoints = [];
	let lineVertexMarkers = [];
	let showToast = false;
	let toastMessage = '';

	// Coordinates for the allowed area
	const focusAreaCoordinates = [
		[98.9601657275698, 18.79084270775664],
		[98.96211706674501, 18.795420821749346],
		[98.95910521714836, 18.803934176372266],
		[98.96025056840341, 18.80566088916268],
		[98.95049387252698, 18.81023860009296],
		[98.9480334883495, 18.810640147739676],
		[98.94858495376855, 18.80939534691305],
		[98.947863806682, 18.809074106494478],
		[98.94735476167983, 18.80939534691305],
		[98.94710023917867, 18.80803007089743],
		[98.94739718209661, 18.806383693906497],
		[98.94608214917417, 18.805620733252553],
		[98.94633667167534, 18.803934176372266],
		[98.94701539834494, 18.802609012678516],
		[98.94676087584384, 18.800079125740638],
		[98.94608214917417, 18.798512986198276],
		[98.94548826333823, 18.797830305426643],
		[98.94574278583934, 18.796705884002407],
		[98.94625183084156, 18.794898762407016],
		[98.96033540923719, 18.791163982975164]
	];

	onMount(async () => {
		initializeMapInteractions();
		isMobile = window.innerWidth < 768;

		if (!$userStore) {
			goto('/login');
			return;
		}
		if ($userStore.role === 'admin') {
			goto('/admin');
			return;
		}
		if ($userStore.role === 'security') {
			goto('/security');
			return;
		}

		await new Promise((resolve) => setTimeout(resolve, 3000));
		showSplash = false;
	});

	function handleMapLoad({ detail }) {
		mapInstance = detail.map;
		maplibreglInstance = detail.maplibregl;
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

		// Auto-focus to the specific area defined by the coordinates

		// Calculate the bounds of the area
		const bounds = new maplibreglInstance.LngLatBounds();
		focusAreaCoordinates.forEach((coord) => {
			bounds.extend(coord);
		});

		// Fit the map to the bounds with some padding
		mapInstance.fitBounds(bounds, {
			padding: 50,
			duration: 1500
		});

		// Add a highlighted line around the area
		const areaLineId = 'focus-area-line';
		const areaSourceId = 'focus-area-source';

		// Create a LineString feature with the coordinates
		const areaFeature = {
			type: 'Feature',
			properties: {},
			geometry: {
				type: 'LineString',
				coordinates: focusAreaCoordinates
			}
		};

		// Add the source for the area line
		mapInstance.addSource(areaSourceId, {
			type: 'geojson',
			data: areaFeature
		});

		// Add the layer for the area line with highlighting
		mapInstance.addLayer({
			id: areaLineId,
			type: 'line',
			source: areaSourceId,
			layout: {
				'line-join': 'round',
				'line-cap': 'round'
			},
			paint: {
				'line-color': '#8F66FF', // Purple color to match the theme
				'line-width': 4,
				'line-opacity': 0.8
			}
		});
	}

	// Check if a point is within the allowed area using ray casting algorithm
	function isPointInArea(point, polygon) {
		let x = point[0],
			y = point[1];
		let inside = false;

		for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
			let xi = polygon[i][0],
				yi = polygon[i][1];
			let xj = polygon[j][0],
				yj = polygon[j][1];

			let intersect = yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
			if (intersect) inside = !inside;
		}

		return inside;
	}

	function handleMapClick({ detail: e }) {
		if (isDrawingLine) {
			const coords = e.lngLat.toArray();

			// Check if the coordinates are within the allowed area
			if (!isPointInArea(coords, focusAreaCoordinates)) {
				// Show a toast message informing the user
				toastMessage = 'Lines can only be drawn within the specified area';
				showToast = true;
				setTimeout(() => (showToast = false), 3000);
				return; // Don't add the point to the line
			}

			currentLinePoints.push(coords);
			updateTempLine();
			const el = document.createElement('div');
			el.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
			const marker = new maplibreglInstance.Marker({ element: el })
				.setLngLat(coords)
				.addTo(mapInstance);
			lineVertexMarkers.push(marker);
		}
	}

	function findUserLocation() {
		if (!navigator.geolocation) return alert('Geolocation not supported');
		navigator.geolocation.getCurrentPosition(
			(pos) => {
				const { longitude, latitude } = pos.coords;
				new maplibreglInstance.Marker({ color: '#8F66FF' })
					.setLngLat([longitude, latitude])
					.addTo(mapInstance);
				mapInstance.flyTo({ center: [longitude, latitude], zoom: 16 });
			},
			() => alert('Could not get location')
		);
	}

	function handleNextStep() {
		if (mapInstance) {
			const center = mapInstance.getCenter();
			const currentCoords = [center.lng, center.lat];

			// Check if the coordinates are within the allowed area
			if (!isPointInArea(currentCoords, focusAreaCoordinates)) {
				// Show a toast message informing the user
				toastMessage = 'Pins can only be placed within the specified area';
				showToast = true;
				setTimeout(() => (showToast = false), 3000);
				return; // Don't proceed with showing the detail form
			}

			pinCoordinates = { lng: center.lng, lat: center.lat };
			showDetailForm = true;
		}
	}

	function updateTempLine() {
		mapInstance.getSource('temp-line-source').setData({
			type: 'Feature',
			geometry: { type: 'LineString', coordinates: currentLinePoints }
		});
	}

	function addPermanentLineToMap(points, category) {
		const lineId = generateUUID();
		const lineColor = category.includes('blocked') ? '#F97316' : '#EF4444';
		mapInstance.addSource(`perm-line-source-${lineId}`, {
			type: 'geojson',
			data: { type: 'Feature', geometry: { type: 'LineString', coordinates: points } }
		});
		mapInstance.addLayer({
			id: `perm-line-layer-${lineId}`,
			type: 'line',
			source: `perm-line-source-${lineId}`,
			layout: { 'line-join': 'round', 'line-cap': 'round' },
			paint: { 'line-color': lineColor, 'line-width': 6, 'line-opacity': 0.8 }
		});
	}

	function addPinToMap(data) {
		const el = document.createElement('div');
		mount(CustomMarker, { target: el, props: { category: data.category } });
		const pinId = data.id || generateUUID();
		const likes = data.likes || 0;
		const dislikes = data.dislikes || 0;
		const imageHTML = data.photoPreviewUrl
			? `<div style="width: 100%; height: 140px; background-image: url('${data.photoPreviewUrl}'); background-size: cover; background-position: center; border-radius: 12px; margin-bottom: 12px;"></div>`
			: '';
		const popupHTML = `
            <div style="font-family: 'Kanit', sans-serif; min-width: 200px; padding: 4px;">
                ${imageHTML}
                <h3 style="font-size: 20px; font-weight: 900; color: #000; margin: 0 0 12px 0; line-height: 1.2;">${data.title}</h3>
                <div style="display: flex; justify-content: space-between; align-items: flex-end;">
                    <div style="font-size: 13px; line-height: 1.4; color: #6B7280;">
                        <span>report by</span><br><span style="color: #1F2937; font-weight: 700;">${data.reporter || 'anonymous'}</span><br><span>${timeAgo(data.timestamp)}</span>
                    </div>
                    <div style="display: flex; gap: 16px; align-items: center;">
                        <div style="display: flex; align-items: center; gap: 6px;"><button id="like-button-${pinId}" onclick="window.handleLike('${pinId}')" style="background: none; border: none; cursor: pointer; padding: 0; display: flex; align-items: center;"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg></button><span id="like-count-${pinId}" style="font-weight: 800; font-size: 16px; color: #374151;">${likes}</span></div>
                        <div style="display: flex; align-items: center; gap: 6px;"><button id="dislike-button-${pinId}" onclick="window.handleDislike('${pinId}')" style="background: none; border: none; cursor: pointer; padding: 0; display: flex; align-items: center;"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: scaleY(-1);"><path d="M7 10v12"/><path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z"/></svg></button><span id="dislike-count-${pinId}" style="font-weight: 800; font-size: 16px; color: #374151;">${dislikes}</span></div>
                    </div>
                </div>
            </div>`;
		const popup = new maplibreglInstance.Popup({
			offset: 35,
			className: 'cmu-popup',
			closeButton: false,
			maxWidth: '300px'
		}).setHTML(popupHTML);
		new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
			.setLngLat([data.coordinates.lng, data.coordinates.lat])
			.setPopup(popup)
			.addTo(mapInstance);
	}

	function handlePinSubmit(e) {
		const formData = e.detail;
		if (formData.visibility === 'public') {
			addPinToMap(formData);
			toastMessage = 'Post published on map';
		} else {
			toastMessage = 'Report sent to security staff';
		}
		showDetailForm = false;
		selectedCategory = null;
		showToast = true;
		setTimeout(() => (showToast = false), 3000);
	}

	function handleCategorySelect(e) {
		const category = e.detail;

		isMobileCategorySheetOpen = false;

		if (category === 'send_help') {
			showSendHelpModal = true;
			return;
		}

		if (category === 'blocked') {
			modalConfig = BLOCKED_MODAL_CONFIG;
			isPointOrLineModalOpen = true;
		} else if (category === 'traffic_general') {
			isPointOrLineModalOpen = false;
			isDrawingLine = true;
			drawingLineCategory = 'traffic_general-line';
			currentLinePoints = [];
			if (mapInstance) {
				mapInstance.getCanvas().style.cursor = 'crosshair';
				if (mapInstance.getLayer('temp-line-layer')) {
					mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
				}
			}
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
		mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
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
		if (currentLinePoints.length < 2) {
			alert('Please click on the map to draw at least 2 points.');
			return;
		}

		// Validate that all line points are within the allowed area
		const allPointsInArea = currentLinePoints.every((point) =>
			isPointInArea(point, focusAreaCoordinates)
		);
		if (!allPointsInArea) {
			toastMessage = 'Lines can only be drawn within the specified area';
			showToast = true;
			setTimeout(() => (showToast = false), 3000);
			return;
		}

		addPermanentLineToMap(currentLinePoints, drawingLineCategory);
		addPinToMap({
			category: drawingLineCategory.includes('traffic') ? 'traffic_general' : 'blocked',
			coordinates: { lng: currentLinePoints[0][0], lat: currentLinePoints[0][1] },
			title: drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off / Closed',
			description: drawingLineCategory.includes('traffic')
				? 'Heavy traffic reported.'
				: 'Reported road closure area.',
			reporter: $userStore?.name || 'Anonymous',
			timestamp: new Date().toISOString(),
			likes: 0,
			dislikes: 0
		});
		toastMessage = 'Route reported successfully';
		showToast = true;
		setTimeout(() => (showToast = false), 3000);
		cancelAll();
	}
</script>

<svelte:head>
	<script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
</svelte:head>

<div class="font-kanit relative h-screen w-full overflow-hidden bg-white">
	{#if showSplash}
		<div
			class="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-white"
			out:fade={{ duration: 500 }}
		>
			<lottie-player
				src="/loading.json"
				background="transparent"
				speed="1"
				style="width: 450px; height: 450px;"
				loop
				autoplay
			></lottie-player>
			<div class="relative z-10 -mt-10 text-center">
				<h1 class="text-4xl font-bold tracking-wide text-[#8F66FF]">ลูกช้าง Maps</h1>
				<p class="mt-2 text-base font-light tracking-widest text-gray-400">
					COMMUNITY SAFETY PLATFORM
				</p>
			</div>
		</div>
	{/if}

	<BaseMap on:load={handleMapLoad} on:click={handleMapClick} />

	{#if !showSplash}
		{#if !selectedCategory && !isDrawingLine}
			<Navbar on:toggleSidebar={() => (isFilterSidebarOpen = true)} />
		{/if}

		{#if !selectedCategory && !isDrawingLine}
			{#if isMobile}
				<button
					class="absolute right-4 bottom-13 z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-3xl text-white shadow-xl transition-transform active:scale-95"
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

		{#if selectedCategory && !showDetailForm && !isDrawingLine}
			<div
				class="pointer-events-none absolute top-24 right-0 left-0 z-30 flex justify-center"
				in:fly={{ y: -20, duration: 300 }}
			>
				<div
					class="flex items-center gap-2 rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg"
				>
					<span class="text-sm font-medium text-gray-600">Create post:</span>
					<span class="text-sm font-bold text-[#8F66FF] uppercase"
						>{CATEGORY_DISPLAY_NAMES[selectedCategory]}</span
					>
				</div>
			</div>
			<div
				class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-full pb-1 drop-shadow-xl"
			>
				<svg
					width="48"
					height="48"
					viewBox="0 0 24 24"
					fill="none"
					xmlns="http://www.w3.org/2000/svg"
					><path
						d="M12 0C7.58 0 4 3.58 4 8C4 13.5 12 24 12 24C12 24 20 13.5 20 8C20 3.58 16.42 0 12 0Z"
						fill="#EF4444"
					/><circle cx="12" cy="8" r="3.5" fill="white" /></svg
				>
			</div>
			<div class="absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
				<button
					class="btn w-32 rounded-full border-gray-200 bg-white px-8 font-bold text-gray-700 shadow-lg hover:bg-gray-50"
					on:click={cancelAll}>Cancel</button
				>
				<button
					class="btn w-32 rounded-full border-none bg-[#8F66FF] px-8 font-bold text-white shadow-lg hover:bg-[#7a52e0]"
					on:click={handleNextStep}>Next</button
				>
			</div>
		{/if}

		{#if isDrawingLine}
			<div class="pointer-events-none absolute top-24 right-0 left-0 z-30 flex justify-center">
				<div class="rounded-full border border-gray-100 bg-white px-6 py-3 shadow-lg">
					<span
						class="font-bold {drawingLineCategory.includes('traffic')
							? 'text-red-600'
							: 'text-orange-600'} text-sm"
					>
						Drawing {drawingLineCategory.includes('traffic') ? 'Traffic Jam' : 'Road Off'} (Tap map to
						add points)
					</span>
				</div>
			</div>
			<div class="absolute right-0 bottom-8 left-0 z-50 flex justify-center gap-4 px-4">
				<button
					class="btn rounded-full border-gray-200 bg-white px-8 text-black shadow-lg"
					on:click={cancelAll}>Cancel</button
				>
				<button
					class="btn rounded-full bg-[#8F66FF] px-8 text-white shadow-lg hover:bg-[#7a52e0]"
					on:click={finishLineDrawing}>Finish</button
				>
			</div>
		{/if}

		{#if showToast}
			<div class="pointer-events-none absolute top-24 right-0 left-0 z-50 flex justify-center">
				<div
					class="flex animate-bounce items-center gap-2 rounded-full border border-gray-200 bg-white px-6 py-3 shadow-lg"
				>
					<span class="font-bold text-green-600">{toastMessage}</span>
				</div>
			</div>
		{/if}

		<button
			class="absolute z-40 flex items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100 active:scale-95 {isMobile
				? 'right-4 bottom-32 h-12 w-12'
				: 'right-4 bottom-38 h-10 w-10'}"
			on:click={findUserLocation}
			title="Find my location"
		>
			<Crosshair class="h-6 w-6 text-gray-600" />
		</button>

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
				on:select={handleCategorySelect}
				on:showOptions={handleCategorySelect}
			/>
		{/if}

		{#if showSendHelpModal}
			<SendHelpConfirmModal
				on:close={() => (showSendHelpModal = false)}
				on:confirm={() => {
					showSendHelpModal = false;
					toastMessage = 'Emergency alert sent to security!';
					showToast = true;
					setTimeout(() => (showToast = false), 3000);
				}}
			/>
		{/if}

		{#if isFilterSidebarOpen}
			<FilterSidebar bind:filters={filterState} on:close={() => (isFilterSidebarOpen = false)} />
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

		<img src="/logo.svg" alt="Logo" class="absolute bottom-4 left-4 z-30 h-8" />
	{/if}
</div>

<style>
	:global(.cmu-popup .maplibregl-popup-content) {
		border-radius: 20px !important;
		padding: 16px !important;
		box-shadow:
			0 10px 25px -5px rgba(0, 0, 0, 0.1),
			0 8px 10px -6px rgba(0, 0, 0, 0.1) !important;
		border: none !important;
	}
	:global(.cmu-popup .maplibregl-popup-tip) {
		display: none !important;
	}
	.font-kanit {
		font-family: 'Kanit', sans-serif;
	}
</style>
