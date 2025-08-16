// Screen Detection para VERSEE
// Este script melhora a detecção de monitores físicos

window.verseeScreenDetection = {
    // Solicitar permissão para Screen Detection API
    async requestScreenPermission() {
        try {
            if ('screen' in window && 'getScreenDetails' in window.screen) {
                console.log('📺 Solicitando permissão para Screen Detection API...');
                const screens = await window.screen.getScreenDetails();
                console.log('✅ Permissão concedida. Monitores detectados:', screens.screens.length);
                return screens;
            } else {
                console.log('⚠️ Screen Detection API não disponível');
                return null;
            }
        } catch (error) {
            console.error('❌ Erro ao solicitar permissão de tela:', error);
            return null;
        }
    },

    // Detectar configuração multi-monitor
    detectMultiMonitorSetup() {
        const screen = window.screen;
        const info = {
            screenWidth: screen.width,
            screenHeight: screen.height,
            availWidth: screen.availWidth,
            availHeight: screen.availHeight,
            colorDepth: screen.colorDepth,
            pixelDepth: screen.pixelDepth,
            devicePixelRatio: window.devicePixelRatio,
            isMultiMonitor: false,
            estimatedSecondaryMonitor: null
        };

        // Detectar se há mais área disponível (setup estendido)
        if (info.availWidth > info.screenWidth * 1.2) {
            info.isMultiMonitor = true;
            info.estimatedSecondaryMonitor = {
                width: info.availWidth - info.screenWidth,
                height: info.screenHeight,
                position: 'right'
            };
            console.log('✅ Setup multi-monitor detectado:', info.estimatedSecondaryMonitor);
        }

        return info;
    },

    // Abrir janela em tela cheia no monitor secundário
    async openFullscreenOnSecondaryMonitor(url) {
        try {
            console.log('🖥️ Tentando abrir em monitor secundário:', url);
            
            const screenInfo = this.detectMultiMonitorSetup();
            
            if (screenInfo.isMultiMonitor && screenInfo.estimatedSecondaryMonitor) {
                const secondary = screenInfo.estimatedSecondaryMonitor;
                const left = screenInfo.screenWidth; // Posição no monitor secundário
                const top = 0;
                
                const features = [
                    `left=${left}`,
                    `top=${top}`,
                    `width=${secondary.width}`,
                    `height=${secondary.height}`,
                    'fullscreen=yes',
                    'resizable=no',
                    'scrollbars=no',
                    'toolbar=no',
                    'menubar=no',
                    'status=no'
                ].join(',');
                
                console.log('🚀 Abrindo janela com features:', features);
                const newWindow = window.open(url, '_blank', features);
                
                if (newWindow) {
                    // Tentar mover para tela cheia após um delay
                    setTimeout(() => {
                        try {
                            if (newWindow.document && newWindow.document.documentElement) {
                                if (newWindow.document.documentElement.requestFullscreen) {
                                    newWindow.document.documentElement.requestFullscreen();
                                } else if (newWindow.document.documentElement.webkitRequestFullscreen) {
                                    newWindow.document.documentElement.webkitRequestFullscreen();
                                } else if (newWindow.document.documentElement.mozRequestFullScreen) {
                                    newWindow.document.documentElement.mozRequestFullScreen();
                                }
                                console.log('✅ Fullscreen ativado no monitor secundário');
                            }
                        } catch (e) {
                            console.warn('⚠️ Não foi possível ativar fullscreen:', e);
                        }
                    }, 1000);
                    
                    return newWindow;
                } else {
                    console.error('❌ Falha ao abrir janela (popup bloqueado?)');
                    return null;
                }
            } else {
                console.log('📱 Abrindo janela normal (sem monitor secundário detectado)');
                const newWindow = window.open(url, '_blank', 'width=1920,height=1080,fullscreen=yes');
                return newWindow;
            }
        } catch (error) {
            console.error('❌ Erro ao abrir janela no monitor secundário:', error);
            return null;
        }
    },

    // Verificar se janela está em monitor secundário
    isWindowOnSecondaryMonitor(windowRef) {
        try {
            if (windowRef && windowRef.screenX !== undefined) {
                const primaryWidth = window.screen.width;
                return windowRef.screenX >= primaryWidth;
            }
            return false;
        } catch (error) {
            console.warn('Não foi possível verificar posição da janela:', error);
            return false;
        }
    },

    // Mover janela para monitor secundário
    async moveToSecondaryMonitor(windowRef) {
        try {
            const screenInfo = this.detectMultiMonitorSetup();
            if (screenInfo.isMultiMonitor && windowRef) {
                const targetX = screenInfo.screenWidth + 100; // Offset no monitor secundário
                const targetY = 100;
                
                windowRef.moveTo(targetX, targetY);
                windowRef.resizeTo(screenInfo.estimatedSecondaryMonitor.width - 200, screenInfo.estimatedSecondaryMonitor.height - 200);
                
                console.log(`✅ Janela movida para monitor secundário: ${targetX}, ${targetY}`);
                return true;
            }
            return false;
        } catch (error) {
            console.error('❌ Erro ao mover janela:', error);
            return false;
        }
    },

    // Inicializar detecção automática
    async initialize() {
        console.log('🔍 Inicializando detecção de monitores VERSEE...');
        
        // Tentar solicitar permissão de telas
        await this.requestScreenPermission();
        
        // Detectar setup atual
        const setup = this.detectMultiMonitorSetup();
        console.log('📊 Setup detectado:', setup);
        
        // Expor funções globalmente para o Flutter
        window.versee = window.versee || {};
        window.versee.screenDetection = this;
        
        return setup;
    }
};

// Auto-inicializar quando o script carrega
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.verseeScreenDetection.initialize();
    });
} else {
    window.verseeScreenDetection.initialize();
}

// Adicionar listener para mudanças de tela
window.addEventListener('resize', () => {
    console.log('📏 Resize detectado, reavaliando setup de monitores...');
    window.verseeScreenDetection.detectMultiMonitorSetup();
});