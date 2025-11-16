<script>
  import { fade } from 'svelte/transition';
  import { userStore } from '$lib/userStore.js'; 
  import Login from '$lib/component/Auth/Login.svelte'; 
  import Map from '$lib/component/Map/Map.svelte';
</script>

<svelte:head>
  <link href="https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;600&display=swap" rel="stylesheet">
</svelte:head>

<div class="relative h-screen w-full overflow-hidden bg-white font-kanit">
  <div class="absolute inset-0 z-0">
    <Map />
  </div>

  {#if !$userStore}
    <div 
        class="fixed inset-0 z-40 flex items-center justify-center bg-black/30 backdrop-blur-sm"
        transition:fade={{ duration: 300 }}
    >
        <div class="w-full max-w-md p-4">
            <Login />
        </div>
    </div>
  {/if}

</div>

<style>
  .font-kanit {
    font-family: 'Kanit', sans-serif;
  }
</style>


<!-- <script>
	import { onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import { userStore } from '$lib/userStore.js';
	import Login from '$lib/component/Auth/Login.svelte';
	import Map from '$lib/component/Map/Map.svelte';

	let showSplash = true;

	onMount(async () => {
		await new Promise((resolve) => setTimeout(resolve, 3000));

		showSplash = false;
	});
</script>

<svelte:head>
	<script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
	<link
		href="https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;600&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

<div class="font-kanit relative h-screen w-full overflow-hidden bg-white">
	<div class="absolute inset-0 z-0">
		<Map />
	</div>

	{#if !showSplash && !$userStore}
		<div
			class="fixed inset-0 z-40 flex items-center justify-center bg-black/30 backdrop-blur-sm"
			transition:fade={{ duration: 300 }}
		>
			<div class="w-full max-w-md p-4">
				<Login />
			</div>
		</div>
	{/if}

	{#if showSplash}
		<div
			class="fixed inset-0 z-50 flex flex-col items-center justify-center bg-white"
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
</div>

<style>
	.font-kanit {
		font-family: 'Kanit', sans-serif;
	}
</style> -->
