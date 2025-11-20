export function initializeMapInteractions() {
	if (typeof window === 'undefined') return;

	// --- Like Handler ---
	window.handleLike = (pinId) => {
		console.log(`MOCK: Liking pin ${pinId}!`);

		const countElement = document.getElementById(`like-count-${pinId}`);
		const buttonElement = document.getElementById(`like-button-${pinId}`);

		if (countElement && buttonElement) {
			let currentLikes = parseInt(countElement.innerText, 10) || 0;
			currentLikes++;
			countElement.innerText = currentLikes;

			// Visual feedback (Green Theme)
			const svg = buttonElement.querySelector('svg');
			if (svg) {
				svg.style.fill = '#22c55e'; // green-500
				svg.style.stroke = '#22c55e';
			}
			buttonElement.style.backgroundColor = '#dcfce7'; // green-100
			buttonElement.disabled = true;
			buttonElement.style.cursor = 'not-allowed';
		}
	};

	// --- Dislike Handler ---
	window.handleDislike = (pinId) => {
		console.log(`MOCK: Disliking pin ${pinId}!`);

		const countElement = document.getElementById(`dislike-count-${pinId}`);
		const buttonElement = document.getElementById(`dislike-button-${pinId}`);

		if (countElement && buttonElement) {
			let currentDislikes = parseInt(countElement.innerText, 10) || 0;
			currentDislikes++;
			countElement.innerText = currentDislikes;

			// Visual feedback (Red Theme)
			const svg = buttonElement.querySelector('svg');
			if (svg) {
				svg.style.fill = '#ef4444'; // red-500
				svg.style.stroke = '#ef4444';
			}
			buttonElement.style.backgroundColor = '#fee2e2'; // red-100
			buttonElement.disabled = true;
			buttonElement.style.cursor = 'not-allowed';
		}
	};

	// --- Comment Handler
	window.handleComment = (pinId) => {
		const inputElement = document.getElementById(`comment-input-${pinId}`);
		const listElement = document.getElementById(`comments-list-${pinId}`);

		if (!inputElement || !listElement) return;

		const commentText = inputElement.value;
		if (!commentText) return;

		const newComment = document.createElement('div');
		newComment.className = 'text-sm';
		// Escape HTML เพื่อความปลอดภัย
		const safeText = commentText.replace(/</g, '&lt;').replace(/>/g, '&gt;');

		newComment.innerHTML = `<strong>You:</strong> ${safeText}`;

		listElement.appendChild(newComment);
		inputElement.value = '';
		listElement.scrollTop = listElement.scrollHeight;

		console.log(`MOCK: Adding comment to pin ${pinId}: ${commentText}`);
	};
}
