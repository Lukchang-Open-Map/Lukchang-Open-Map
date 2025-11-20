<script>
	import { userStore } from '$lib/stores/userStore.js';
	import { clickOutside } from '$lib/utils/actions.js';
	import { Menu, User, ChevronDown, ChevronUp } from 'lucide-svelte';
	import { createEventDispatcher } from 'svelte';
	import { goto } from '$app/navigation';

	export let showMenuButton = true;

	const dispatch = createEventDispatcher();
	let isProfileOpen = false;

	function handleLogout() {
		userStore.set(null);
		goto('/login');
	}
</script>

<nav
	class="pt-safe pointer-events-none absolute top-0 right-0 left-0 z-40 flex items-center justify-between px-4"
>
	{#if showMenuButton}
		<button
			class="pointer-events-auto flex items-center justify-center rounded-2xl border border-gray-100 bg-white p-3 shadow-sm transition-all hover:bg-gray-50 active:scale-95"
			on:click={() => dispatch('toggleSidebar')}
		>
			<Menu class="h-6 w-6 text-gray-700" />
		</button>
	{:else}
		<div></div>
	{/if}

	<div
		class="pointer-events-auto relative"
		use:clickOutside
		on:clickoutside={() => (isProfileOpen = false)}
	>
		{#if $userStore}
			<button
				on:click={() => (isProfileOpen = !isProfileOpen)}
				class="flex items-center gap-3 rounded-2xl border border-gray-100 bg-white p-2 pr-4 shadow-sm transition-all hover:bg-gray-50"
			>
				<div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gray-100">
					<User class="h-5 w-5 text-gray-600" />
				</div>
				<span class="max-w-[200px] truncate text-lg font-bold text-gray-800 hidden sm:block">{$userStore?.name ?? 'User'}</span>
				{#if isProfileOpen}
					<ChevronUp class="h-4 w-4 shrink-0 text-gray-400" />
				{:else}
					<ChevronDown class="h-4 w-4 shrink-0 text-gray-400" />
				{/if}
			</button>

			{#if isProfileOpen}
				<div
					class="animate-in fade-in slide-in-from-top-2 absolute right-0 z-50 mt-2 w-64 rounded-2xl border border-gray-100 bg-white p-4 shadow-xl"
				>
					<div class="border-b border-gray-100 pb-3">
						<!-- <div class="text-xl font-bold text-gray-900">{$userStore?.name}</div> -->
						<div class="mt-1 text-sm text-gray-500">{$userStore?.email}</div>
						{#if $userStore?.role}
							<div class="mt-2">
								<span
									class="inline-block rounded-full bg-[#EBE0F3] px-3 py-1 text-xs font-bold tracking-wide text-[#8F66FF] uppercase"
								>
									{$userStore.role}
								</span>
							</div>
						{/if}
					</div>
					<div class="pt-2">
						<button
							on:click={handleLogout}
							class="w-full rounded-lg px-2 py-2 text-left text-base font-semibold text-gray-700 transition-colors hover:bg-gray-50"
						>
							Sign Out
						</button>
					</div>
				</div>
			{/if}
		{:else}
			<a
				href="/login"
				class="pointer-events-auto flex items-center justify-center rounded-2xl bg-white px-6 py-3 font-bold text-[#8F66FF] shadow-md hover:bg-gray-50"
			>
				Login
			</a>
		{/if}
	</div>
</nav>

<style>
	.pt-safe {
		padding-top: max(1rem, env(safe-area-inset-top));
	}
</style>
