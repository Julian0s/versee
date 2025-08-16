const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegStatic = require('ffmpeg-static');
const tmp = require('tmp');
const fs = require('fs');
const path = require('path');

admin.initializeApp();

// Configurar FFmpeg com binário estático
ffmpeg.setFfmpegPath(ffmpegStatic);

const storage = new Storage();

/**
 * Cloud Function para otimização de áudio
 * Converte para OGG (primário) + MP3 (fallback)
 */
exports.optimizeAudio = functions.storage.object().onFinalize(async (object) => {
  const bucket = admin.storage().bucket();
  const filePath = object.name;
  const fileName = path.basename(filePath);
  
  // Verificar se é um arquivo de áudio para processamento
  if (!filePath.includes('/audio/') || fileName.includes('_optimized')) {
    return null;
  }
  
  console.log(`Processando áudio: ${fileName}`);
  
  try {
    // Criar arquivos temporários
    const tempInputFile = tmp.tmpNameSync({ postfix: path.extname(fileName) });
    const tempOggFile = tmp.tmpNameSync({ postfix: '.ogg' });
    const tempMp3File = tmp.tmpNameSync({ postfix: '.mp3' });
    
    // Baixar arquivo original
    await bucket.file(filePath).download({ destination: tempInputFile });
    
    // Conversão para OGG (formato moderno, menor tamanho)
    await new Promise((resolve, reject) => {
      ffmpeg(tempInputFile)
        .audioCodec('libvorbis')
        .audioBitrate('128k')
        .audioChannels(2)
        .audioFrequency(44100)
        .format('ogg')
        .on('end', resolve)
        .on('error', reject)
        .save(tempOggFile);
    });
    
    // Conversão para MP3 (fallback universal)
    await new Promise((resolve, reject) => {
      ffmpeg(tempInputFile)
        .audioCodec('libmp3lame')
        .audioBitrate('128k')
        .audioChannels(2)
        .audioFrequency(44100)
        .format('mp3')
        .on('end', resolve)
        .on('error', reject)
        .save(tempMp3File);
    });
    
    // Upload dos arquivos otimizados
    const baseFileName = path.parse(fileName).name;
    const userId = filePath.split('/')[1]; // Extrair userId do caminho
    
    const oggDestination = `audio/${userId}/${baseFileName}_optimized.ogg`;
    const mp3Destination = `audio/${userId}/${baseFileName}_optimized.mp3`;
    
    await Promise.all([
      bucket.upload(tempOggFile, {
        destination: oggDestination,
        metadata: {
          metadata: {
            originalFile: filePath,
            optimizedFormat: 'ogg',
            compressionType: 'vorbis',
            bitrate: '128k'
          }
        }
      }),
      bucket.upload(tempMp3File, {
        destination: mp3Destination,
        metadata: {
          metadata: {
            originalFile: filePath,
            optimizedFormat: 'mp3',
            compressionType: 'lame',
            bitrate: '128k'
          }
        }
      })
    ]);
    
    // Limpar arquivos temporários
    [tempInputFile, tempOggFile, tempMp3File].forEach(file => {
      try { fs.unlinkSync(file); } catch (e) { console.warn(`Erro ao limpar ${file}:`, e); }
    });
    
    // Atualizar Firestore com URLs otimizadas
    const [oggFile, mp3File] = await Promise.all([
      bucket.file(oggDestination).getSignedUrl({
        action: 'read',
        expires: '03-09-2030'
      }),
      bucket.file(mp3Destination).getSignedUrl({
        action: 'read',
        expires: '03-09-2030'
      })
    ]);
    
    // Buscar documento no Firestore e atualizar
    const firestore = admin.firestore();
    const mediaQuery = await firestore.collection('media_items')
      .where('sourcePath', '==', `https://firebasestorage.googleapis.com/v0/b/${object.bucket}/o/${encodeURIComponent(filePath)}?alt=media`)
      .limit(1)
      .get();
    
    if (!mediaQuery.empty) {
      const doc = mediaQuery.docs[0];
      await doc.ref.update({
        optimizedUrls: {
          primary: oggFile[0],
          fallback: mp3File[0],
          format: 'ogg+mp3'
        },
        optimizedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    console.log(`Áudio otimizado com sucesso: ${baseFileName}`);
    return { success: true, oggUrl: oggFile[0], mp3Url: mp3File[0] };
    
  } catch (error) {
    console.error('Erro na otimização de áudio:', error);
    return { success: false, error: error.message };
  }
});

/**
 * Cloud Function para otimização de vídeo
 * Converte para WebM (primário) + MP4 (fallback)
 */
exports.optimizeVideo = functions.storage.object().onFinalize(async (object) => {
  const bucket = admin.storage().bucket();
  const filePath = object.name;
  const fileName = path.basename(filePath);
  
  // Verificar se é um arquivo de vídeo para processamento
  if (!filePath.includes('/video/') || fileName.includes('_optimized')) {
    return null;
  }
  
  console.log(`Processando vídeo: ${fileName}`);
  
  try {
    // Criar arquivos temporários
    const tempInputFile = tmp.tmpNameSync({ postfix: path.extname(fileName) });
    const tempWebmFile = tmp.tmpNameSync({ postfix: '.webm' });
    const tempMp4File = tmp.tmpNameSync({ postfix: '.mp4' });
    
    // Baixar arquivo original
    await bucket.file(filePath).download({ destination: tempInputFile });
    
    // Conversão para WebM (formato moderno, excelente compressão)
    await new Promise((resolve, reject) => {
      ffmpeg(tempInputFile)
        .videoCodec('libvpx-vp9')
        .audioCodec('libvorbis')
        .videoBitrate('1000k')
        .audioBitrate('128k')
        .size('1280x720') // HD ready, balance entre qualidade e tamanho
        .fps(30)
        .format('webm')
        .on('end', resolve)
        .on('error', reject)
        .save(tempWebmFile);
    });
    
    // Conversão para MP4 (fallback universal)
    await new Promise((resolve, reject) => {
      ffmpeg(tempInputFile)
        .videoCodec('libx264')
        .audioCodec('aac')
        .videoBitrate('1000k')
        .audioBitrate('128k')
        .size('1280x720')
        .fps(30)
        .format('mp4')
        .on('end', resolve)
        .on('error', reject)
        .save(tempMp4File);
    });
    
    // Upload dos arquivos otimizados
    const baseFileName = path.parse(fileName).name;
    const userId = filePath.split('/')[1];
    
    const webmDestination = `video/${userId}/${baseFileName}_optimized.webm`;
    const mp4Destination = `video/${userId}/${baseFileName}_optimized.mp4`;
    
    await Promise.all([
      bucket.upload(tempWebmFile, {
        destination: webmDestination,
        metadata: {
          metadata: {
            originalFile: filePath,
            optimizedFormat: 'webm',
            compressionType: 'vp9+vorbis',
            resolution: '1280x720'
          }
        }
      }),
      bucket.upload(tempMp4File, {
        destination: mp4Destination,
        metadata: {
          metadata: {
            originalFile: filePath,
            optimizedFormat: 'mp4',
            compressionType: 'h264+aac',
            resolution: '1280x720'
          }
        }
      })
    ]);
    
    // Limpar arquivos temporários
    [tempInputFile, tempWebmFile, tempMp4File].forEach(file => {
      try { fs.unlinkSync(file); } catch (e) { console.warn(`Erro ao limpar ${file}:`, e); }
    });
    
    // Atualizar Firestore com URLs otimizadas
    const [webmFile, mp4File] = await Promise.all([
      bucket.file(webmDestination).getSignedUrl({
        action: 'read',
        expires: '03-09-2030'
      }),
      bucket.file(mp4Destination).getSignedUrl({
        action: 'read',
        expires: '03-09-2030'
      })
    ]);
    
    // Buscar documento no Firestore e atualizar
    const firestore = admin.firestore();
    const mediaQuery = await firestore.collection('media_items')
      .where('sourcePath', '==', `https://firebasestorage.googleapis.com/v0/b/${object.bucket}/o/${encodeURIComponent(filePath)}?alt=media`)
      .limit(1)
      .get();
    
    if (!mediaQuery.empty) {
      const doc = mediaQuery.docs[0];
      await doc.ref.update({
        optimizedUrls: {
          primary: webmFile[0],
          fallback: mp4File[0],
          format: 'webm+mp4'
        },
        optimizedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    console.log(`Vídeo otimizado com sucesso: ${baseFileName}`);
    return { success: true, webmUrl: webmFile[0], mp4Url: mp4File[0] };
    
  } catch (error) {
    console.error('Erro na otimização de vídeo:', error);
    return { success: false, error: error.message };
  }
});

/**
 * Cloud Function HTTP para status de otimização
 */
exports.getOptimizationStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }
  
  const { mediaItemId } = data;
  
  try {
    const firestore = admin.firestore();
    const doc = await firestore.collection('media_items').doc(mediaItemId).get();
    
    if (!doc.exists) {
      throw new functions.https.HttpsError('not-found', 'Item de mídia não encontrado');
    }
    
    const mediaData = doc.data();
    
    return {
      isOptimized: !!mediaData.optimizedUrls,
      optimizedUrls: mediaData.optimizedUrls || null,
      optimizedAt: mediaData.optimizedAt || null,
      originalUrl: mediaData.sourcePath
    };
    
  } catch (error) {
    console.error('Erro ao verificar status de otimização:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});