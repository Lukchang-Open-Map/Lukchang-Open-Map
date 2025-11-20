<script>
	import { createEventDispatcher } from 'svelte';
	import {
		AlertTriangle,
		TrafficCone,
		HelpCircle,
		Droplet,
		LifeBuoy,
		CarFront,
		ParkingSquare,
		Briefcase,
		PartyPopper
	} from 'lucide-svelte';
	import { CATEGORY_STYLES } from '$lib/constant/map-config.js';

	const dispatch = createEventDispatcher();

	// กลุ่ม 1: Incident Report
	const incidentCategories = [
		{ label: 'Accident /Hazard', value: 'accident', Icon: AlertTriangle },
		{ label: 'Blocked', value: 'blocked', Icon: TrafficCone },
		{ label: 'Beware', value: 'beware', Icon: HelpCircle },
		{ label: 'Flood', value: 'flood', Icon: Droplet },
		{ label: 'Send Help', value: 'send_help', Icon: LifeBuoy }
	];

	// กลุ่ม 2: General Report (ตัด Map Chat ออกตามรูป)
	const generalCategories = [
		{ label: 'Traffic', value: 'traffic_general', Icon: CarFront },
		{ label: 'Parking', value: 'parking', Icon: ParkingSquare },
		{ label: 'Events', value: 'events', Icon: PartyPopper },
		{ label: 'Lost & Found', value: 'lost_found', Icon: Briefcase }
	];

	function handleSelect(category) {
		if (category === 'send_help') {
			dispatch('sendHelp');
		} else if (category === 'blocked' || category === 'traffic_general') {
			dispatch('showOptions', category);
		} else {
			dispatch('select', category);
		}
	}
</script>

<div
	class="pointer-events-auto absolute top-24 left-4 z-30 flex w-72 flex-col gap-4 rounded-3xl border border-gray-100 bg-white p-5 shadow-xl"
>
	<h2 class="mb-1 text-center text-xl font-bold text-gray-900">What's happening here?</h2>

	<div>
		<h3 class="mb-3 pl-1 text-base font-medium text-gray-600">Incident Report</h3>
		<div class="grid grid-cols-3 gap-3">
			{#each incidentCategories as cat}
				<button
					class="flex flex-col items-center gap-2 rounded-xl p-2 transition-all hover:bg-gray-50 active:scale-95"
					on:click={() => handleSelect(cat.value)}
				>
					<div
						class="flex h-14 w-14 items-center justify-center rounded-full {CATEGORY_STYLES[
							cat.value
						].bg}"
					>
						<svelte:component this={cat.Icon} class="h-7 w-7 {CATEGORY_STYLES[cat.value].text}" />
					</div>
					<span class="font-regular px-1 text-center text-xs leading-tight text-gray-800">
						{@html cat.label.replace(' ', '<br>')}
					</span>
				</button>
			{/each}
		</div>
	</div>

	<div>
		<h3 class="mb-3 pl-1 text-base font-medium text-gray-600">General Report</h3>
		<div class="grid grid-cols-3 gap-3">
			{#each generalCategories as cat}
				<button
					class="flex flex-col items-center gap-2 rounded-xl p-2 transition-all hover:bg-gray-50 active:scale-95"
					on:click={() => handleSelect(cat.value)}
				>
					<div
						class="flex h-14 w-14 items-center justify-center rounded-full {CATEGORY_STYLES[
							cat.value
						].bg}"
					>
						<svelte:component this={cat.Icon} class="h-7 w-7 {CATEGORY_STYLES[cat.value].text}" />
					</div>
					<span class="font-regular text-center text-xs leading-tight text-gray-800">
						{@html cat.label.replace('&', '<br>&')}
					</span>
				</button>
			{/each}
		</div>
	</div>
</div>
