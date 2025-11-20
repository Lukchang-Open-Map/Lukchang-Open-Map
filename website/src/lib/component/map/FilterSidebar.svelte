<script>
	import { createEventDispatcher } from 'svelte';
	import { fly } from 'svelte/transition';
	import {
		X,
		AlertTriangle,
		TrafficCone,
		HelpCircle,
		Droplet,
		LifeBuoy,
		CarFront,
		ParkingSquare,
		Briefcase,
		PartyPopper,
		MessageSquare
	} from 'lucide-svelte';

	export let filters;

	const dispatch = createEventDispatcher();

	const incidentFilters = [
		{ id: 'accident', label: 'Accident \n /Hazard', Icon: AlertTriangle, color: 'text-red-600' },
		{ id: 'blocked', label: 'Blocked', Icon: TrafficCone, color: 'text-orange-600' },
		{ id: 'beware', label: 'Beware', Icon: HelpCircle, color: 'text-gray-700' },
		{ id: 'flood', label: 'Flood', Icon: Droplet, color: 'text-blue-600' }
		// { id: 'send_help', label: 'Send Help', Icon: LifeBuoy, color: 'text-red-600' }
	];
	const generalFilters = [
		{ id: 'traffic_general', label: 'Traffic', Icon: CarFront, color: 'text-red-600' },
		{ id: 'parking', label: 'Parking', Icon: ParkingSquare, color: 'text-blue-600' },
		{ id: 'events', label: 'Events', Icon: PartyPopper, color: 'text-purple-600' },
		// { id: 'map_chat', label: 'Map Chat', Icon: MessageSquare, color: 'text-green-600' },
		{ id: 'lost_found', label: 'Lost & Found', Icon: Briefcase, color: 'text-orange-600' }
	];
</script>

<!-- Overlay -->
<div
	on:click={() => dispatch('close')}
	class="absolute inset-0 z-50 bg-black/50"
	transition:fly={{ duration: 300, x: 0, opacity: 0.5 }}
></div>

<!-- Sidebar -->
<div
	transition:fly={{ x: -320, duration: 300 }}
	class="safe-sidebar absolute top-0 left-0 z-50 h-full w-64 overflow-y-auto bg-white shadow-lg sm:w-80"
>
	<!-- Header with Close Button -->
	<div class="safe-sidebar-header mb-6 flex items-center justify-between">
		<h2 class="text-xl font-bold">Filter Pins</h2>
		<button
			on:click={() => dispatch('close')}
			class="-mr-2 rounded-full p-1 text-gray-500 hover:text-gray-800"
		>
			<X class="h-6 w-6" />
		</button>
	</div>

	<!-- Filter Sections -->
	<div class="safe-sidebar-content flex flex-col gap-6">
		<!-- Incident Report Filters -->
		<div>
			<h3 class="mb-2 font-semibold">Incident Report</h3>
			<div class="flex flex-col gap-2">
				{#each incidentFilters as filter (filter.id)}
					<label class="flex cursor-pointer items-center gap-3 rounded-lg p-2 hover:bg-gray-50">
						<svelte:component this={filter.Icon} class="h-5 w-5 {filter.color}" />
						<span class="flex-1">{filter.label}</span>
						<input
							type="checkbox"
							class="toggle toggle-primary"
							style="--tcb: #8F66FF; --tbc: #8F66FF;"
							bind:checked={filters[filter.id]}
						/>
					</label>
				{/each}
			</div>
		</div>

		<!-- General Report Filters -->
		<div>
			<h3 class="mb-2 font-semibold">General Report</h3>
			<div class="flex flex-col gap-2">
				{#each generalFilters as filter (filter.id)}
					<label class="flex cursor-pointer items-center gap-3 rounded-lg p-2 hover:bg-gray-50">
						<svelte:component this={filter.Icon} class="h-5 w-5 {filter.color}" />
						<span class="flex-1">{filter.label}</span>
						<input
							type="checkbox"
							class="toggle toggle-primary"
							style="--tcb: #8F66FF; --tbc: #8F66FF;"
							bind:checked={filters[filter.id]}
						/>
					</label>
				{/each}
			</div>
		</div>
	</div>
</div>

<style>
	/* Safe area for entire sidebar */
	.safe-sidebar {
		padding-top: max(0rem, env(safe-area-inset-top));
		padding-bottom: max(0rem, env(safe-area-inset-bottom));
	}

	/* Header with horizontal safe spacing and more top padding */
	.safe-sidebar-header {
		padding-top: max(2rem, calc(2rem + env(safe-area-inset-top))); /* Increased from 1rem to 2rem */
		padding-left: max(1.5rem, env(safe-area-inset-left));
		padding-right: max(1.5rem, env(safe-area-inset-right));
	}

	/* Content area with horizontal safe spacing */
	.safe-sidebar-content {
		padding-left: max(1.5rem, env(safe-area-inset-left));
		padding-right: max(1.5rem, env(safe-area-inset-right));
		padding-bottom: max(1.5rem, calc(1.5rem + env(safe-area-inset-bottom)));
	}
</style>
