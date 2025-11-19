<script>
	import { onMount, mount } from 'svelte';
	import { userStore } from '$lib/stores/userStore.js';
	import BaseMap from '$lib/component/map/BaseMap.svelte';
	import Navbar from '$lib/component/layout/Navbar.svelte';
	import CustomMarker from '$lib/component/map/CustomMarker.svelte';
	import PinCategoryPanel from '$lib/component/map/PinCategoryPanel.svelte';
	import FilterSidebar from '$lib/component/map/FilterSidebar.svelte';
	import PinDetailForm from '$lib/component/common/PinDetailForm.svelte';
	import PointOrLineModal from '$lib/component/common/PointOrLineModal.svelte';
	import MobileCategorySheet from '$lib/component/map/MobileCategorySheet.svelte';
	import SendHelpConfirmModal from '$lib/component/common/SendHelpConfirmModal.svelte';
	import {
		Shield,Search,MessageSquare,CheckCircle,ChevronLeft,
		Crosshair,Construction,RouteOff
	} from 'lucide-svelte';
	import { CATEGORY_STYLES, CATEGORY_DISPLAY_NAMES } from '$lib/constant/map-config.js';
	import { timeAgo } from '$lib/utils/formatting.js';
	import { initializeMapInteractions } from '$lib/utils/map-interactions.js';

	// ============================================================================
	// MOCK DATA
	// ============================================================================
	const SECURITY_LOCATIONS = [
		{ id: 0, name: 'ทางเข้าวงเวียน', lng: 98.95315768199401, lat: 18.795269111341696 },
		{ id: 1, name: 'สี่แยกสถาปัต', lng: 98.95043693938567, lat: 18.79684741671042 },
		{ id: 2, name: 'ทางเข้าหน้ามอ', lng: 98.95438058092196, lat: 18.80722761195173 },
		{ id: 3, name: 'ทางออกหน้ามอ', lng: 98.95315671360765, lat: 18.80615435722116 },
		{ id: 4, name: 'อ่างแก้ว', lng: 98.95043172833226, lat: 18.805220006467806 },
		{ id: 5, name: 'แมสคอม', lng: 98.94818999196912, lat: 18.80199061126453 },
		{ id: 6, name: 'อ่างตาด', lng: 98.94910352845847, lat: 18.803583664409146 },
		{ id: 7, name: 'อมช', lng: 98.95112492412699, lat: 18.79919173363757 },
		{ id: 9, name: 'สี่แยกสนามกีฬา', lng: 98.95594476882661, lat: 18.796233122362295 },
		{ id: 10, name: 'ศึกษา', lng: 98.95491536596535, lat: 18.79607521853582 }
	];

	let posts = $state([
		{
			id: 'post_001',
			category: 'accident',
			title: 'รถเครื่องชนกัน',
			description: 'เกิดอุบัติเหตุที่หน้ามอ ต้องการความช่วยเหลือ',
			coordinates: { lng: 98.9545, lat: 18.807 },
			reporter: { name: 'Somchai Lertsuk', displayAs: 'Anonymous' },
			timestamp: new Date(Date.now() - 3600000).toISOString(),
			likes: 12,
			dislikes: 2,
			status: 'active'
		},
		{
			id: 'post_002',
			category: 'flood',
			title: 'น้ำท่วมถนน',
			description: 'น้ำท่วมสูงประมาณ 20 ซม. ที่อ่างแก้ว',
			coordinates: { lng: 98.9504, lat: 18.8052 },
			reporter: { name: 'Nittaya P.', displayAs: 'Nittaya P.' },
			timestamp: new Date(Date.now() - 7200000).toISOString(),
			likes: 8,
			dislikes: 0,
			status: 'active'
		},
		{
			id: 'post_003',
			category: 'map_chat',
			title: 'ใครรู้พิกัดร้านกาแฟดีๆ',
			description: 'แนะนำร้านกาแฟใกล้ห้องสมุดหน่อยครับ',
			coordinates: { lng: 98.9517, lat: 18.8011 },
			reporter: { name: 'John Doe', displayAs: 'Anonymous' },
			timestamp: new Date(Date.now() - 10800000).toISOString(),
			likes: 15,
			dislikes: 1,
			status: 'active'
		},
		{
			id: 'post_004',
			category: 'parking',
			title: 'ที่จอดรถเต็ม',
			description: 'ที่จอดรถม่วงเต็มแล้ว ห้ามเข้า',
			coordinates: { lng: 98.9524, lat: 18.7993 },
			reporter: { name: 'Staff User', displayAs: 'Staff User' },
			timestamp: new Date(Date.now() - 14400000).toISOString(),
			likes: 20,
			dislikes: 3,
			photoUrl: 'https://via.placeholder.com/300x200',
			status: 'active'
		}
	]);

	// ============================================================================
	// STATE MANAGEMENT
	// ============================================================================
	let mapInstance = null;
	let maplibreglInstance = null;
	let viewMode = $state('admin'); // 'admin' or 'user'
	let activeTab = $state('posts');
	let isSidebarOpen = $state(true);
	let selectedPost = $state(null);
	let selectedLocation = $state(null);
	let searchQuery = $state('');
	let categoryFilter = $state('all');
	let showNotification = $state(false);
	let notificationMessage = $state('');
	let userLocationMarker = null;
	let isMobile = false;

	// User mode states
	let isFilterSidebarOpen = $state(false);
	let selectedCategory = $state(null);
	let showDetailForm = $state(false);
	let pinCoordinates = $state(null);
	let isPointOrLineModalOpen = $state(false);
	let modalConfig = $state({});
	let isDrawingLine = $state(false);
	let drawingLineCategory = $state('blocked-line');
	let currentLinePoints = $state([]);
	let lineVertexMarkers = $state([]);
	let isMobileCategorySheetOpen = $state(false);
	let showSendHelpModal = $state(false);
	let showToast = $state(false);
	let toastMessage = $state('');
	let toastTimeout;

	let filterState = $state({
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
	});

	// ============================================================================
	// DERIVED STATE
	// ============================================================================
	const currentStyle = $derived(
		CATEGORY_STYLES[selectedCategory] || CATEGORY_STYLES['accident']
	);
	
	const filteredPosts = $derived(
		posts.filter((post) => {
			const matchesSearch =
				post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
				post.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
				post.reporter.name.toLowerCase().includes(searchQuery.toLowerCase());
			const matchesCategory = categoryFilter === 'all' || post.category === categoryFilter;
			return matchesSearch && matchesCategory;
		})
	);

	const sortedPosts = $derived(filteredPosts.sort((a, b) => b.dislikes - a.dislikes));

	const categoryCount = $derived((category) => {
		if (category === 'all') return posts.length;
		return posts.filter((p) => p.category === category).length;
	});

	const categoryCounts = $derived(
		Object.keys(CATEGORY_DISPLAY_NAMES).reduce((acc, cat) => {
			acc[cat] = posts.filter((p) => p.category === cat).length;
			return acc;
		}, {})
	);

	// Update map cursor based on view mode and state
	$effect(() => {
		if (mapInstance && viewMode === 'user') {
			if (selectedCategory && selectedCategory !== 'send_help') {
				mapInstance.getCanvas().style.cursor = 'crosshair';
			} else if (!isDrawingLine) {
				mapInstance.getCanvas().style.cursor = '';
			}
		} else if (mapInstance && viewMode === 'admin') {
			mapInstance.getCanvas().style.cursor = '';
		}
	});

	// ============================================================================
	// LIFECYCLE
	// ============================================================================
	onMount(() => {
		isMobile = window.innerWidth < 768;
		initializeMapInteractions();
	});

	// ============================================================================
	// ADMIN MODE HANDLERS
	// ============================================================================
	const showSuccess = (message) => {
		notificationMessage = message;
		showNotification = true;
		setTimeout(() => (showNotification = false), 3000);
	};

	const handleDeletePost = async (postId) => {
		posts = posts.filter((p) => p.id !== postId);
		selectedPost = null;
		showSuccess('Post deleted successfully');
	};

	const flyToPost = (post) => {
		if (mapInstance) {
			mapInstance.flyTo({
				center: [post.coordinates.lng, post.coordinates.lat],
				zoom: 17,
				duration: 1500
			});
		}
		selectedPost = post;
	};

	const flyToLocation = (location) => {
		if (mapInstance) {
			mapInstance.flyTo({
				center: [location.lng, location.lat],
				zoom: 17,
				duration: 1500
			});
		}
		selectedLocation = location;
	};

	const toggleViewMode = (mode) => {
		viewMode = mode;
		if (mode === 'user') {
			isSidebarOpen = false;
			selectedPost = null;
			selectedLocation = null;
			cancelPinning();
		} else {
			cancelPinning();
			isSidebarOpen = true;
		}
	};

	// ============================================================================
	// USER MODE HANDLERS
	// ============================================================================
	function cancelPinning() {
		selectedCategory = null;
		isDrawingLine = false;
		currentLinePoints = [];

		for (const marker of lineVertexMarkers) {
			marker.remove();
		}
		lineVertexMarkers = [];

		if (mapInstance) {
			mapInstance.getCanvas().style.cursor = '';
			updateLineOnMap('temp-line-source', []);
			if (mapInstance.getPaintProperty('temp-line-layer', 'line-color')) {
				mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
			}
		}
	}

	function goToNextStep() {
		const center = mapInstance.getCenter();
		pinCoordinates = center;
		showDetailForm = true;
	}

	function onFormClose() {
		showDetailForm = false;
		selectedCategory = null;
	}

	function handleCategorySelection(category) {
		if (category === 'send_help') {
			showSendHelpModal = true;
			return;
		}

		if (category === 'blocked' || category === 'traffic_general') {
			onShowOptions({ detail: category });
			return;
		}

		selectedCategory = category;
	}

	function onShowOptions(event) {
		const category = event.detail;

		if (category === 'blocked') {
			modalConfig = {
				type: 'blocked',
				title: 'Report Blocked Path',
				pointOption: {
					Icon: Construction,
					title: 'Obstacle',
					description: 'e.g., Fallen tree (Pin a point)'
				},
				lineOption: {
					Icon: RouteOff,
					title: 'Road Closed',
					description: 'e.g., Construction (Draw a line)'
				}
			};
			isPointOrLineModalOpen = true;
		} else if (category === 'traffic_general') {
			if (mapInstance.getPaintProperty('temp-line-layer', 'line-color')) {
				mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#EF4444');
			}
			isDrawingLine = true;
			drawingLineCategory = 'traffic_general-line';
			currentLinePoints = [];
			mapInstance.getCanvas().style.cursor = 'crosshair';
		}
	}

	function onSelectPoint() {
		isPointOrLineModalOpen = false;
		selectedCategory = modalConfig.type;
	}

	function onSelectLine() {
		isPointOrLineModalOpen = false;
		if (mapInstance.getPaintProperty('temp-line-layer', 'line-color')) {
			mapInstance.setPaintProperty('temp-line-layer', 'line-color', '#F97316');
		}
		isDrawingLine = true;
		drawingLineCategory = 'blocked-line';
		currentLinePoints = [];
		mapInstance.getCanvas().style.cursor = 'crosshair';
	}

	function handleSendHelpConfirm() {
		if (userLocationMarker) {
			const lngLat = userLocationMarker.getLngLat();
			pinCoordinates = { lng: lngLat.lng, lat: lngLat.lat };
		} else {
			const center = mapInstance.getCenter();
			pinCoordinates = { lng: center.lng, lat: center.lat };
		}
		showSuccessToast('Security Alerted');
		showSendHelpModal = false;
	}

	async function onFormSubmit(event) {
		const formData = event.detail;

		if (formData.visibility === 'public') {
			addPinToMap(formData);
			showSuccessToast(CATEGORY_DISPLAY_NAMES[formData.category]);
		} else {
			showSuccessToast('Report sent to staff');
		}

		onFormClose();
	}

	function showSuccessToast(message) {
		toastMessage = message;
		showToast = true;
		if (toastTimeout) clearTimeout(toastTimeout);
		toastTimeout = setTimeout(() => {
			showToast = false;
		}, 3000);
	}

	function updateLineOnMap(sourceId, points) {
		if (!mapInstance) return;
		const source = mapInstance.getSource(sourceId);
		if (source) {
			source.setData({
				type: 'Feature',
				geometry: { type: 'LineString', coordinates: points }
			});
		}
	}

	function submitLineDrawing() {
		if (currentLinePoints.length < 2) {
			cancelPinning();
			return;
		}

		const lineCategory = drawingLineCategory.replace('-line', '');
		const categoryName = lineCategory === 'blocked' ? 'Road Closed' : 'Traffic Jam';
		showSuccessToast(categoryName);

		cancelPinning();
	}

	function findUserLocation() {
		if (!navigator.geolocation) {
			alert('Geolocation is not supported by your browser.');
			return;
		}
		navigator.geolocation.getCurrentPosition(
			(position) => {
				const { longitude, latitude } = position.coords;
				if (userLocationMarker) userLocationMarker.remove();
				userLocationMarker = new maplibreglInstance.Marker({ color: '#8F66FF' })
					.setLngLat([longitude, latitude])
					.addTo(mapInstance);
				mapInstance.flyTo({ center: [longitude, latitude], zoom: 16 });
			},
			(error) => {
				console.error('Error getting location:', error.message);
				alert('Could not get your location.');
			}
		);
	}

	// ============================================================================
	// MAP INITIALIZATION
	// ============================================================================
	function handleMapLoad({ detail }) {
		mapInstance = detail.map;
		maplibreglInstance = detail.maplibregl;

		// Add security locations
		SECURITY_LOCATIONS.forEach((location) => {
			const securityEl = document.createElement('div');
			securityEl.innerHTML = `<img src="/security.svg" alt="Security" style="width: 60px; height: 60px;" />`;
			securityEl.style.cssText = 'cursor: pointer; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));';

			new maplibreglInstance.Marker({ element: securityEl, anchor: 'center' })
				.setLngLat([location.lng, location.lat])
				.setPopup(
					new maplibreglInstance.Popup({ offset: 25, closeButton: false, className: 'cmu-popup' })
						.setHTML(`
							<div class="p-1" style="min-width: 220px; font-family: 'Kanit', sans-serif;">
								<h3 class="font-bold text-lg text-blue-600 flex items-center gap-2">
									<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
										<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
									</svg>
									Security Guard
								</h3>
								<p class="text-sm text-gray-600 mt-1">${location.name}</p>
								<div class="mt-2 pt-2 border-t border-gray-200 text-xs text-gray-500">
									Status: <span class="text-green-600 font-semibold">On Duty</span>
								</div>
							</div>
						`)
				)
				.addTo(mapInstance);
		});

		// Add posts markers
		posts.forEach((post) => {
			addPinToMap(post);
		});

		// Add temporary line source
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

		// Handle map clicks
		mapInstance.on('click', (e) => {
			if (viewMode !== 'user') return;
			const coords = e.lngLat;

			if (isDrawingLine) {
				currentLinePoints.push(coords.toArray());
				const vertexEl = document.createElement('div');
				vertexEl.className = 'w-3 h-3 bg-white rounded-full border-2 border-orange-500 shadow-md';
				const vertexMarker = new maplibreglInstance.Marker({ element: vertexEl, anchor: 'center' })
					.setLngLat(coords)
					.addTo(mapInstance);
				lineVertexMarkers.push(vertexMarker);
				updateLineOnMap('temp-line-source', currentLinePoints);
			} else if (selectedCategory && !showDetailForm) {
				pinCoordinates = { lng: coords.lng, lat: coords.lat };
				showDetailForm = true;
			}
		});
	}

	function addPinToMap(formData) {
		const el = document.createElement('div');
		mount(CustomMarker, { target: el, props: { category: formData.category } });

		const popupHTML = `
			<div style="font-family: 'Kanit', sans-serif; min-width: 220px; padding: 8px;">
				<h3 style="font-weight: 700; font-size: 16px;">${formData.title}</h3>
				<p style="font-size: 13px; color: #6B7280;">${formData.description}</p>
				<div style="margin-top: 8px; font-size: 11px; color: #9CA3AF;">
					Reported by ${formData.reporter.name} • ${timeAgo(formData.timestamp)}
				</div>
			</div>
		`;

		const popup = new maplibreglInstance.Popup({ offset: 25, closeButton: false, className: 'cmu-popup' })
			.setHTML(popupHTML);

		new maplibreglInstance.Marker({ element: el, anchor: 'bottom' })
			.setLngLat([formData.coordinates.lng, formData.coordinates.lat])
			.setPopup(popup)
			.addTo(mapInstance);
	}
</script>

<div class="relative h-screen w-full font-kanit overflow-hidden">
	<!-- Map -->
	<div class="absolute inset-0 z-0">
		<BaseMap on:load={handleMapLoad} />
	</div>

	<!-- Navbar -->
	<Navbar 
		showMenuButton={true}
		showViewToggle={true}
		{viewMode}
		on:toggleSidebar={() => {
			if (viewMode === 'admin') isSidebarOpen = !isSidebarOpen;
			else isFilterSidebarOpen = true;
		}}
		on:switchView={(e) => toggleViewMode(e.detail)}
	/>

	<!-- Admin Sidebar -->
	{#if viewMode === 'admin'}
		<div class="absolute left-0 top-0 bottom-0 z-30 w-full md:w-[445px] bg-white shadow-2xl transition-transform transform {isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} pt-20">
			<!-- Header -->
			<div class="p-4 border-b bg-white flex justify-between items-center sticky top-0">
				<div class="flex items-center gap-2">
					<h2 class="text-xl font-bold">Admin Management</h2>
					{#if posts.length > 0}
						<span class="px-2 py-0.5 bg-red-500 text-white rounded-full text-xs font-bold">{posts.length}</span>
					{/if}
				</div>
				<button on:click={() => (isSidebarOpen = false)} class="p-2 hover:bg-gray-100 rounded-lg md:hidden">
					<ChevronLeft class="w-5 h-5" />
				</button>
			</div>

			<!-- Search & Filters -->
			<div class="p-4 border-b bg-gray-50">
				<div class="relative mb-3">
					<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
					<input
						type="text"
						placeholder="Search posts..."
						bind:value={searchQuery}
						class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-[#8F66FF]"
					/>
				</div>

				<div class="flex gap-2 overflow-x-auto pb-2">
					<button
						on:click={() => (categoryFilter = 'all')}
						class="px-3 py-1.5 text-xs rounded-full font-semibold whitespace-nowrap {categoryFilter === 'all' ? 'bg-[#8F66FF] text-white' : 'bg-white border text-gray-700'}"
					>
						All ({categoryCount('all')})
					</button>
					{#each Object.entries(CATEGORY_DISPLAY_NAMES) as [cat, displayName]}
						{#if categoryCounts[cat] > 0}
							<button
								on:click={() => (categoryFilter = cat)}
								class="px-3 py-1.5 text-xs rounded-full font-semibold whitespace-nowrap flex items-center gap-1 {categoryFilter === cat ? 'bg-[#8F66FF] text-white' : 'bg-white border text-gray-700'}"
							>
								<svelte:component this={CATEGORY_STYLES[cat].Icon} class="w-3 h-3" />
								{displayName} ({categoryCounts[cat]})
							</button>
						{/if}
					{/each}
				</div>
			</div>

			<!-- Tabs -->
			<div class="flex border-b bg-white">
				<button
					on:click={() => (activeTab = 'posts')}
					class="flex-1 px-4 py-3 text-sm font-semibold {activeTab === 'posts' ? 'border-b-2 border-[#8F66FF] text-[#8F66FF]' : 'text-gray-600'}"
				>
					<MessageSquare class="inline w-4 h-4 mr-2" />
					Posts ({sortedPosts.length})
				</button>
				<button
					on:click={() => (activeTab = 'security')}
					class="flex-1 px-4 py-3 text-sm font-semibold {activeTab === 'security' ? 'border-b-2 border-[#8F66FF] text-[#8F66FF]' : 'text-gray-600'}"
				>
					<Shield class="inline w-4 h-4 mr-2" />
					Security ({SECURITY_LOCATIONS.length})
				</button>
			</div>

			<!-- Content -->
			<div class="overflow-y-auto p-4 space-y-4 h-[calc(100vh-280px)]">
				{#if activeTab === 'posts'}
					{#if sortedPosts.length === 0}
						<div class="text-center py-12 text-gray-400">
							<MessageSquare class="w-16 h-16 mx-auto mb-3" />
							<p>No posts found</p>
						</div>
					{:else}
						{#each sortedPosts as post (post.id)}
							{@const style = CATEGORY_STYLES[post.category]}
							<div
								class="border-2 rounded-2xl p-4 cursor-pointer transition-all hover:shadow-lg {selectedPost?.id === post.id ? 'border-[#8F66FF] shadow-lg' : 'border-gray-200'}"
								on:click={() => flyToPost(post)}
							>
								<div class="flex items-center gap-2 mb-3">
									<div class="w-10 h-10 rounded-full flex items-center justify-center {style.bg}">
										<svelte:component this={style.Icon} class="w-5 h-5 {style.text}" />
									</div>
									<div class="flex-1">
										<span class="text-xs font-bold {style.text} uppercase">{CATEGORY_DISPLAY_NAMES[post.category]}</span>
										<div class="text-xs text-gray-500">{new Date(post.timestamp).toLocaleString()}</div>
									</div>
								</div>

								<h3 class="font-bold text-gray-900 mb-1">{post.title}</h3>
								<p class="text-sm text-gray-600 mb-3">{post.description}</p>

								<div class="text-xs text-gray-500 mb-3">
									Reported by <span class="font-semibold">{post.reporter.name}</span> • {timeAgo(post.timestamp)}
								</div>

								<div class="flex gap-2">
									<button
										on:click|stopPropagation={() => handleDeletePost(post.id)}
										class="flex-1 py-2 border border-red-300 text-red-600 rounded-lg font-semibold text-sm hover:bg-red-50"
									>
										Delete
									</button>
									<button
										on:click|stopPropagation={() => flyToPost(post)}
										class="flex-1 py-2 bg-[#8F66FF] text-white rounded-lg font-semibold text-sm hover:bg-[#7a52e0]"
									>
										View on Map
									</button>
								</div>
							</div>
						{/each}
					{/if}
				{:else}
					{#each SECURITY_LOCATIONS as location (location.id)}
						<div
							class="border-2 rounded-2xl p-4 cursor-pointer transition-all hover:shadow-lg {selectedLocation?.id === location.id ? 'border-blue-500 shadow-lg' : 'border-gray-200'}"
							on:click={() => flyToLocation(location)}
						>
							<div class="flex items-start gap-3">
								<div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
									<Shield class="w-5 h-5 text-blue-600" />
								</div>
								<div>
									<h4 class="font-bold">{location.name}</h4>
									<p class="text-xs text-gray-500">Station #{location.id}</p>
									<p class="text-xs text-gray-400 mt-1">📍 {location.lat.toFixed(5)}, {location.lng.toFixed(5)}</p>
								</div>
							</div>
						</div>
					{/each}
				{/if}
			</div>
		</div>
	{/if}

	<!-- User View UI -->
	{#if viewMode === 'user'}
		{#if !selectedCategory && !isDrawingLine && !showDetailForm}
			{#if isFilterSidebarOpen}
				<FilterSidebar bind:filters={filterState} on:close={() => (isFilterSidebarOpen = false)} />
			{/if}

			{#if !isMobile}
				<div class="absolute top-20 left-4 z-40">
					<PinCategoryPanel
						on:selectPinCategory={(e) => handleCategorySelection(e.detail)}
						on:showOptions={onShowOptions}
						on:sendHelp={() => (showSendHelpModal = true)}
					/>
				</div>
			{/if}

			{#if isMobile}
				<button
					class="fixed z-50 flex h-16 w-16 items-center justify-center rounded-full bg-[#8F66FF] text-white text-4xl shadow-xl"
					style="bottom: max(3rem, calc(3rem + env(safe-area-inset-bottom))); right: max(1rem, env(safe-area-inset-right));"
					on:click={() => (isMobileCategorySheetOpen = true)}
				>
					+
				</button>
			{/if}
		{/if}

		{#if isMobileCategorySheetOpen}
			<MobileCategorySheet
				on:close={() => (isMobileCategorySheetOpen = false)}
				on:select={(e) => {
					isMobileCategorySheetOpen = false;
					handleCategorySelection(e.detail);
				}}
				on:showOptions={onShowOptions}
			/>
		{/if}

		{#if isPointOrLineModalOpen}
			<PointOrLineModal
				on:close={() => (isPointOrLineModalOpen = false)}
				on:selectPoint={onSelectPoint}
				on:selectLine={onSelectLine}
				bind:title={modalConfig.title}
				bind:pointOption={modalConfig.pointOption}
				bind:lineOption={modalConfig.lineOption}
			/>
		{/if}

		{#if showSendHelpModal}
			<SendHelpConfirmModal
				on:confirm={handleSendHelpConfirm}
				on:close={() => (showSendHelpModal = false)}
			/>
		{/if}

		{#if selectedCategory && !showDetailForm && !isDrawingLine}
			<div class="pointer-events-none absolute top-1/2 left-1/2 z-10 -translate-x-1/2 -translate-y-1/2">
				<svg class="h-12 w-12 drop-shadow-lg" viewBox="0 0 24 24" fill="#FF494C">
					<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
					<circle cx="12" cy="8.5" r="2.5" fill="white"/>
				</svg>
			</div>

			<div class="pointer-events-none absolute top-4 left-4 right-4 z-30 flex justify-center" style="padding-top: max(1rem, env(safe-area-inset-top));">
				<div class="flex items-center gap-2 bg-white rounded-full px-4 py-2 shadow-md">
					<span class="font-medium">Create post:</span>
					<span class="font-bold {currentStyle.text}">
						{CATEGORY_DISPLAY_NAMES[selectedCategory]}
					</span>
				</div>
			</div>

			<div class="absolute z-[100] flex justify-center gap-3" style="bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom))); left: 0; right: 0; padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));">
				<button
					on:click={cancelPinning}
					class="rounded-full bg-white text-black shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'} px-6 py-3 font-medium"
				>
					Cancel
				</button>
				<button
					on:click={goToNextStep}
					class="rounded-full bg-[#8F66FF] text-white shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'} px-6 py-3 font-medium"
				>
					Next
				</button>
			</div>
		{/if}

		{#if isDrawingLine}
			<div class="pointer-events-none absolute top-4 left-4 right-4 z-30 flex justify-center" style="padding-top: max(1rem, env(safe-area-inset-top));">
				<div class="flex items-center gap-3 bg-white rounded-full px-4 py-2 shadow-md">
					{#if drawingLineCategory === 'blocked-line'}
						<span class="font-medium text-gray-800">Drawing Road Closure...</span>
						<span class="font-bold text-orange-600 text-sm">(Click to add points)</span>
					{:else}
						<span class="font-medium text-gray-800">Drawing Traffic Jam...</span>
						<span class="font-bold text-red-600 text-sm">(Click to add points)</span>
					{/if}
				</div>
			</div>

			<div class="absolute z-[100] flex justify-center gap-3" style="bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom))); left: 0; right: 0; padding-left: max(1rem, env(safe-area-inset-left)); padding-right: max(1rem, env(safe-area-inset-right));">
				<button
					on:click={cancelPinning}
					class="rounded-full bg-white text-black shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'} px-6 py-3 font-medium"
				>
					Cancel
				</button>
				<button
					on:click={submitLineDrawing}
					class="rounded-full bg-[#8F66FF] text-white shadow-md {isMobile ? 'flex-1 max-w-[45%]' : 'w-48'} px-6 py-3 font-medium"
				>
					Finish Drawing
				</button>
			</div>
		{/if}

		{#if showDetailForm}
			<PinDetailForm
				{isMobile}
				category={selectedCategory}
				coordinates={pinCoordinates}
				categoryDisplayNames={CATEGORY_DISPLAY_NAMES}
				on:close={onFormClose}
				on:submit={onFormSubmit}
			/>
		{/if}
	{/if}

	<!-- Notifications -->
	{#if showNotification}
		<div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-green-600 text-white px-6 py-3 rounded-full shadow-2xl flex items-center gap-3">
			<CheckCircle class="w-5 h-5" />
			<span class="font-medium">{notificationMessage}</span>
		</div>
	{/if}

	{#if showToast}
		<div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-white px-4 py-2 rounded-full shadow-lg flex items-center gap-2 border">
			<span class="font-medium text-gray-700">Post success:</span>
			<span class="font-bold text-green-600">{toastMessage}</span>
		</div>
	{/if}

	<!-- Crosshair Button -->
	<button
		class="absolute z-40 flex items-center justify-center rounded-full bg-white shadow-md hover:bg-gray-100 {isMobile ? 'h-9 w-9' : 'h-10 w-10 bottom-38 right-2'}"
		style="{isMobile ? 'bottom: max(8rem, calc(8rem + env(safe-area-inset-bottom))); right: max(1rem, env(safe-area-inset-right));' : ''}"
		on:click={findUserLocation}
	>
		<Crosshair class="{isMobile ? 'h-7 w-7' : 'h-6 w-6'}" />
	</button>

	<!-- Logo -->
	<img src="/logo.svg" alt="Logo" class="absolute z-30 h-8" style="bottom: max(1rem, env(safe-area-inset-bottom)); left: max(1rem, env(safe-area-inset-left));" />
</div>

<style>
	.font-kanit {
		font-family: 'Kanit', sans-serif;
	}

	.bottom-38 {
		bottom: 9.5rem;
	}

	:global(.cmu-popup .maplibregl-popup-content) {
		border-radius: 16px;
		padding: 12px;
		box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
		border: none;
	}

	:global(.cmu-popup .maplibregl-popup-tip) {
		display: none;
	}
</style>