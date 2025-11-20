<script>
	import { createEventDispatcher } from 'svelte';
	// ✅ Import RouteOff เข้ามาใช้แทน Spline
	import { MapPin, RouteOff, X } from 'lucide-svelte';

	// ✅ แก้ Default Values ตรงนี้เลยครับ
	export let title = 'Report Obstacle / Traffic';

	export let pointOption = {
		Icon: MapPin,
		title: 'Obstacle',
		description: 'e.g. Fallen tree, Car breakdown'
	};

	export let lineOption = {
		// ✅ เปลี่ยน Icon เป็น RouteOff
		Icon: RouteOff,
		// ✅ เปลี่ยน Title เป็น Road Off
		title: 'Road Off',
		description: 'e.g. Construction, Flooding'
	};

	const dispatch = createEventDispatcher();
</script>

<div
	class="font-kanit fixed inset-0 z-[90] flex items-center justify-center bg-black/40 p-4 backdrop-blur-[2px]"
	on:click={() => dispatch('close')}
>
	<div
		on:click|stopPropagation
		class="animate-scale-up flex w-full max-w-sm flex-col gap-4 rounded-[32px] bg-white p-6 shadow-2xl"
	>
		<div class="flex items-center justify-between pl-2">
			<h2 class="text-xl font-bold text-gray-900">{title}</h2>
			<button
				on:click={() => dispatch('close')}
				class="rounded-full p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
			>
				<X class="h-6 w-6" />
			</button>
		</div>

		<p class="-mt-2 pl-2 text-sm text-gray-500">What kind of report is it?</p>

		<div class="mt-2 flex flex-col gap-3">
			<button
				on:click={() => dispatch('selectPoint')}
				class="group flex items-center gap-4 rounded-2xl border border-gray-200 p-4 text-left transition-all hover:border-orange-200 hover:bg-orange-50"
			>
				<div
					class="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-orange-100 text-orange-600 transition-colors group-hover:bg-orange-200"
				>
					<svelte:component this={pointOption.Icon} class="h-6 w-6" />
				</div>
				<div>
					<span class="block text-lg font-bold text-gray-800">{pointOption.title}</span>
					<span class="text-sm text-gray-500">{pointOption.description}</span>
				</div>
			</button>

			<button
				on:click={() => dispatch('selectLine')}
				class="group flex items-center gap-4 rounded-2xl border border-gray-200 p-4 text-left transition-all hover:border-orange-200 hover:bg-orange-50"
			>
				<div
					class="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-orange-100 text-orange-600 transition-colors group-hover:bg-orange-200"
				>
					<svelte:component this={lineOption.Icon} class="h-6 w-6" />
				</div>
				<div>
					<span class="block text-lg font-bold text-gray-800">{lineOption.title}</span>
					<span class="text-sm text-gray-500">{lineOption.description}</span>
				</div>
			</button>
		</div>
	</div>
</div>

<style>
	@keyframes scale-up {
		from {
			transform: scale(0.95);
			opacity: 0;
		}
		to {
			transform: scale(1);
			opacity: 1;
		}
	}
	.animate-scale-up {
		animation: scale-up 0.2s ease-out forwards;
	}
</style>
