<script>
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import "maplibre-gl/dist/maplibre-gl.css";

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children()}
