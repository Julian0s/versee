// Service Worker para melhorar o carregamento de mídia
const CACHE_NAME = 'versee-media-v1';

// Cache de recursos essenciais
const urlsToCache = [
  '/',
  '/manifest.json',
  '/favicon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // Interceptar requisições de mídia do Firebase Storage
  if (url.hostname.includes('firebasestorage.googleapis.com')) {
    event.respondWith(
      caches.open(CACHE_NAME + '-media').then(cache => {
        return cache.match(event.request).then(cachedResponse => {
          if (cachedResponse) {
            console.log('Serving cached media:', url.pathname);
            return cachedResponse;
          }
          
          // Fetch with optimized headers for audio
          return fetch(event.request.clone(), {
            mode: 'cors',
            credentials: 'omit',
            headers: {
              'Accept': 'audio/*,video/*,*/*;q=0.9',
              'Accept-Encoding': 'identity',
              'Cache-Control': 'max-age=31536000',
              'Range': 'bytes=0-'
            }
          }).then(response => {
            if (!response.ok) {
              throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            // Clone response for caching
            const responseClone = response.clone();
            
            // Enhanced headers for audio compatibility
            const headers = new Headers(response.headers);
            headers.set('Access-Control-Allow-Origin', '*');
            headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
            headers.set('Access-Control-Allow-Headers', 'Range, Content-Range, Content-Length, Accept, Cache-Control');
            headers.set('Accept-Ranges', 'bytes');
            headers.set('Cache-Control', 'public, max-age=31536000');
            
            // Set appropriate content type if missing
            if (!headers.get('Content-Type') || !headers.get('Content-Type').startsWith('audio/')) {
              const pathname = url.pathname.toLowerCase();
              if (pathname.includes('.mp3') || pathname.includes('audio%2Fmpeg')) {
                headers.set('Content-Type', 'audio/mpeg');
              } else if (pathname.includes('.wav')) {
                headers.set('Content-Type', 'audio/wav');
              } else if (pathname.includes('.ogg')) {
                headers.set('Content-Type', 'audio/ogg');
              } else if (pathname.includes('.m4a')) {
                headers.set('Content-Type', 'audio/mp4');
              }
            }
            
            const enhancedResponse = new Response(response.body, {
              status: response.status,
              statusText: response.statusText,
              headers: headers
            });
            
            // Cache successful responses
            if (response.status === 200) {
              cache.put(event.request, responseClone);
            }
            
            return enhancedResponse;
          });
        });
      }).catch(error => {
        console.error('Erro ao carregar mídia:', error);
        return new Response(JSON.stringify({
          error: 'Erro ao carregar mídia',
          details: error.message,
          url: event.request.url
        }), { 
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      })
    );
    return;
  }
  
  // Cache padrão para outros recursos
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});

// Limpar caches antigos
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});