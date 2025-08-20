# Status da Migração Provider → Riverpod

## Progresso: 4/27 (15%)

### ✅ Migrados:
1. ThemeService
2. LanguageService (bridge híbrida)
3. StorageMonitoringService
4. StorageAnalysisService

### ⏳ Próximos candidatos simples:
5. NotesService
6. VerseCollectionService
7. MediaService
8. PlaylistService

### 📝 Notas:
- Padrão de 4 fases funciona bem
- Bridge híbrida necessária quando há muitos Consumer<>
- storage_page.dart precisa atualização