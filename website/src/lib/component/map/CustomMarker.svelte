<script>
	import { CATEGORY_STYLES } from '$lib/constant/map-config.js';
	export let category;
	$: style = CATEGORY_STYLES[category] || CATEGORY_STYLES['beware'];
</script>

<div class="relative flex h-12 w-12 items-center justify-center">
	{#if category === 'flood'}
		<div class="absolute h-10 w-10 animate-ping rounded-full bg-blue-400 opacity-75"></div>
		<div class="absolute h-10 w-10 rounded-full bg-blue-500 opacity-20"></div>
	{/if}
	<div class="relative z-10 h-11 w-10">
		<div
			class="absolute top-0 left-0 flex h-10 w-10 items-center justify-center rounded-full shadow-lg {style.bg} border-2 border-white"
		>
			<svelte:component this={style.Icon} class="h-6 w-6 {style.text}" />
		</div>
		<div
			class="absolute top-[38px] left-1/2 -translate-x-1/2"
			style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 10px solid white; filter: drop-shadow(0 1px 1px rgb(0 0 0 / 0.1));"
		></div>
	</div>
</div>
