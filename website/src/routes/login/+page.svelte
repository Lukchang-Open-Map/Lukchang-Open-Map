<script>
	import { goto } from '$app/navigation';
	import { userStore } from '$lib/stores/userStore.js';
	import { ChevronLeft } from 'lucide-svelte';
	import { supabase } from '$lib/supabaseClient.js';

	let step = 1;
	let cmuEmail = '';
	let otpArray = Array(6).fill('');
	let countdown = 50;
	let timer;
	let emailError = '';

	$: isEmailValid = cmuEmail.length > 0; // ตาม logic เดิม
	$: isOtpComplete = otpArray.join('').length === 6;
	$: formattedTime =
		String(Math.floor(countdown / 60)).padStart(2, '0') +
		':' +
		String(countdown % 60).padStart(2, '0');

	function validateEmail() {
		if (cmuEmail.endsWith('@cmu.ac.th')) {
			emailError = '';
			return true;
		} else {
			if (cmuEmail.length > 0) emailError = 'Please use a valid @cmu.ac.th account.';
			return false;
		}
	}
	$: if (cmuEmail) validateEmail();

	async function sendOTP() {
		if (!validateEmail()) return;
		step = 2;
		startCountdown();
		let { data, error } = await supabase.auth.signInWithOtp({
			email: cmuEmail
		});
		if (error) {
			alert(error.message);
		} else {
			// OTP sent
		}
	}

	function startCountdown() {
		countdown = 50;
		clearInterval(timer);
		timer = setInterval(() => {
			if (countdown > 0) countdown--;
			else clearInterval(timer);
		}, 1000);
	}

	async function verifyOTP() {
		const otp = await otpArray.join('');

		let { data, error } = await supabase.auth.verifyOtp({
			email: cmuEmail,
			token: otp,
			type: 'email'
		});
		if (error) {
			alert(error.message);
		} else {
			const {
				data: { user }
			} = await supabase.auth.getUser();
			userStore.set({
				id: user.id,
				name: cmuEmail.split('@')[0],
				email: cmuEmail,
				role: user.role
			});
			user.role === 'security' || user.role === 'admin' ? goto(`/${user.role}`) : goto('/');
		}
	}

	function handleInput(e, index) {
		const val = e.target.value.replace(/\D/g, '');
		if (!val) {
			otpArray[index] = '';
			return;
		}
		otpArray[index] = val[0];
		let nextIndex = index + 1;
		for (let i = 1; i < val.length && nextIndex < otpArray.length; i++, nextIndex++) {
			otpArray[nextIndex] = val[i];
		}
		if (index < 5 && val.length > 0) document.getElementById(`otp-${index + 1}`)?.focus();
	}

	function handleKeydown(e, index) {
		if (e.key === 'Backspace' && !otpArray[index] && index > 0)
			document.getElementById(`otp-${index - 1}`)?.focus();
	}
</script>

<div class="font-kanit absolute inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
	<div class="flex w-full max-w-sm flex-col gap-6 rounded-2xl bg-white p-8 text-center shadow-xl">
		<div class="mb-2 flex flex-col items-center gap-2">
			<img src="/logo.svg" alt="Logo" class="mb-2 h-8" />
			<h2 class="text-2xl font-bold">Welcome Back!</h2>
			<p class="text-sm text-gray-500">Let’s get you back on the map</p>
		</div>

		{#if step === 1}
			<form on:submit|preventDefault={sendOTP} class="flex flex-col gap-6 text-left">
				<div class="flex flex-col gap-1">
					<label for="email" class="font-medium text-gray-700">CMU Account</label>
					<input
						id="email"
						type="email"
						placeholder="name@cmu.ac.th"
						class="input-bordered input w-full"
						class:input-error={emailError}
						bind:value={cmuEmail}
						required
					/>
					{#if emailError}<p class="mt-1 text-sm text-error">{emailError}</p>{/if}
				</div>
				<button
					type="submit"
					class="btn w-full rounded-full text-white"
					style:background-color={isEmailValid ? '#8F66FF' : ''}
					style:border-color={isEmailValid ? '#8F66FF' : ''}
					disabled={!isEmailValid}>Send OTP</button
				>
			</form>
		{/if}

		{#if step === 2}
			<button
				class="flex items-center self-start p-0 font-medium text-gray-700 hover:text-black"
				on:click={() => (step = 1)}
			>
				<ChevronLeft class="mr-1 h-4 w-4" /> Back
			</button>
			<form on:submit|preventDefault={verifyOTP} class="flex flex-col gap-6 text-left">
				<div class="flex flex-col gap-2">
					<span class="font-medium text-gray-700">One Time Password</span>
					<div class="flex justify-center gap-2">
						{#each otpArray as digit, i}
							<input
								id={`otp-${i}`}
								type="text"
								inputmode="numeric"
								class="input-bordered input h-12 w-12 text-center text-lg"
								maxlength="1"
								bind:value={otpArray[i]}
								on:input={(e) => handleInput(e, i)}
								on:keydown={(e) => handleKeydown(e, i)}
							/>
						{/each}
					</div>
				</div>
				<div class="-mt-2 flex items-center justify-between">
					<span class="text-sm text-gray-500">{formattedTime}</span>
					<button
						type="button"
						class="btn p-0 text-sm text-[#8F66FF] btn-link"
						on:click={() => {
							startCountdown();
							alert('OTP Resent');
						}}
						disabled={countdown > 0}>Resend OTP</button
					>
				</div>
				<button
					type="submit"
					class="btn w-full rounded-full text-white"
					style:background-color={isOtpComplete ? '#8F66FF' : ''}
					style:border-color={isOtpComplete ? '#8F66FF' : ''}
					disabled={!isOtpComplete}>LOG IN</button
				>
			</form>
		{/if}
	</div>
</div>
