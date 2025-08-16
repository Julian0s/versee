// Service Worker para cache inteligente de mídia - VERSEE
// Implementa estratégias avançadas de cache para melhor performance

const CACHE_VERSION = 'v1';
const CACHE_NAMES = {
  static: `versee-static-${CACHE_VERSION}`,
  media: `versee-media-${CACHE_VERSION}`,
  api: `versee-api-${CACHE_VERSION}`,
  thumbnails: `versee-thumbnails-${CACHE_VERSION}`,
};

const MEDIA_CACHE_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 dias
const THUMBNAIL_CACHE_DURATION = 60 * 24 * 60 * 60 * 1000; // 60 dias
const API_CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 horas

// URLs que devem ser cacheadas estaticamente
const STATIC_CACHE_URLS = [
  '/',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Padrões de URL para diferentes tipos de cache
const URL_PATTERNS = {
  media: /\.(mp3|mp4|wav|ogg|webm|m4a|aac)$/i,
  images: /\.(jpg|jpeg|png|gif|webp|svg)$/i,
  thumbnails: /\/thumbnails?\//i,
  firebase: /firebasestorage\.googleapis\.com/,
  api: /\/api\//,
};

console.log('🔧 Service Worker VERSEE iniciado');

// Instalação do Service Worker
self.addEventListener('install', event => {
  console.log('📦 Service Worker instalando...');
  
  event.waitUntil(
    Promise.all([
      caches.open(CACHE_NAMES.static).then(cache => {
        console.log('📁 Cache estático criado');
        return cache.addAll(STATIC_CACHE_URLS);
      }),
      caches.open(CACHE_NAMES.media).then(cache => {
        console.log('🎵 Cache de mídia criado');
      }),
      caches.open(CACHE_NAMES.thumbnails).then(cache => {
        console.log('🖼️ Cache de thumbnails criado');
      }),
      caches.open(CACHE_NAMES.api).then(cache => {
        console.log('🌐 Cache de API criado');
      }),
    ]).then(() => {
      console.log('✅ Service Worker instalado com sucesso');
      self.skipWaiting();
    })
  );
});

// Ativação do Service Worker
self.addEventListener('activate', event => {
  console.log('🚀 Service Worker ativando...');
  
  event.waitUntil(
    Promise.all([
      // Limpar caches antigos
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => {
            if (!Object.values(CACHE_NAMES).includes(cacheName)) {
              console.log('🗑️ Removendo cache antigo:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      // Assumir controle de todas as páginas
      self.clients.claim(),
    ]).then(() => {
      console.log('✅ Service Worker ativado e assumiu controle');
    })
  );
});

// Interceptação de requisições
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  
  // Ignorar requisições não-HTTP
  if (!request.url.startsWith('http')) {
    return;
  }
  
  // Estratégias de cache baseadas no tipo de conteúdo
  if (URL_PATTERNS.thumbnails.test(url.pathname)) {
    event.respondWith(handleThumbnailRequest(request));
  } else if (URL_PATTERNS.media.test(url.pathname) || URL_PATTERNS.firebase.test(url.hostname)) {
    event.respondWith(handleMediaRequest(request));
  } else if (URL_PATTERNS.images.test(url.pathname)) {
    event.respondWith(handleImageRequest(request));
  } else if (URL_PATTERNS.api.test(url.pathname)) {
    event.respondWith(handleApiRequest(request));
  } else {
    event.respondWith(handleStaticRequest(request));
  }
});

// Cache para thumbnails (sempre cache primeiro)
async function handleThumbnailRequest(request) {
  try {
    const cache = await caches.open(CACHE_NAMES.thumbnails);
    const cached = await cache.match(request);
    
    if (cached) {
      console.log('🖼️ Thumbnail servido do cache:', request.url);
      return cached;
    }
    
    console.log('📥 Baixando thumbnail:', request.url);
    const response = await fetch(request);
    
    if (response.ok) {
      // Cache com headers otimizados
      const responseToCache = response.clone();
      await cache.put(request, responseToCache);
      console.log('💾 Thumbnail salvo no cache:', request.url);
    }
    
    return response;
  } catch (error) {
    console.error('❌ Erro ao processar thumbnail:', error);
    return new Response('Thumbnail não disponível', { status: 404 });
  }
}

// Cache para mídia com estratégia de streaming
async function handleMediaRequest(request) {
  try {
    const cache = await caches.open(CACHE_NAMES.media);
    const url = new URL(request.url);
    
    // Para mídia, verificar se é uma requisição de range (streaming)
    const range = request.headers.get('range');
    
    if (range) {
      console.log('🎵 Requisição de range para mídia:', request.url);
      return handleRangeRequest(request, cache);
    }
    
    // Tentar cache primeiro para mídia pequena
    const cached = await cache.match(request);
    if (cached) {
      console.log('🎵 Mídia servida do cache:', request.url);
      return cached;
    }
    
    console.log('📥 Baixando mídia:', request.url);
    const response = await fetch(request);
    
    if (response.ok) {
      const contentLength = response.headers.get('content-length');
      const size = contentLength ? parseInt(contentLength) : 0;
      
      // Cache apenas mídias menores que 50MB
      if (size < 50 * 1024 * 1024) {
        const responseToCache = response.clone();
        await cache.put(request, responseToCache);
        console.log('💾 Mídia salva no cache:', request.url, formatBytes(size));
      } else {
        console.log('⚠️ Mídia muito grande para cache:', request.url, formatBytes(size));
      }
    }
    
    return response;
  } catch (error) {
    console.error('❌ Erro ao processar mídia:', error);
    return new Response('Mídia não disponível', { status: 404 });
  }
}

// Manipular requisições de range para streaming
async function handleRangeRequest(request, cache) {
  try {
    // Verificar se temos a mídia completa no cache
    const fullRequest = new Request(request.url, {
      headers: new Headers(request.headers)
    });
    fullRequest.headers.delete('range');
    
    const cached = await cache.match(fullRequest);
    
    if (cached) {
      console.log('🎵 Servindo range do cache:', request.url);
      return createRangeResponse(cached, request.headers.get('range'));
    }
    
    // Se não tiver no cache, fazer requisição normal
    console.log('📥 Range request para servidor:', request.url);
    return fetch(request);
  } catch (error) {
    console.error('❌ Erro no range request:', error);
    return fetch(request);
  }
}

// Criar resposta de range a partir do cache
async function createRangeResponse(cachedResponse, rangeHeader) {
  const arrayBuffer = await cachedResponse.arrayBuffer();
  const totalLength = arrayBuffer.byteLength;
  
  // Parse do header Range: bytes=start-end
  const rangeMatch = rangeHeader.match(/bytes=(\d+)-(\d*)/);
  if (!rangeMatch) {
    return new Response(arrayBuffer, {
      status: 200,
      headers: cachedResponse.headers
    });
  }
  
  const start = parseInt(rangeMatch[1]);
  const end = rangeMatch[2] ? parseInt(rangeMatch[2]) : totalLength - 1;
  
  if (start >= totalLength || end >= totalLength || start > end) {
    return new Response(null, {
      status: 416,
      headers: {
        'Content-Range': `bytes */${totalLength}`
      }
    });
  }
  
  const chunk = arrayBuffer.slice(start, end + 1);
  
  return new Response(chunk, {
    status: 206,
    headers: {
      'Content-Range': `bytes ${start}-${end}/${totalLength}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': (end - start + 1).toString(),
      'Content-Type': cachedResponse.headers.get('Content-Type') || 'application/octet-stream'
    }
  });
}

// Cache para imagens
async function handleImageRequest(request) {
  try {
    const cache = await caches.open(CACHE_NAMES.media);
    const cached = await cache.match(request);
    
    if (cached) {
      console.log('🖼️ Imagem servida do cache:', request.url);
      return cached;
    }
    
    const response = await fetch(request);
    
    if (response.ok) {
      const responseToCache = response.clone();
      await cache.put(request, responseToCache);
      console.log('💾 Imagem salva no cache:', request.url);
    }
    
    return response;
  } catch (error) {
    console.error('❌ Erro ao processar imagem:', error);
    return fetch(request);
  }
}

// Cache para API com TTL
async function handleApiRequest(request) {
  try {
    const cache = await caches.open(CACHE_NAMES.api);
    const cached = await cache.match(request);
    
    if (cached) {
      const cachedDate = cached.headers.get('sw-cached-date');
      if (cachedDate) {
        const age = Date.now() - parseInt(cachedDate);
        if (age < API_CACHE_DURATION) {
          console.log('🌐 API servida do cache:', request.url);
          return cached;
        }
      }
    }
    
    console.log('📥 Fazendo requisição API:', request.url);
    const response = await fetch(request);
    
    if (response.ok && request.method === 'GET') {
      const responseToCache = response.clone();
      const headers = new Headers(responseToCache.headers);
      headers.set('sw-cached-date', Date.now().toString());
      
      const modifiedResponse = new Response(await responseToCache.blob(), {
        status: responseToCache.status,
        statusText: responseToCache.statusText,
        headers: headers
      });
      
      await cache.put(request, modifiedResponse);
      console.log('💾 Resposta API salva no cache:', request.url);
    }
    
    return response;
  } catch (error) {
    console.error('❌ Erro ao processar API:', error);
    
    // Tentar servir do cache em caso de erro de rede
    const cache = await caches.open(CACHE_NAMES.api);
    const cached = await cache.match(request);
    
    if (cached) {
      console.log('🔄 Servindo API do cache (offline):', request.url);
      return cached;
    }
    
    throw error;
  }
}

// Cache para recursos estáticos
async function handleStaticRequest(request) {
  try {
    const cache = await caches.open(CACHE_NAMES.static);
    const cached = await cache.match(request);
    
    if (cached) {
      return cached;
    }
    
    const response = await fetch(request);
    
    if (response.ok) {
      const responseToCache = response.clone();
      await cache.put(request, responseToCache);
    }
    
    return response;
  } catch (error) {
    console.error('❌ Erro ao processar recurso estático:', error);
    return fetch(request);
  }
}

// Limpeza automática de cache antigo
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'CLEANUP_CACHE') {
    event.waitUntil(cleanupOldCache());
  }
});

async function cleanupOldCache() {
  console.log('🧹 Iniciando limpeza de cache...');
  
  try {
    const cacheNames = await caches.keys();
    const mediaCache = await caches.open(CACHE_NAMES.media);
    const thumbnailCache = await caches.open(CACHE_NAMES.thumbnails);
    
    // Limpar mídia antiga
    const mediaRequests = await mediaCache.keys();
    for (const request of mediaRequests) {
      const response = await mediaCache.match(request);
      if (response) {
        const cachedDate = response.headers.get('date');
        if (cachedDate) {
          const age = Date.now() - new Date(cachedDate).getTime();
          if (age > MEDIA_CACHE_DURATION) {
            await mediaCache.delete(request);
            console.log('🗑️ Mídia antiga removida:', request.url);
          }
        }
      }
    }
    
    // Limpar thumbnails antigos
    const thumbnailRequests = await thumbnailCache.keys();
    for (const request of thumbnailRequests) {
      const response = await thumbnailCache.match(request);
      if (response) {
        const cachedDate = response.headers.get('date');
        if (cachedDate) {
          const age = Date.now() - new Date(cachedDate).getTime();
          if (age > THUMBNAIL_CACHE_DURATION) {
            await thumbnailCache.delete(request);
            console.log('🗑️ Thumbnail antigo removido:', request.url);
          }
        }
      }
    }
    
    console.log('✅ Limpeza de cache concluída');
  } catch (error) {
    console.error('❌ Erro na limpeza de cache:', error);
  }
}

// Utilitário para formatar bytes
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Agendar limpeza automática a cada 6 horas
setInterval(() => {
  cleanupOldCache().catch(console.error);
}, 6 * 60 * 60 * 1000);

console.log('✅ Service Worker VERSEE carregado e pronto');