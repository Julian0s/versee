import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/services/auth_service.dart';

class CloudBibleService {
  static const String _localBiblesKey = 'imported_bibles';
  static const String _localEnabledBiblesKey = 'enabled_imported_bibles';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  
  static const String _biblesCollection = 'user_bibles';
  static const String _storageFolder = 'bible_files';

  /// Salva uma Bíblia importada na nuvem
  Future<bool> saveBibleToCloud(BibleVersionInfo bible, String xmlContent) async {
    try {
      final user = _authService.user;
      if (user == null) {
        print('Usuário não autenticado - salvando localmente');
        return await _saveLocally(bible, xmlContent);
      }

      print('Salvando Bíblia na nuvem: ${bible.name}');
      
      // 1. Fazer upload do arquivo XML para o Storage
      final fileRef = _storage.ref()
          .child(_storageFolder)
          .child(user.uid)
          .child('${bible.id}.xml');
      
      await fileRef.putString(xmlContent, format: PutStringFormat.raw);
      final downloadUrl = await fileRef.getDownloadURL();
      
      // 2. Salvar informações da Bíblia no Firestore
      final bibleDoc = {
        'id': bible.id,
        'name': bible.name,
        'abbreviation': bible.abbreviation,
        'language': bible.language,
        'isPopular': bible.isPopular,
        'isImported': true,
        'fileUrl': downloadUrl,
        'fileSize': xmlContent.length,
        'uploadedAt': Timestamp.now(),
        'enabled': true,
      };
      
      await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .doc(bible.id)
          .set(bibleDoc);
      
      // 3. Também salvar localmente para acesso offline
      await _saveLocally(bible, xmlContent);
      
      print('Bíblia ${bible.name} salva na nuvem com sucesso');
      return true;
      
    } catch (e) {
      print('Erro ao salvar Bíblia na nuvem: $e');
      // Fallback para salvamento local
      return await _saveLocally(bible, xmlContent);
    }
  }

  /// Carrega Bíblias do usuário da nuvem
  Future<List<BibleVersionInfo>> loadBiblesFromCloud() async {
    try {
      final user = _authService.user;
      if (user == null) {
        print('Usuário não autenticado - carregando localmente');
        return await _loadLocally();
      }
      
      print('Carregando Bíblias da nuvem');
      
      final snapshot = await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .get();
      
      final cloudBibles = <BibleVersionInfo>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bible = BibleVersionInfo(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? 'Bíblia Importada',
          abbreviation: data['abbreviation'] ?? 'IMP',
          language: data['language'] ?? 'pt',
          isPopular: data['isPopular'] ?? false,
          isImported: true,
        );
        cloudBibles.add(bible);
      }
      
      // Sincronizar com armazenamento local
      await _syncWithLocal(cloudBibles);
      
      print('Carregadas ${cloudBibles.length} Bíblias da nuvem');
      return cloudBibles;
      
    } catch (e) {
      print('Erro ao carregar Bíblias da nuvem: $e');
      // Fallback para carregamento local
      return await _loadLocally();
    }
  }

  /// Obtém o conteúdo XML de uma Bíblia da nuvem
  Future<String?> getBibleXmlFromCloud(String bibleId) async {
    try {
      final user = _authService.user;
      if (user == null) {
        return await _getLocalXml(bibleId);
      }
      
      // Primeiro tentar buscar no cache local
      final localXml = await _getLocalXml(bibleId);
      if (localXml != null) {
        return localXml;
      }
      
      print('Baixando XML da nuvem para: $bibleId');
      
      // Buscar URL do arquivo no Firestore
      final doc = await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .doc(bibleId)
          .get();
      
      if (!doc.exists) {
        print('Bíblia não encontrada na nuvem: $bibleId');
        return null;
      }
      
      final fileUrl = doc.data()?['fileUrl'] as String?;
      if (fileUrl == null) {
        print('URL do arquivo não encontrada para: $bibleId');
        return null;
      }
      
      // Fazer download do arquivo
      final fileRef = _storage.refFromURL(fileUrl);
      final xmlContent = await fileRef.getData();
      
      if (xmlContent != null) {
        final xmlString = String.fromCharCodes(xmlContent);
        
        // Salvar no cache local
        await _saveLocalXml(bibleId, xmlString);
        
        return xmlString;
      }
      
      return null;
      
    } catch (e) {
      print('Erro ao obter XML da nuvem: $e');
      // Fallback para XML local
      return await _getLocalXml(bibleId);
    }
  }

  /// Remove uma Bíblia da nuvem
  Future<bool> removeBibleFromCloud(String bibleId) async {
    try {
      final user = _authService.user;
      if (user == null) {
        return await _removeLocally(bibleId);
      }
      
      print('Removendo Bíblia da nuvem: $bibleId');
      
      // 1. Remover documento do Firestore
      await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .doc(bibleId)
          .delete();
      
      // 2. Remover arquivo do Storage
      try {
        final fileRef = _storage.ref()
            .child(_storageFolder)
            .child(user.uid)
            .child('$bibleId.xml');
        await fileRef.delete();
      } catch (e) {
        print('Arquivo não encontrado no Storage: $e');
      }
      
      // 3. Remover do cache local
      await _removeLocally(bibleId);
      
      print('Bíblia removida da nuvem com sucesso');
      return true;
      
    } catch (e) {
      print('Erro ao remover Bíblia da nuvem: $e');
      return false;
    }
  }

  /// Habilita/desabilita uma Bíblia na nuvem
  Future<void> toggleBibleEnabledInCloud(String bibleId, bool enabled) async {
    try {
      final user = _authService.user;
      if (user == null) {
        await _toggleLocalEnabled(bibleId, enabled);
        return;
      }
      
      await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .doc(bibleId)
          .update({
        'enabled': enabled,
        'updatedAt': Timestamp.now(),
      });
      
      // Também atualizar localmente
      await _toggleLocalEnabled(bibleId, enabled);
      
    } catch (e) {
      print('Erro ao atualizar status da Bíblia: $e');
      // Fallback para atualização local
      await _toggleLocalEnabled(bibleId, enabled);
    }
  }

  /// Obtém lista de Bíblias habilitadas da nuvem
  Future<List<String>> getEnabledBiblesFromCloud() async {
    try {
      final user = _authService.user;
      if (user == null) {
        return await _getLocalEnabledBibles();
      }
      
      final snapshot = await _firestore
          .collection(_biblesCollection)
          .doc(user.uid)
          .collection('bibles')
          .where('enabled', isEqualTo: true)
          .get();
      
      final enabledIds = snapshot.docs.map((doc) => doc.id).toList();
      
      // Sincronizar com lista local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_localEnabledBiblesKey, enabledIds);
      
      return enabledIds;
      
    } catch (e) {
      print('Erro ao obter Bíblias habilitadas da nuvem: $e');
      return await _getLocalEnabledBibles();
    }
  }

  /// Sincroniza Bíblias locais com a nuvem (quando usuário faz login)
  Future<void> syncLocalBiblesToCloud() async {
    try {
      final user = _authService.user;
      if (user == null) {
        print('Usuário não autenticado - não é possível sincronizar');
        return;
      }
      
      print('Sincronizando Bíblias locais com a nuvem');
      
      // Obter Bíblias locais
      final localBibles = await _loadLocally();
      
      for (final bible in localBibles) {
        final xmlContent = await _getLocalXml(bible.id);
        if (xmlContent != null) {
          // Verificar se já existe na nuvem
          final cloudDoc = await _firestore
              .collection(_biblesCollection)
              .doc(user.uid)
              .collection('bibles')
              .doc(bible.id)
              .get();
          
          if (!cloudDoc.exists) {
            print('Fazendo upload de Bíblia local para a nuvem: ${bible.name}');
            await saveBibleToCloud(bible, xmlContent);
          }
        }
      }
      
      print('Sincronização concluída');
      
    } catch (e) {
      print('Erro na sincronização: $e');
    }
  }

  /// Sincroniza Bíblias da nuvem para local (quando usuário faz login)
  Future<void> syncCloudBiblesToLocal() async {
    try {
      final user = _authService.user;
      if (user == null) return;
      
      print('Sincronizando Bíblias da nuvem para local');
      
      final cloudBibles = await loadBiblesFromCloud();
      
      for (final bible in cloudBibles) {
        // Verificar se XML já existe localmente
        final localXml = await _getLocalXml(bible.id);
        if (localXml == null) {
          print('Baixando XML da nuvem para: ${bible.name}');
          await getBibleXmlFromCloud(bible.id);
        }
      }
      
      print('Sincronização da nuvem concluída');
      
    } catch (e) {
      print('Erro na sincronização da nuvem: $e');
    }
  }

  // ========== Métodos auxiliares para armazenamento local ==========

  Future<bool> _saveLocally(BibleVersionInfo bible, String xmlContent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar informações da Bíblia
      final importedBibles = await _loadLocally();
      importedBibles.add(bible);
      
      final biblesJson = importedBibles.map((b) => b.toJson()).toList();
      await prefs.setString(_localBiblesKey, json.encode(biblesJson));
      
      // Salvar conteúdo XML
      await prefs.setString('bible_xml_${bible.id}', xmlContent);
      
      print('Bíblia ${bible.name} salva localmente');
      return true;
    } catch (e) {
      print('Erro ao salvar Bíblia localmente: $e');
      return false;
    }
  }

  Future<List<BibleVersionInfo>> _loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final biblesJson = prefs.getString(_localBiblesKey);
      
      if (biblesJson == null) return [];
      
      final List<dynamic> decoded = json.decode(biblesJson);
      return decoded.map((json) => BibleVersionInfo.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar Bíblias locais: $e');
      return [];
    }
  }

  Future<String?> _getLocalXml(String bibleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('bible_xml_$bibleId');
    } catch (e) {
      print('Erro ao obter XML local: $e');
      return null;
    }
  }

  Future<void> _saveLocalXml(String bibleId, String xmlContent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_xml_$bibleId', xmlContent);
  }

  Future<bool> _removeLocally(String bibleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove das Bíblias importadas
      final biblesJson = prefs.getString(_localBiblesKey);
      if (biblesJson != null) {
        final List<dynamic> decoded = json.decode(biblesJson);
        final bibles = decoded.map((json) => BibleVersionInfo.fromJson(json)).toList();
        bibles.removeWhere((b) => b.id == bibleId);
        
        final updatedJson = bibles.map((b) => b.toJson()).toList();
        await prefs.setString(_localBiblesKey, json.encode(updatedJson));
      }
      
      // Remove das habilitadas
      final enabledIds = prefs.getStringList(_localEnabledBiblesKey) ?? [];
      enabledIds.remove(bibleId);
      await prefs.setStringList(_localEnabledBiblesKey, enabledIds);
      
      // Remove conteúdo XML
      await prefs.remove('bible_xml_$bibleId');
      
      return true;
    } catch (e) {
      print('Erro ao remover Bíblia localmente: $e');
      return false;
    }
  }

  Future<void> _toggleLocalEnabled(String bibleId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledIds = prefs.getStringList(_localEnabledBiblesKey) ?? [];
      
      if (enabled && !enabledIds.contains(bibleId)) {
        enabledIds.add(bibleId);
      } else if (!enabled && enabledIds.contains(bibleId)) {
        enabledIds.remove(bibleId);
      }
      
      await prefs.setStringList(_localEnabledBiblesKey, enabledIds);
    } catch (e) {
      print('Erro ao alterar status local da Bíblia: $e');
    }
  }

  Future<List<String>> _getLocalEnabledBibles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_localEnabledBiblesKey) ?? [];
    } catch (e) {
      print('Erro ao obter Bíblias habilitadas locais: $e');
      return [];
    }
  }

  Future<void> _syncWithLocal(List<BibleVersionInfo> cloudBibles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final biblesJson = cloudBibles.map((b) => b.toJson()).toList();
      await prefs.setString(_localBiblesKey, json.encode(biblesJson));
    } catch (e) {
      print('Erro ao sincronizar com armazenamento local: $e');
    }
  }

}