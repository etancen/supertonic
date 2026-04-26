export interface SuperTonicSettings {
    apiUrl: string;
    voice: string;
    language: string;
    speed: number;
    totalStep: number;
}

export const DEFAULT_SETTINGS: SuperTonicSettings = {
    apiUrl: "http://localhost:8765",
    voice: "M1",
    language: "en",
    speed: 1.05,
    totalStep: 5,
};

export const VOICE_NAMES = ["M1", "M2", "M3", "M4", "M5", "F1", "F2", "F3", "F4", "F5"];

export const LANGUAGES: Record<string, string> = {
    en: "English",
    ko: "Korean",
    es: "Spanish",
    pt: "Portuguese",
    fr: "French",
};
