if( typeof window === 'undefined' ) {
	self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
	self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
	self.addEventListener('fetch', event => {
		if( new URL(event.request.url).origin !== self.location.origin ) return;
		event.respondWith(fetch(event.request).then(response => {
			if( response.status === 0 ) return response;
			var headers = new Headers(response.headers);
			headers.set('Cross-Origin-Opener-Policy', 'same-origin');
			headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
			return new Response(response.body, {
				status: response.status,
				statusText: response.statusText,
				headers: headers
			});
		}));
	});
} else {
	var MWAtlasIsolationReady = (async function() {
		if( window.crossOriginIsolated ) return;
		if( window.top !== window.self ) {
			throw new Error('Enable SharedArrayBuffer support in the itch.io embed settings.');
		}
		if( !window.isSecureContext || !('serviceWorker' in navigator) ) {
			throw new Error('Threaded WebAssembly requires HTTPS and service worker support.');
		}
		if( navigator.serviceWorker.controller ) {
			throw new Error('Cross-origin isolation is unavailable. Check browser permissions and COOP/COEP support.');
		}
		var controlled = new Promise(resolve => {
			navigator.serviceWorker.addEventListener('controllerchange', resolve, { once: true });
		});
		await navigator.serviceWorker.register('isolation.js', { updateViaCache: 'none' });
		await controlled;
		window.location.reload();
		await new Promise(() => {});
	})();
}