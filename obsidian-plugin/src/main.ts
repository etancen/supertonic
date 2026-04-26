import {
    App,
    Editor,
    MarkdownView,
    Notice,
    Plugin,
    PluginSettingTab,
    Setting,
    requestUrl,
} from "obsidian";
import {
    DEFAULT_SETTINGS,
    LANGUAGES,
    SuperTonicSettings,
    VOICE_NAMES,
} from "./settings";

export default class SuperTonicPlugin extends Plugin {
    settings: SuperTonicSettings;
    private audioContext: AudioContext | null = null;
    private activeSource: AudioBufferSourceNode | null = null;

    async onload() {
        await this.loadSettings();
        this.addSettingTab(new SuperTonicSettingTab(this.app, this));

        this.addCommand({
            id: "speak-selection",
            name: "Speak selected text",
            editorCallback: (editor: Editor, _view: MarkdownView) => {
                const text = editor.getSelection();
                if (!text) {
                    new Notice("SuperTonic: No text selected");
                    return;
                }
                this.speakText(text);
            },
        });

        this.addCommand({
            id: "stop-speaking",
            name: "Stop speaking",
            callback: () => {
                this.stopSpeaking();
            },
        });
    }

    onunload() {
        this.stopSpeaking();
        this.audioContext?.close();
        this.audioContext = null;
    }

    private async speakText(text: string) {
        this.stopSpeaking();

        new Notice("SuperTonic: Synthesizing...");

        try {
            const response = await requestUrl({
                url: `${this.settings.apiUrl}/tts`,
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    text,
                    voice: this.settings.voice,
                    lang: this.settings.language,
                    speed: this.settings.speed,
                    total_step: this.settings.totalStep,
                }),
            });

            if (response.status !== 200) {
                new Notice(`SuperTonic: API error ${response.status}`);
                return;
            }

            if (!this.audioContext) {
                this.audioContext = new AudioContext();
            }

            const audioBuffer = await this.audioContext.decodeAudioData(
                response.arrayBuffer
            );

            const source = this.audioContext.createBufferSource();
            source.buffer = audioBuffer;
            source.connect(this.audioContext.destination);
            source.onended = () => {
                if (this.activeSource === source) {
                    this.activeSource = null;
                }
            };

            this.activeSource = source;
            source.start();

            new Notice("SuperTonic: Playing...");
        } catch (e) {
            new Notice(`SuperTonic: ${e.message}`);
        }
    }

    private stopSpeaking() {
        if (this.activeSource) {
            try {
                this.activeSource.stop();
            } catch (_) {
                // already stopped
            }
            this.activeSource = null;
        }
    }

    async loadSettings() {
        this.settings = Object.assign(
            {},
            DEFAULT_SETTINGS,
            await this.loadData()
        );
    }

    async saveSettings() {
        await this.saveData(this.settings);
    }
}

class SuperTonicSettingTab extends PluginSettingTab {
    plugin: SuperTonicPlugin;

    constructor(app: App, plugin: SuperTonicPlugin) {
        super(app, plugin);
        this.plugin = plugin;
    }

    display(): void {
        const { containerEl } = this;
        containerEl.empty();

        containerEl.createEl("h2", { text: "SuperTonic TTS Settings" });

        new Setting(containerEl)
            .setName("API Server URL")
            .setDesc("SuperTonic TTS API server address")
            .addText((text) =>
                text
                    .setPlaceholder("http://localhost:8765")
                    .setValue(this.plugin.settings.apiUrl)
                    .onChange(async (value) => {
                        this.plugin.settings.apiUrl = value.replace(
                            /\/+$/,
                            ""
                        );
                        await this.plugin.saveSettings();
                    })
            );

        new Setting(containerEl)
            .setName("Voice")
            .setDesc("Voice style to use for synthesis")
            .addDropdown((dropdown) => {
                for (const voice of VOICE_NAMES) {
                    dropdown.addOption(voice, voice);
                }
                dropdown
                    .setValue(this.plugin.settings.voice)
                    .onChange(async (value) => {
                        this.plugin.settings.voice = value;
                        await this.plugin.saveSettings();
                    });
            });

        new Setting(containerEl)
            .setName("Language")
            .setDesc("Language of the text being spoken")
            .addDropdown((dropdown) => {
                for (const [code, name] of Object.entries(LANGUAGES)) {
                    dropdown.addOption(code, name);
                }
                dropdown
                    .setValue(this.plugin.settings.language)
                    .onChange(async (value) => {
                        this.plugin.settings.language = value;
                        await this.plugin.saveSettings();
                    });
            });

        new Setting(containerEl)
            .setName("Speed")
            .setDesc("Speech speed (0.5 = slow, 2.0 = fast)")
            .addSlider((slider) =>
                slider
                    .setLimits(0.5, 2.0, 0.05)
                    .setValue(this.plugin.settings.speed)
                    .setDynamicTooltip()
                    .onChange(async (value) => {
                        this.plugin.settings.speed = value;
                        await this.plugin.saveSettings();
                    })
            );

        new Setting(containerEl)
            .setName("Quality steps")
            .setDesc("Denoising steps (3 = fast, 10 = best quality)")
            .addSlider((slider) =>
                slider
                    .setLimits(3, 10, 1)
                    .setValue(this.plugin.settings.totalStep)
                    .setDynamicTooltip()
                    .onChange(async (value) => {
                        this.plugin.settings.totalStep = value;
                        await this.plugin.saveSettings();
                    })
            );

        containerEl.createEl("hr");

        const tipEl = containerEl.createEl("p");
        tipEl.innerHTML =
            'Bind a hotkey in <b>Settings → Hotkeys</b>: search for <b>"SuperTonic: Speak selected text"</b> and set <b>Ctrl+Shift+P</b>.';
    }
}
